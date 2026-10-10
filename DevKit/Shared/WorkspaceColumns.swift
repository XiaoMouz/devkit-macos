import AppKit
import SwiftUI

/// Explicit viewports prevent native split-view intrinsic sizes from shrinking or offsetting editors.
struct WorkspaceColumns<First: View, Second: View>: View {
  @State private var fraction: CGFloat = 0.5
  @State private var dragStart: CGFloat?
  @State private var hovering = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @ViewBuilder let first: () -> First
  @ViewBuilder let second: () -> Second
  var body: some View {
    GeometryReader { bounds in
      let usable = max(0, bounds.size.width - WorkspaceMetrics.paneGap)
      let minimum = min(280, usable * 0.4)
      let left = min(max(usable * fraction, minimum), max(minimum, usable - minimum))
      HStack(spacing: 0) {
        first().frame(width: left, height: bounds.size.height, alignment: .topLeading)
        // Floating panes are separated by the gap itself; a grip marks the handle.
        Rectangle().fill(.clear).frame(width: WorkspaceMetrics.paneGap)
          .overlay { Capsule().fill(.secondary.opacity(hovering ? 0.55 : 0.25)).frame(width: 3, height: 24) }
          .contentShape(Rectangle())
          .onHover { inside in
            guard inside != hovering else { return }
            hovering = inside
            if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
          }
          .gesture(
            DragGesture(minimumDistance: 1)
              .onChanged { value in
                if dragStart == nil { dragStart = left }
                fraction = min(
                  max(((dragStart ?? left) + value.translation.width) / max(usable, 1), 0.2), 0.8)
              }
              .onEnded { _ in dragStart = nil }
          )
          .onTapGesture(count: 2) {
            withAnimation(WorkspaceMotion.layout(reduceMotion: reduceMotion)) { fraction = 0.5 }
          }
          .accessibilityLabel("调整左右面板宽度")
          .accessibilityAdjustableAction { direction in
            withAnimation(WorkspaceMotion.layout(reduceMotion: reduceMotion)) {
              fraction = min(max(fraction + (direction == .increment ? 0.05 : -0.05), 0.2), 0.8)
            }
          }
        second().frame(
          width: max(0, usable - left), height: bounds.size.height, alignment: .topLeading
        )
      }.frame(width: bounds.size.width, height: bounds.size.height, alignment: .topLeading)
    }
    .onDisappear {
      if hovering {
        NSCursor.pop()
        hovering = false
      }
    }
  }
}
