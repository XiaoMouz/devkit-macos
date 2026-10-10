import SwiftUI

struct WorkspaceCard: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 9))
      .clipShape(RoundedRectangle(cornerRadius: 9))
      .overlay {
        RoundedRectangle(cornerRadius: 9).strokeBorder(.primary.opacity(0.08), lineWidth: 1)
      }
  }
}
extension View {
  func workspaceCard() -> some View { modifier(WorkspaceCard()) }
}

/// A quiet, continuous boundary remains visible even with reduced transparency.
struct WorkspaceBoundary: View {
  var body: some View {
    HStack(spacing: 0) { Divider() }.frame(width: 1)
      .allowsHitTesting(false).accessibilityHidden(true)
  }
}

struct WorkspaceSegments<Value: Hashable>: View {
  let items: [(String, Value)]
  @Binding var selection: Value
  var symbols: [Value: String] = [:]
  var body: some View {
    Picker("切换", selection: $selection) {
      ForEach(items.indices, id: \.self) { index in
        Group {
          if let symbol = symbols[items[index].1] { Label(items[index].0, systemImage: symbol) }
          else { Text(items[index].0) }
        }.tag(items[index].1)
      }
    }
    .labelsHidden().pickerStyle(.segmented).controlSize(.small)
    .fixedSize().glassEffect(.regular, in: .capsule)
  }
}

enum WorkspacePane: String, CaseIterable, Identifiable {
  case input, secondary, output
  var id: String { rawValue }
}
enum DetachedWorkspacePane: String {
  case input, secondary, output, comparison
  var title: String {
    switch self {
    case .input: "输入"
    case .secondary: "第二输入"
    case .output: "结果"
    case .comparison: "对照"
    }
  }
}

/// Stable pane identity keeps editor selection and scroll position when switching layout.
struct WorkspacePaneDeck<Pane: View>: View {
  let roles: [WorkspacePane]
  let visible: [WorkspacePane]
  var titles: [WorkspacePane: String] = [:]
  @ViewBuilder let pane: (WorkspacePane) -> Pane
  @State private var fraction: CGFloat = 0.5
  @State private var dragStart: CGFloat?
  @State private var hovering = false
  var body: some View {
    GeometryReader { bounds in
      let split = visible.count == 2
      let space = max(0, bounds.size.width - 16)
      let left = min(
        max(space * fraction, min(320, space * 0.4)), max(0, space - min(320, space * 0.4)))
      ZStack(alignment: .topLeading) {
        ForEach(roles) { role in
          let shown = visible.contains(role)
          let second = split && visible.last == role
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
              Text(titles[role] ?? role.rawValue).font(.system(size: 11, weight: .medium))
              Spacer()
              if role == .output { Text("只读").font(.system(size: 10)) }
            }.foregroundStyle(.secondary).padding(.horizontal, 16).frame(height: 24)
            pane(role).frame(maxWidth: .infinity, maxHeight: .infinity)
          }
            .frame(
              width: split && shown ? (second ? space - left : left) : bounds.size.width,
              height: bounds.size.height, alignment: .topLeading
            )
            .background(Color(nsColor: .textBackgroundColor))
            .offset(x: second ? left + 16 : 0)
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(shown).disabled(!shown)
            .accessibilityElement(children: .contain).accessibilityHidden(!shown)
        }
        if split {
          Rectangle().fill(.clear).frame(width: 16, height: bounds.size.height)
            .overlay {
              Rectangle().fill(.primary.opacity(0.09)).frame(width: 1)
              Capsule().fill(.secondary.opacity(hovering ? 0.55 : 0.25)).frame(width: 3, height: 24)
            }
            .contentShape(Rectangle()).offset(x: left)
            .onHover { inside in
              guard inside != hovering else { return }
              hovering = inside
              if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            .gesture(
              DragGesture(minimumDistance: 1).onChanged { value in
                if dragStart == nil { dragStart = left }
                fraction = min(
                  max(((dragStart ?? left) + value.translation.width) / max(space, 1), 0.25), 0.75)
              }.onEnded { _ in dragStart = nil }
            )
            .onTapGesture(count: 2) { fraction = 0.5 }
            .accessibilityLabel("调整对照面板宽度")
            .accessibilityAdjustableAction { direction in
              fraction = min(max(fraction + (direction == .increment ? 0.05 : -0.05), 0.25), 0.75)
            }
        }
      }.frame(width: bounds.size.width, height: bounds.size.height, alignment: .topLeading)
        .clipped()
    }
    .onChange(of: visible) { _, _ in
      if hovering {
        NSCursor.pop()
        hovering = false
      }
    }
    .onDisappear {
      if hovering {
        NSCursor.pop()
        hovering = false
      }
    }
  }
}
