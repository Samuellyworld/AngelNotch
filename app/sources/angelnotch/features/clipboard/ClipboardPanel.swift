import AppKit
import SwiftUI

struct ClipboardPanel: View {
  @ObservedObject var store: ClipboardHistoryStore
  @State private var selectedID: UUID?

  var body: some View {
    VStack(spacing: 10) {
      searchField

      if store.filteredItems.isEmpty {
        EmptyPanel(
          symbol: "doc.on.clipboard",
          title: "Clipboard history is empty",
          detail: "Text and images you copy will appear here."
        )
      } else {
        HStack(spacing: 10) {
          ScrollView {
            LazyVStack(spacing: 5) {
              ForEach(store.filteredItems) { item in
                ClipboardRow(
                  item: item,
                  store: store,
                  isSelected: selectedItem?.id == item.id
                ) {
                  selectedID = item.id
                }
              }
            }
          }
          .frame(width: 245)

          ClipboardPreview(item: selectedItem, store: store)
        }
      }
    }
    .onAppear {
      selectedID = selectedID ?? store.filteredItems.first?.id
    }
    .onChange(of: store.searchQuery) { _, _ in
      keepSelectionValid()
    }
    .onChange(of: store.items) { _, _ in
      keepSelectionValid()
    }
  }

  private var searchField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(LoopDesign.Palette.textTertiary)
      TextField("Search copied text", text: $store.searchQuery)
        .textFieldStyle(.plain)
        .font(LoopDesign.TypeStyle.label)
      Button("Clear", action: store.clearUnpinned)
        .buttonStyle(.plain)
        .font(LoopDesign.TypeStyle.detail)
        .foregroundStyle(LoopDesign.Palette.textTertiary)
        .interactiveCursor()
    }
    .padding(.horizontal, 11)
    .frame(height: 32)
    .background(
      LoopDesign.Palette.surfaceQuiet,
      in: RoundedRectangle(cornerRadius: 10)
    )
  }

  private var selectedItem: ClipboardHistoryItem? {
    if let selectedID,
      let item = store.filteredItems.first(where: { $0.id == selectedID })
    {
      return item
    }
    return store.filteredItems.first
  }

  private func keepSelectionValid() {
    if !store.filteredItems.contains(where: { $0.id == selectedID }) {
      selectedID = store.filteredItems.first?.id
    }
  }
}

private struct ClipboardRow: View {
  let item: ClipboardHistoryItem
  @ObservedObject var store: ClipboardHistoryStore
  let isSelected: Bool
  let select: () -> Void

  var body: some View {
    HStack(spacing: 9) {
      thumbnail

      VStack(alignment: .leading, spacing: 3) {
        Text(item.text ?? "Image")
          .font(LoopDesign.TypeStyle.label)
          .foregroundStyle(LoopDesign.Palette.textPrimary)
          .lineLimit(1)
        Text(item.createdAt, style: .relative)
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textTertiary)
      }
      Spacer(minLength: 4)

      if item.isPinned {
        Circle()
          .fill(LoopDesign.Palette.accent)
          .frame(width: 5, height: 5)
      }
    }
    .padding(.horizontal, 9)
    .frame(height: 46)
    .contentShape(Rectangle())
    .onTapGesture(count: 2) {
      select()
      store.copy(item)
    }
    .onTapGesture(perform: select)
    .modifier(LoopHoverSurface(cornerRadius: 11, isSelected: isSelected))
    .help("Click to preview · Double-click to copy")
    .interactiveCursor()
  }

  @ViewBuilder
  private var thumbnail: some View {
    Group {
      if item.kind == .image,
        let url = store.imageURL(for: item),
        let image = NSImage(contentsOf: url)
      {
        Image(nsImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Text(textMonogram)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(LoopDesign.Palette.accent)
      }
    }
    .frame(width: 30, height: 30)
    .background(
      LoopDesign.Palette.surface,
      in: RoundedRectangle(cornerRadius: 8)
    )
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var textMonogram: String {
    guard
      let character = item.text?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .first
    else {
      return "⌘"
    }
    return String(character).uppercased()
  }
}

private struct ClipboardPreview: View {
  let item: ClipboardHistoryItem?
  @ObservedObject var store: ClipboardHistoryStore

  var body: some View {
    Group {
      if let item {
        VStack(alignment: .leading, spacing: 10) {
          previewContent(item)
          Spacer(minLength: 0)
          smartAction(for: item)
          actions(for: item)
        }
        .padding(12)
      } else {
        EmptyPanel(
          symbol: "doc.text.magnifyingglass",
          title: "Select an item",
          detail: "Its full contents will appear here."
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LoopDesign.Palette.surfaceQuiet,
      in: RoundedRectangle(cornerRadius: 14)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 14)
        .stroke(LoopDesign.Palette.outline, lineWidth: 0.7)
    }
  }

  @ViewBuilder
  private func previewContent(_ item: ClipboardHistoryItem) -> some View {
    if item.kind == .image,
      let url = store.imageURL(for: item),
      let image = NSImage(contentsOf: url)
    {
      Image(nsImage: image)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: 168)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      Text("\(Int(image.size.width)) × \(Int(image.size.height)) image")
        .font(LoopDesign.TypeStyle.detail)
        .foregroundStyle(LoopDesign.Palette.textTertiary)
    } else {
      ScrollView {
        Text(item.text ?? "")
          .font(.system(size: 12))
          .foregroundStyle(LoopDesign.Palette.textPrimary)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .topLeading)
      }
      .frame(maxHeight: 150)
      Text("\(item.text?.count ?? 0) characters")
        .font(LoopDesign.TypeStyle.detail)
        .foregroundStyle(LoopDesign.Palette.textTertiary)
    }
  }

  @ViewBuilder
  private func smartAction(for item: ClipboardHistoryItem) -> some View {
    if let url = detectedURL(item.text) {
      Button {
        NSWorkspace.shared.open(url)
      } label: {
        HStack {
          Text("Open link")
          Spacer()
          Image(systemName: "arrow.up.right")
        }
      }
      .buttonStyle(LoopTextButtonStyle())
    } else if let color = detectedColor(item.text) {
      HStack(spacing: 8) {
        Circle()
          .fill(color)
          .frame(width: 18, height: 18)
          .overlay(Circle().stroke(LoopDesign.Palette.outline))
        Text("Color detected")
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textSecondary)
        Spacer()
        Text(item.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .foregroundStyle(LoopDesign.Palette.textPrimary)
      }
      .padding(.horizontal, 10)
      .frame(height: 32)
      .background(
        LoopDesign.Palette.surface,
        in: RoundedRectangle(cornerRadius: 9)
      )
    }
  }

  private func actions(for item: ClipboardHistoryItem) -> some View {
    HStack(spacing: 8) {
      Button {
        store.copy(item)
      } label: {
        Label(
          store.recentlyCopiedID == item.id ? "Copied" : "Copy",
          systemImage: store.recentlyCopiedID == item.id
            ? "checkmark"
            : "doc.on.doc"
        )
      }
      .buttonStyle(LoopPrimaryButtonStyle())

      LoopIconButton(
        symbol: item.isPinned ? "pin.fill" : "pin",
        active: item.isPinned,
        help: item.isPinned ? "Unpin" : "Pin"
      ) {
        store.togglePinned(item)
      }

      LoopIconButton(symbol: "trash", help: "Delete") {
        store.delete(item)
      }
    }
  }

  private func detectedURL(_ text: String?) -> URL? {
    guard let value = text?.trimmingCharacters(in: .whitespacesAndNewlines),
      !value.contains(where: { $0.isWhitespace }),
      let url = URL(string: value),
      let scheme = url.scheme?.lowercased(),
      ["http", "https"].contains(scheme)
    else {
      return nil
    }
    return url
  }

  private func detectedColor(_ text: String?) -> Color? {
    guard var hex = text?.trimmingCharacters(in: .whitespacesAndNewlines),
      hex.hasPrefix("#")
    else {
      return nil
    }
    hex.removeFirst()
    if hex.count == 3 {
      hex = hex.map { "\($0)\($0)" }.joined()
    }
    guard hex.count == 6, let value = UInt64(hex, radix: 16) else {
      return nil
    }
    return Color(
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255
    )
  }
}
