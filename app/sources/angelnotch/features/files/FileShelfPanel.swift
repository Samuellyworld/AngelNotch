import AppKit
import SwiftUI

struct FileShelfPanel: View {
  @ObservedObject var store: FileShelfStore

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Label(
          "Drop files anywhere in this panel",
          systemImage: "plus.circle.fill"
        )
        .font(LoopDesign.TypeStyle.label)
        .foregroundStyle(LoopDesign.Palette.textSecondary)
        Spacer()
        Text("Auto-clean: \(store.cleanupAfterDays)d")
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textTertiary)
      }
      .padding(.horizontal, 11)
      .frame(height: 34)
      .background(LoopDesign.Palette.surface, in: Capsule())

      if store.items.isEmpty {
        EmptyPanel(
          symbol: "tray.and.arrow.down.fill",
          title: "Your shelf is empty",
          detail: "Drop files to keep them available after restart."
        )
      } else {
        ScrollView {
          LazyVStack(spacing: 6) {
            ForEach(store.items) { item in
              ShelfFileRow(item: item, store: store)
            }
          }
        }
      }
    }
    .dropDestination(for: URL.self) { urls, _ in
      let files = urls.filter(\.isFileURL)
      store.add(files)
      return !files.isEmpty
    }
  }
}

private struct ShelfFileRow: View {
  let item: ShelfFile
  @ObservedObject var store: FileShelfStore

  var body: some View {
    HStack(spacing: 8) {
      if let url = store.resolvedURL(for: item) {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
          .resizable()
          .frame(width: 30, height: 30)
      }
      Button(item.displayName) {
        store.open(item)
      }
      .buttonStyle(.plain)
      .font(LoopDesign.TypeStyle.label)
      .lineLimit(1)
      .interactiveCursor()
      Spacer()
      FileAction(symbol: "eye") { store.quickLook(item) }
      FileAction(symbol: "square.and.arrow.up") {
        store.share(item, from: NSApp.keyWindow?.contentView)
      }
      FileAction(symbol: "airplayaudio") { store.airDrop(item) }
      FileAction(symbol: item.isPinned ? "pin.fill" : "pin") {
        store.togglePinned(item)
      }
      FileAction(symbol: "xmark") { store.remove(item) }
    }
    .padding(.horizontal, 10)
    .frame(height: 44)
    .background(
      LoopDesign.Palette.surfaceQuiet,
      in: RoundedRectangle(cornerRadius: 12)
    )
  }
}
