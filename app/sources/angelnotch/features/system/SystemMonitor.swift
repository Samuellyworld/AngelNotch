import AVFoundation
import AppKit
import CoreAudio
import CoreGraphics
import CoreMediaIO
import Darwin
import Foundation
import IOKit
import IOKit.ps

struct AudioOutputDevice: Identifiable, Equatable, Sendable {
  let id: AudioDeviceID
  let name: String
  let uid: String
}

enum AirPodsModel: Equatable, Sendable {
  case standard
  case generation3
  case pro
  case max

  var symbolName: String {
    switch self {
    case .standard: "airpods"
    case .generation3: "airpods.gen3"
    case .pro: "airpodspro"
    case .max: "airpodsmax"
    }
  }

  static func infer(from productName: String) -> AirPodsModel {
    let value = productName.lowercased()
    if value.contains("max") {
      return .max
    }
    if value.contains("pro") {
      return .pro
    }
    if value.contains("3rd")
      || value.contains("third")
      || value.contains("gen 3")
      || value.contains("generation 3")
      || value.contains("airpods 3")
    {
      return .generation3
    }
    return .standard
  }
}

struct ConnectedAirPods: Equatable, Sendable {
  let name: String
  let model: AirPodsModel
  let batteryLevel: Double?
}

struct SystemSnapshot: Equatable, Sendable {
  var volume: Double = 0
  var isMuted = false
  var brightness: Double = 0.5
  var isBrightnessAvailable = true
  var batteryLevel: Double = 1
  var isCharging = false
  var isPowerAdapterConnected = false
  var isLowPowerModeEnabled = false
  var batteryMinutesRemaining: Int?
  var isMicrophoneMuted = false
  var isCameraInUse = false
  var outputDeviceName = "Audio output"
  var isCallActive = false
  var connectedAirPods: ConnectedAirPods?
}

enum SystemHUDKind: Equatable, Sendable {
  case volume(Double, muted: Bool)
  case brightness(Double)
  case battery(
    Double,
    charging: Bool,
    powerConnected: Bool,
    lowPowerMode: Bool
  )
  case microphone(muted: Bool)
  case camera(active: Bool)
  case audioOutput(String)
  case airPodsConnected(ConnectedAirPods)
}

struct SystemHUDEvent: Equatable, Sendable {
  let id = UUID()
  let kind: SystemHUDKind

  static func == (lhs: SystemHUDEvent, rhs: SystemHUDEvent) -> Bool {
    lhs.id == rhs.id
  }
}

@MainActor
final class SystemMonitor: ObservableObject {
  @Published private(set) var snapshot = SystemSnapshot()
  @Published private(set) var outputDevices: [AudioOutputDevice] = []
  @Published private(set) var latestHUD: SystemHUDEvent?

  private var monitorTask: Task<Void, Never>?
  private var hasInitialSnapshot = false
  private var previousInputVolume: Double = 0.75

  func start() {
    guard monitorTask == nil else { return }
    monitorTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        let reading = await Task.detached(priority: .utility) {
          Self.readSystem()
        }.value
        self?.apply(reading)
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }

  func setVolume(_ value: Double) {
    let clamped = max(0, min(1, value))
    Task.detached(priority: .userInitiated) {
      Self.setDeviceVolume(clamped, input: false)
    }
    snapshot.volume = clamped
    snapshot.isMuted = false
    latestHUD = SystemHUDEvent(kind: .volume(clamped, muted: false))
  }

  func toggleMute() {
    let muted = !snapshot.isMuted
    Task.detached(priority: .userInitiated) {
      Self.setDeviceMute(muted, input: false)
    }
    snapshot.isMuted = muted
    latestHUD = SystemHUDEvent(kind: .volume(snapshot.volume, muted: muted))
  }

  func setBrightness(_ value: Double) {
    guard snapshot.isBrightnessAvailable else { return }
    let clamped = max(0, min(1, value))
    Task.detached(priority: .userInitiated) {
      Self.setDisplayBrightness(Float(clamped))
    }
    snapshot.brightness = clamped
    latestHUD = SystemHUDEvent(kind: .brightness(clamped))
  }

  func toggleMicrophoneMute() {
    let willMute = !snapshot.isMicrophoneMuted
    if willMute {
      previousInputVolume = max(0.05, Self.deviceVolume(input: true))
      Task.detached(priority: .userInitiated) {
        Self.setDeviceVolume(0, input: true)
      }
    } else {
      let restore = previousInputVolume
      Task.detached(priority: .userInitiated) {
        Self.setDeviceVolume(restore, input: true)
      }
    }
    snapshot.isMicrophoneMuted = willMute
    latestHUD = SystemHUDEvent(kind: .microphone(muted: willMute))
  }

  func selectOutput(_ device: AudioOutputDevice) {
    Task.detached(priority: .userInitiated) {
      Self.setDefaultOutputDevice(device.id)
    }
    snapshot.outputDeviceName = device.name
    latestHUD = SystemHUDEvent(kind: .audioOutput(device.name))
  }

  func openCameraPrivacySettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
      )
    else { return }
    NSWorkspace.shared.open(url)
  }

  private func apply(_ reading: SystemReading) {
    let previous = snapshot
    snapshot = reading.snapshot
    outputDevices = reading.outputDevices

    guard hasInitialSnapshot else {
      hasInitialSnapshot = true
      if let connectedAirPods = snapshot.connectedAirPods {
        latestHUD = SystemHUDEvent(
          kind: .airPodsConnected(connectedAirPods)
        )
      }
      return
    }

    if previous.isPowerAdapterConnected != snapshot.isPowerAdapterConnected
      || previous.isCharging != snapshot.isCharging
    {
      latestHUD = SystemHUDEvent(
        kind: .battery(
          snapshot.batteryLevel,
          charging: snapshot.isCharging,
          powerConnected: snapshot.isPowerAdapterConnected,
          lowPowerMode: snapshot.isLowPowerModeEnabled
        )
      )
    } else if abs(previous.volume - snapshot.volume) > 0.025
      || previous.isMuted != snapshot.isMuted
    {
      latestHUD = SystemHUDEvent(
        kind: .volume(snapshot.volume, muted: snapshot.isMuted)
      )
    } else if abs(previous.brightness - snapshot.brightness) > 0.025 {
      latestHUD = SystemHUDEvent(kind: .brightness(snapshot.brightness))
    } else if previous.isMicrophoneMuted != snapshot.isMicrophoneMuted {
      latestHUD = SystemHUDEvent(
        kind: .microphone(muted: snapshot.isMicrophoneMuted)
      )
    } else if previous.isCameraInUse != snapshot.isCameraInUse {
      latestHUD = SystemHUDEvent(
        kind: .camera(active: snapshot.isCameraInUse)
      )
    } else if previous.connectedAirPods == nil,
      let connectedAirPods = snapshot.connectedAirPods
    {
      latestHUD = SystemHUDEvent(
        kind: .airPodsConnected(connectedAirPods)
      )
    } else if previous.outputDeviceName != snapshot.outputDeviceName {
      latestHUD = SystemHUDEvent(
        kind: .audioOutput(snapshot.outputDeviceName)
      )
    }
  }
}

private struct SystemReading: Sendable {
  let snapshot: SystemSnapshot
  let outputDevices: [AudioOutputDevice]
}

private struct BatteryReading: Sendable {
  var level = 1.0
  var charging = false
  var powerConnected = false
  var minutesRemaining: Int?
}

private struct AirPodsAccessoryStatus: Sendable {
  var productName: String?
  var batteryLevel: Double?
}

private struct ActiveAudioInputProcess: Sendable {
  let bundleIdentifier: String
  let inputDeviceIDs: [AudioDeviceID]
}

extension SystemMonitor {
  fileprivate nonisolated static func readSystem() -> SystemReading {
    let outputs = audioOutputDevices()
    let defaultOutput = defaultDevice(input: false)
    let defaultName =
      outputs.first(where: { $0.id == defaultOutput })?.name
      ?? "Audio output"
    let battery = batteryStatus()
    let brightness = displayBrightness()
    let connectedAirPodsDevice = outputs.first {
      $0.name.localizedCaseInsensitiveContains("AirPods")
    }
    let connectedAirPods = connectedAirPodsDevice.map {
      let accessory = airPodsAccessoryStatus(matching: $0.name)
      return ConnectedAirPods(
        name: $0.name,
        model: AirPodsModel.infer(
          from: accessory.productName ?? $0.name
        ),
        batteryLevel: accessory.batteryLevel
      )
    }
    let activeInputProcesses = activeAudioInputProcesses()
    let activeCallProcess = activeInputProcesses.first(
      where: {
        isCallCapableBundleIdentifier($0.bundleIdentifier)
      }
    )
    let processDetectionAvailable = audioProcessMonitoringIsAvailable()
    #if DEBUG
      if ProcessInfo.processInfo.environment["ANGELNOTCH_LOG_PRESENCE"] == "1" {
        print(
          "angelnotch input processes: "
            + "\(activeInputProcesses.map(\.bundleIdentifier)), "
            + "call: \(activeCallProcess?.bundleIdentifier ?? "none"), "
            + "input devices: \(activeCallProcess?.inputDeviceIDs ?? [])"
        )
      }
    #endif

    return SystemReading(
      snapshot: SystemSnapshot(
        volume: deviceVolume(input: false),
        isMuted: deviceMute(input: false),
        brightness: Double(brightness ?? 0.5),
        isBrightnessAvailable: brightness != nil,
        batteryLevel: battery.level,
        isCharging: battery.charging,
        isPowerAdapterConnected: battery.powerConnected,
        isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled,
        batteryMinutesRemaining: battery.minutesRemaining,
        isMicrophoneMuted: deviceVolume(input: true) < 0.01
          || deviceMute(input: true),
        isCameraInUse: cameraIsRunning(),
        outputDeviceName: defaultName,
        isCallActive: activeCallProcess != nil
          || (!processDetectionAvailable
            && microphoneIsInUseByAnotherApplication()),
        connectedAirPods: connectedAirPods
      ),
      outputDevices: outputs
    )
  }

  fileprivate nonisolated static func defaultDevice(input: Bool) -> AudioDeviceID {
    var device = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    var address = AudioObjectPropertyAddress(
      mSelector: input
        ? kAudioHardwarePropertyDefaultInputDevice
        : kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      0,
      nil,
      &size,
      &device
    )
    return device
  }

  fileprivate nonisolated static func deviceVolume(input: Bool) -> Double {
    let device = defaultDevice(input: input)
    let scope = input ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
    for element in [
      kAudioObjectPropertyElementMain,
      AudioObjectPropertyElement(1),
      AudioObjectPropertyElement(2),
    ] {
      var value = Float32(0)
      var size = UInt32(MemoryLayout<Float32>.size)
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: scope,
        mElement: element
      )
      if AudioObjectGetPropertyData(
        device,
        &address,
        0,
        nil,
        &size,
        &value
      ) == noErr {
        return Double(value)
      }
    }
    return 0
  }

  fileprivate nonisolated static func setDeviceVolume(_ value: Double, input: Bool) {
    let device = defaultDevice(input: input)
    let scope = input ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
    var scalar = Float32(value)
    let size = UInt32(MemoryLayout<Float32>.size)
    for element in [
      kAudioObjectPropertyElementMain,
      AudioObjectPropertyElement(1),
      AudioObjectPropertyElement(2),
    ] {
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: scope,
        mElement: element
      )
      _ = AudioObjectSetPropertyData(
        device,
        &address,
        0,
        nil,
        size,
        &scalar
      )
    }
    if !input && value > 0 {
      setDeviceMute(false, input: false)
    }
  }

  fileprivate nonisolated static func deviceMute(input: Bool) -> Bool {
    let device = defaultDevice(input: input)
    var muted: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyMute,
      mScope: input
        ? kAudioDevicePropertyScopeInput
        : kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    guard
      AudioObjectGetPropertyData(
        device,
        &address,
        0,
        nil,
        &size,
        &muted
      ) == noErr
    else {
      return false
    }
    return muted != 0
  }

  fileprivate nonisolated static func setDeviceMute(_ muted: Bool, input: Bool) {
    let device = defaultDevice(input: input)
    var value: UInt32 = muted ? 1 : 0
    let size = UInt32(MemoryLayout<UInt32>.size)
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyMute,
      mScope: input
        ? kAudioDevicePropertyScopeInput
        : kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    _ = AudioObjectSetPropertyData(
      device,
      &address,
      0,
      nil,
      size,
      &value
    )
  }

  fileprivate nonisolated static func audioOutputDevices() -> [AudioOutputDevice] {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    guard
      AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        0,
        nil,
        &size
      ) == noErr
    else {
      return []
    }

    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    var devices = [AudioDeviceID](repeating: 0, count: count)
    guard
      AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        0,
        nil,
        &size,
        &devices
      ) == noErr
    else {
      return []
    }

    return devices.compactMap { device in
      guard
        hasOutputChannels(device),
        deviceBooleanProperty(
          kAudioDevicePropertyDeviceIsAlive,
          device: device
        )
      else {
        return nil
      }
      return AudioOutputDevice(
        id: device,
        name: stringProperty(kAudioObjectPropertyName, device: device)
          ?? "Audio device",
        uid: stringProperty(kAudioDevicePropertyDeviceUID, device: device)
          ?? "\(device)"
      )
    }
    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  fileprivate nonisolated static func deviceBooleanProperty(
    _ selector: AudioObjectPropertySelector,
    device: AudioDeviceID
  ) -> Bool {
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    guard AudioObjectHasProperty(device, &address) else { return false }
    return AudioObjectGetPropertyData(
      device,
      &address,
      0,
      nil,
      &size,
      &value
    ) == noErr && value != 0
  }

  fileprivate nonisolated static func airPodsAccessoryStatus(
    matching deviceName: String
  ) -> AirPodsAccessoryStatus {
    let hidStatus = airPodsHIDStatus(matching: deviceName)
    if hidStatus.productName != nil || hidStatus.batteryLevel != nil {
      return hidStatus
    }
    return AirPodsAccessoryStatus(
      productName: nil,
      batteryLevel: airPodsPowerSourceLevel(matching: deviceName)
    )
  }

  fileprivate nonisolated static func airPodsHIDStatus(
    matching deviceName: String
  ) -> AirPodsAccessoryStatus {
    var iterator: io_iterator_t = 0
    guard
      IOServiceGetMatchingServices(
        kIOMainPortDefault,
        IOServiceMatching("AppleDeviceManagementHIDEventService"),
        &iterator
      ) == kIOReturnSuccess
    else {
      return AirPodsAccessoryStatus()
    }
    defer { IOObjectRelease(iterator) }

    var fallback = AirPodsAccessoryStatus()
    while true {
      let service = IOIteratorNext(iterator)
      guard service != 0 else { break }
      defer { IOObjectRelease(service) }

      var unmanagedProperties: Unmanaged<CFMutableDictionary>?
      guard
        IORegistryEntryCreateCFProperties(
          service,
          &unmanagedProperties,
          kCFAllocatorDefault,
          0
        ) == kIOReturnSuccess,
        let properties =
          unmanagedProperties?.takeRetainedValue() as? [String: Any]
      else {
        continue
      }

      let productName =
        properties["Product"] as? String
        ?? properties["Product Name"] as? String
        ?? properties["Name"] as? String
      guard
        let productName,
        productName.localizedCaseInsensitiveContains("AirPods")
      else {
        continue
      }

      let batteryLevel = accessoryBatteryLevel(in: properties)
      let status = AirPodsAccessoryStatus(
        productName: productName,
        batteryLevel: batteryLevel
      )
      if normalizedAccessoryName(productName)
        == normalizedAccessoryName(deviceName)
      {
        return status
      }
      if fallback.productName == nil || fallback.batteryLevel == nil {
        fallback = status
      }
    }
    return fallback
  }

  fileprivate nonisolated static func airPodsPowerSourceLevel(
    matching deviceName: String
  ) -> Double? {
    guard
      let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
      let sources =
        IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
    else {
      return nil
    }

    var fallback: Double?
    for source in sources {
      guard
        let description = IOPSGetPowerSourceDescription(
          info,
          source
        )?.takeUnretainedValue() as? [String: Any],
        let name = description[kIOPSNameKey] as? String,
        name.localizedCaseInsensitiveContains("AirPods"),
        let level = capacityLevel(in: description)
      else {
        continue
      }

      if normalizedAccessoryName(name)
        == normalizedAccessoryName(deviceName)
      {
        return level
      }
      fallback = min(fallback ?? level, level)
    }
    return fallback
  }

  fileprivate nonisolated static func accessoryBatteryLevel(
    in properties: [String: Any]
  ) -> Double? {
    let primaryKeys = [
      "BatteryPercent",
      "BatteryPercentCombined",
      "BatteryPercentSingle",
    ]
    for key in primaryKeys {
      if let level = normalizedBatteryValue(properties[key]) {
        return level
      }
    }

    let earbudLevels = [
      "BatteryPercentLeft",
      "BatteryPercentRight",
    ].compactMap {
      normalizedBatteryValue(properties[$0])
    }
    return earbudLevels.min()
  }

  fileprivate nonisolated static func capacityLevel(
    in properties: [String: Any]
  ) -> Double? {
    guard
      let current = (properties[kIOPSCurrentCapacityKey] as? NSNumber)?
        .doubleValue,
      let maximum = (properties[kIOPSMaxCapacityKey] as? NSNumber)?
        .doubleValue,
      maximum > 0
    else {
      return nil
    }
    return min(1, max(0, current / maximum))
  }

  fileprivate nonisolated static func normalizedBatteryValue(
    _ value: Any?
  ) -> Double? {
    guard let rawValue = (value as? NSNumber)?.doubleValue else {
      return nil
    }
    let level = rawValue > 1 ? rawValue / 100 : rawValue
    guard level >= 0, level <= 1 else { return nil }
    return level
  }

  fileprivate nonisolated static func normalizedAccessoryName(
    _ name: String
  ) -> String {
    name.lowercased().filter(\.isLetter)
  }

  fileprivate nonisolated static func activeAudioInputProcesses()
    -> [ActiveAudioInputProcess]
  {
    audioProcessObjects().compactMap { object in
      guard
        audioObjectBooleanProperty(
          kAudioProcessPropertyIsRunningInput,
          object: object
        ),
        let bundleIdentifier = processBundleIdentifier(object),
        !bundleIdentifier.isEmpty
      else {
        return nil
      }

      let inputDeviceIDs = audioObjectIDsProperty(
        kAudioProcessPropertyDevices,
        object: object
      ).filter(hasInputStreams)
      return ActiveAudioInputProcess(
        bundleIdentifier: bundleIdentifier,
        inputDeviceIDs: inputDeviceIDs
      )
    }
  }

  fileprivate nonisolated static func audioProcessMonitoringIsAvailable() -> Bool {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyProcessObjectList,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    return AudioObjectHasProperty(
      AudioObjectID(kAudioObjectSystemObject),
      &address
    )
  }

  fileprivate nonisolated static func audioProcessObjects() -> [AudioObjectID] {
    audioObjectIDsProperty(
      kAudioHardwarePropertyProcessObjectList,
      object: AudioObjectID(kAudioObjectSystemObject)
    )
  }

  fileprivate nonisolated static func audioObjectIDsProperty(
    _ selector: AudioObjectPropertySelector,
    object: AudioObjectID
  ) -> [AudioObjectID] {
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    guard
      AudioObjectGetPropertyDataSize(
        object,
        &address,
        0,
        nil,
        &size
      ) == noErr
    else {
      return []
    }

    let count = Int(size) / MemoryLayout<AudioObjectID>.size
    var objects = [AudioObjectID](repeating: 0, count: count)
    guard
      AudioObjectGetPropertyData(
        object,
        &address,
        0,
        nil,
        &size,
        &objects
      ) == noErr
    else {
      return []
    }
    return objects
  }

  fileprivate nonisolated static func hasInputStreams(
    _ device: AudioDeviceID
  ) -> Bool {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyStreams,
      mScope: kAudioDevicePropertyScopeInput,
      mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    return AudioObjectGetPropertyDataSize(
      device,
      &address,
      0,
      nil,
      &size
    ) == noErr
      && size >= UInt32(MemoryLayout<AudioStreamID>.size)
  }

  fileprivate nonisolated static func audioObjectBooleanProperty(
    _ selector: AudioObjectPropertySelector,
    object: AudioObjectID
  ) -> Bool {
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    guard AudioObjectHasProperty(object, &address) else { return false }
    return AudioObjectGetPropertyData(
      object,
      &address,
      0,
      nil,
      &size,
      &value
    ) == noErr && value != 0
  }

  fileprivate nonisolated static func processBundleIdentifier(
    _ object: AudioObjectID
  ) -> String? {
    var value: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioProcessPropertyBundleID,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    guard
      AudioObjectGetPropertyData(
        object,
        &address,
        0,
        nil,
        &size,
        &value
      ) == noErr
    else {
      return nil
    }
    return value?.takeRetainedValue() as String?
  }

  fileprivate nonisolated static func isCallCapableBundleIdentifier(
    _ bundleIdentifier: String
  ) -> Bool {
    let value = bundleIdentifier.lowercased()
    return [
      "avconferenced",
      "facetime",
      "zoom",
      "teams",
      "slack",
      "discord",
      "webex",
      "whatsapp",
      "telegram",
      "signal",
      "skype",
      "messenger",
      "chrome",
      "safari",
      "webkit",
      "firefox",
      "arc",
    ].contains { value.contains($0) }
  }

  fileprivate nonisolated static func hasOutputChannels(_ device: AudioDeviceID) -> Bool {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyStreamConfiguration,
      mScope: kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    return AudioObjectGetPropertyDataSize(
      device,
      &address,
      0,
      nil,
      &size
    ) == noErr && size > 0
  }

  fileprivate nonisolated static func stringProperty(
    _ selector: AudioObjectPropertySelector,
    device: AudioDeviceID
  ) -> String? {
    var value: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    guard
      AudioObjectGetPropertyData(
        device,
        &address,
        0,
        nil,
        &size,
        &value
      ) == noErr
    else {
      return nil
    }
    return value?.takeUnretainedValue() as String?
  }

  fileprivate nonisolated static func setDefaultOutputDevice(_ device: AudioDeviceID) {
    var mutableDevice = device
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    _ = AudioObjectSetPropertyData(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      0,
      nil,
      UInt32(MemoryLayout<AudioDeviceID>.size),
      &mutableDevice
    )
  }

  fileprivate nonisolated static func batteryStatus() -> BatteryReading {
    guard
      let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
      let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
    else {
      return BatteryReading()
    }

    for source in sources {
      guard
        let description = IOPSGetPowerSourceDescription(
          info,
          source
        )?.takeUnretainedValue() as? [String: Any],
        let current = (description[kIOPSCurrentCapacityKey] as? NSNumber)?.doubleValue,
        let maximum = (description[kIOPSMaxCapacityKey] as? NSNumber)?.doubleValue,
        maximum > 0
      else {
        continue
      }

      let charging = (description[kIOPSIsChargingKey] as? NSNumber)?.boolValue ?? false
      let powerState = description[kIOPSPowerSourceStateKey] as? String
      let powerConnected = powerState == kIOPSACPowerValue
      let timeKey =
        charging
        ? kIOPSTimeToFullChargeKey
        : kIOPSTimeToEmptyKey
      let rawMinutes = (description[timeKey] as? NSNumber)?.intValue
      let minutes = rawMinutes.flatMap {
        $0 > 0 && $0 < Int.max ? $0 : nil
      }
      return BatteryReading(
        level: current / maximum,
        charging: charging,
        powerConnected: powerConnected,
        minutesRemaining: minutes
      )
    }
    return BatteryReading()
  }

  fileprivate nonisolated static func displayBrightness() -> Float? {
    displayServicesBrightness() ?? ioDisplayBrightness()
  }

  fileprivate nonisolated static func setDisplayBrightness(_ value: Float) {
    if setDisplayServicesBrightness(value) {
      return
    }
    guard let service = displayService() else { return }
    defer { IOObjectRelease(service) }
    _ = IODisplaySetFloatParameter(
      service,
      0,
      kIODisplayBrightnessKey as CFString,
      value
    )
  }

  /// `IODisplayConnect` no longer controls the built-in panel on many apple
  /// silicon Macs. DisplayServices remains the system path used by macOS for
  /// that panel, so use it dynamically and retain IOKit for compatible
  /// external displays.
  fileprivate nonisolated static func displayServicesBrightness() -> Float? {
    typealias Getter =
      @convention(c) (
        CGDirectDisplayID,
        UnsafeMutablePointer<Float>
      ) -> Int32

    guard
      let handle = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
        RTLD_LAZY | RTLD_LOCAL
      )
    else {
      return nil
    }
    defer { dlclose(handle) }
    guard let symbol = dlsym(handle, "DisplayServicesGetBrightness") else {
      return nil
    }

    let getter = unsafeBitCast(symbol, to: Getter.self)
    var value: Float = 0.5
    return getter(CGMainDisplayID(), &value) == 0 ? value : nil
  }

  fileprivate nonisolated static func setDisplayServicesBrightness(_ value: Float) -> Bool {
    typealias Setter = @convention(c) (CGDirectDisplayID, Float) -> Int32

    guard
      let handle = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
        RTLD_LAZY | RTLD_LOCAL
      )
    else {
      return false
    }
    defer { dlclose(handle) }
    guard let symbol = dlsym(handle, "DisplayServicesSetBrightness") else {
      return false
    }

    let setter = unsafeBitCast(symbol, to: Setter.self)
    return setter(CGMainDisplayID(), value) == 0
  }

  fileprivate nonisolated static func ioDisplayBrightness() -> Float? {
    guard let service = displayService() else { return nil }
    defer { IOObjectRelease(service) }
    var value: Float = 0.5
    guard
      IODisplayGetFloatParameter(
        service,
        0,
        kIODisplayBrightnessKey as CFString,
        &value
      ) == kIOReturnSuccess
    else {
      return nil
    }
    return value
  }

  fileprivate nonisolated static func displayService() -> io_service_t? {
    var iterator: io_iterator_t = 0
    guard
      IOServiceGetMatchingServices(
        kIOMainPortDefault,
        IOServiceMatching("IODisplayConnect"),
        &iterator
      ) == kIOReturnSuccess
    else {
      return nil
    }
    defer { IOObjectRelease(iterator) }
    let service = IOIteratorNext(iterator)
    return service == 0 ? nil : service
  }

  fileprivate nonisolated static func cameraIsRunning() -> Bool {
    var address = CMIOObjectPropertyAddress(
      mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
      mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
      mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    var size: UInt32 = 0
    guard
      CMIOObjectGetPropertyDataSize(
        CMIOObjectID(kCMIOObjectSystemObject),
        &address,
        0,
        nil,
        &size
      ) == noErr
    else {
      return false
    }

    let count = Int(size) / MemoryLayout<CMIODeviceID>.size
    var devices = [CMIODeviceID](repeating: 0, count: count)
    guard
      CMIOObjectGetPropertyData(
        CMIOObjectID(kCMIOObjectSystemObject),
        &address,
        0,
        nil,
        size,
        &size,
        &devices
      ) == noErr
    else {
      return false
    }

    return devices.contains { device in
      cameraPropertyIsTrue(
        device,
        selector: CMIOObjectPropertySelector(
          kCMIODevicePropertyDeviceIsRunningSomewhere
        )
      )
        || cameraPropertyIsTrue(
          device,
          selector: CMIOObjectPropertySelector(
            kCMIODevicePropertyDeviceIsRunning
          )
        )
    }
  }

  fileprivate nonisolated static func microphoneIsInUseByAnotherApplication() -> Bool {
    AVCaptureDevice.default(for: .audio)?.isInUseByAnotherApplication == true
  }

  fileprivate nonisolated static func cameraPropertyIsTrue(
    _ device: CMIODeviceID,
    selector: CMIOObjectPropertySelector
  ) -> Bool {
    var running: UInt32 = 0
    var runningSize = UInt32(MemoryLayout<UInt32>.size)
    var address = CMIOObjectPropertyAddress(
      mSelector: selector,
      mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
      mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    guard CMIOObjectHasProperty(device, &address) else { return false }
    return CMIOObjectGetPropertyData(
      device,
      &address,
      0,
      nil,
      runningSize,
      &runningSize,
      &running
    ) == noErr && running != 0
  }
}
