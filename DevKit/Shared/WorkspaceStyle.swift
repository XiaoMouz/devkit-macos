import DevKitCore
import SwiftUI

extension ToolCategory {
  /// Content-layer identity colour. Used only for small icon glyphs and their
  /// low-opacity tiles, never for selection, which stays on neutral surfaces.
  var tint: Color {
    switch self {
    case .encoding: .blue
    case .structured: .indigo
    case .security: .pink
    case .generators: .orange
    case .text: .teal
    case .numbers: .green
    case .web: .cyan
    case .css: .purple
    case .assets: .mint
    }
  }
}

struct ToolIconTile: View {
  let symbol: String
  var tint: Color = .accentColor
  var size: CGFloat = 24
  var emphasized = false
  var body: some View {
    Image(systemName: symbol)
      .font(.system(size: size * 0.52, weight: .medium))
      .symbolRenderingMode(.hierarchical)
      .foregroundStyle(tint)
      .frame(width: size, height: size)
      .background(tint.opacity(emphasized ? 0.2 : 0.12),
        in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
      .accessibilityHidden(true)
  }
}

/// Right-aligned count with tabular digits and a fixed minimum width.
struct CountBadge: View {
  let count: Int
  var body: some View {
    Text("\(count)").font(.system(size: 10, weight: .medium)).monospacedDigit()
      .foregroundStyle(.secondary).padding(.horizontal, 6).frame(minWidth: 22, minHeight: 16)
      .background(.primary.opacity(0.06), in: Capsule())
  }
}

/// A plain list or card button with quiet hover, press and selection surfaces.
struct HoverSurfaceButtonStyle: ButtonStyle {
  var cornerRadius: CGFloat = 8
  var selected = false
  var resting = 0.0
  var bordered = false
  func makeBody(configuration: Configuration) -> some View {
    HoverSurface(configuration: configuration, style: self)
  }
}
private struct HoverSurface: View {
  let configuration: ButtonStyleConfiguration
  let style: HoverSurfaceButtonStyle
  @Environment(\.isEnabled) private var isEnabled
  @State private var hovering = false
  var body: some View {
    let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
    configuration.label
      .background(shape.fill(.primary.opacity(fillOpacity)))
      .overlay {
        if style.bordered {
          shape.strokeBorder(.primary.opacity(hovering ? 0.14 : 0.07), lineWidth: 1)
        }
      }
      .contentShape(shape)
      .onHover { hovering = isEnabled && $0 }
      .animation(.easeOut(duration: 0.12), value: hovering)
  }
  private var fillOpacity: Double {
    if configuration.isPressed { return style.resting + 0.11 }
    if style.selected { return 0.1 }
    return style.resting + (hovering ? 0.05 : 0)
  }
}

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

extension View {
  /// Every pane's action row shares one height and inset, so the editors below
  /// start on the same line in the comparison view.
  func paneActionRow() -> some View {
    padding(.horizontal, 16).frame(height: 40)
  }
}

extension EnvironmentValues {
  /// False for tools kept alive in the background, so only the visible tool
  /// contributes items to the shared window toolbar.
  @Entry var workspaceActive = true
}

struct WorkspaceSegments<Value: Hashable>: View {
  let items: [(String, Value)]
  @Binding var selection: Value
  var symbols: [Value: String] = [:]
  /// Controls already placed on a glass panel must not add a second glass layer.
  var glass = true
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
    .fixedSize().glassEffect(glass ? .regular : .identity, in: .capsule)
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
              if role == .output {
                Label("只读", systemImage: "lock").font(.system(size: 10)).labelStyle(.titleAndIcon)
              }
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
