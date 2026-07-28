import SwiftUI

struct ActivitiesPanel: View {
  @ObservedObject var center: LiveActivityCenter

  var body: some View {
    Group {
      if center.activities.isEmpty {
        VStack(spacing: 12) {
          EmptyPanel(
            symbol: "dot.radiowaves.left.and.right",
            title: "No live activities",
            detail: "Chrome downloads and local integrations appear here."
          )
          Button(action: center.chooseActivityFile) {
            Label("Import activity", systemImage: "plus")
          }
          .buttonStyle(
            LoopCapsuleButtonStyle(color: LoopDesign.Palette.cyan)
          )
        }
      } else {
        ScrollView {
          LazyVStack(spacing: 8) {
            ForEach(center.activities) { activity in
              HStack(spacing: 10) {
                Image(systemName: symbol(activity.kind))
                  .font(.title3)
                  .foregroundStyle(LoopDesign.Palette.cyan)
                VStack(alignment: .leading, spacing: 3) {
                  Text(activity.title)
                    .font(LoopDesign.TypeStyle.label)
                    .lineLimit(1)
                  Text(activity.detail)
                    .font(LoopDesign.TypeStyle.detail)
                    .foregroundStyle(LoopDesign.Palette.textSecondary)
                }
                Spacer()
                if let progress = activity.progress {
                  CircularProgress(
                    value: progress,
                    color: LoopDesign.Palette.cyan
                  )
                  .frame(width: 28, height: 28)
                }
              }
              .padding(.horizontal, 12)
              .frame(height: 52)
              .background(
                LoopDesign.Palette.surfaceQuiet,
                in: RoundedRectangle(cornerRadius: 14)
              )
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func symbol(_ kind: LoopActivityKind) -> String {
    switch kind {
    case .download: "arrow.down.circle.fill"
    case .delivery: "shippingbox.fill"
    case .sport: "figure.run"
    case .task: "gearshape.2.fill"
    }
  }
}
