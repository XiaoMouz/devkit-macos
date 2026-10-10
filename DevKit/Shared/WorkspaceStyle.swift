import DevKitCore
import SwiftUI

enum WorkspaceMetrics {
  static let sidebarWidth: CGFloat = 232
  static let inset: CGFloat = 12
  static let paneGap: CGFloat = 12
  static let cornerRadius: CGFloat = 16
}

enum WorkspaceMotion {
  static func layout(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : .smooth(duration: 0.26, extraBounce: 0)
  }
}

/// Count and disclosure keep separate, fixed slots, including while hovering.
struct SidebarSectionHeader: View {
  let title: String
  let symbol: String
  let tint: Color
  let count: Int
  @Binding var expanded: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var hovering = false
  var body: some View {
    Button {
      withAnimation(WorkspaceMotion.layout(reduceMotion: reduceMotion)) { expanded.toggle() }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: symbol).foregroundStyle(tint).frame(width: 16)
        Text(title).lineLimit(1)
        Spacer(minLength: 4)
        Text("\(count)").monospacedDigit().frame(width: 22, alignment: .trailing)
        Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
          .rotationEffect(.degrees(expanded ? 90 : 0)).frame(width: 12, height: 16)
          .opacity(hovering ? 1 : 0.5)
      }
      .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
      .padding(.trailing, 10).frame(height: 28).contentShape(Rectangle())
    }
    .buttonStyle(.plain).padding(.top, 8).padding(.bottom, 2)
    .onHover { hovering = $0 }
    .accessibilityLabel("\(title)，\(count) 个工具")
    .accessibilityValue(expanded ? "已展开" : "已收起")
    .accessibilityHint(expanded ? "收起分类" : "展开分类")
  }
}

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
  @Environment(\.colorScheme) private var colorScheme
  var body: some View {
    Image(systemName: symbol)
      .font(.system(size: size * 0.52, weight: .medium))
      .symbolRenderingMode(.hierarchical)
      .foregroundStyle(tint)
      .frame(width: size, height: size)
      // Dark surfaces need more tint for the tile to read as a shape at all.
      .background(tint.opacity((emphasized ? 0.2 : 0.12) + (colorScheme == .dark ? 0.06 : 0)),
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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
      .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovering)
  }
  private var fillOpacity: Double {
    if configuration.isPressed { return style.resting + 0.11 }
    if style.selected { return 0.1 }
    return style.resting + (hovering ? 0.05 : 0)
  }
}

extension NSColor {
  /// The window's base layer, beneath the floating sidebar and content panes.
  static var workspaceBase: NSColor {
    NSColor(name: "workspaceBase") { appearance in
      appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .textBackgroundColor : .windowBackgroundColor
    }
  }
  /// Elevated content panes: white on the light window grey, and a lighter
  /// surface than the base in dark mode, as elevated dark surfaces are.
  static var workspaceCard: NSColor {
    NSColor(name: "workspaceCard") { appearance in
      appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? NSColor(white: 0.17, alpha: 1) : .textBackgroundColor
    }
  }
}

/// Lifts a content pane off the base layer. Content stays on an opaque surface;
/// Liquid Glass is reserved for controls and navigation, not for text being edited.
private struct FloatingPane: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.colorSchemeContrast) private var contrast
  func body(content: Content) -> some View {
    let shape = RoundedRectangle(cornerRadius: WorkspaceMetrics.cornerRadius, style: .continuous)
    let dark = colorScheme == .dark
    content
      .background(Color(nsColor: .workspaceCard))
      .clipShape(shape)
      .overlay {
        shape.strokeBorder(.primary.opacity(contrast == .increased ? 0.3 : dark ? 0.1 : 0.07), lineWidth: 1)
          .allowsHitTesting(false)
      }
      .background {
        shape.fill(Color(nsColor: .workspaceCard))
          .shadow(color: .black.opacity(dark ? 0.35 : 0.08), radius: dark ? 10 : 8, y: 2)
      }
  }
}
/// One behind-window material, as in the stashed chrome, without an opaque fill
/// beneath it or a second glass sheet. The system supplies its appearance/contrast.
private struct SidebarMaterial: NSViewRepresentable {
  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = .sidebar
    view.blendingMode = .behindWindow
    view.state = .followsWindowActiveState
    return view
  }
  func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

private struct FloatingSidebarPanel: ViewModifier {
  private let inset: CGFloat = 8
  private let radius = WorkspaceMetrics.cornerRadius
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.colorSchemeContrast) private var contrast
  func body(content: Content) -> some View {
    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
    content
      // Rows scroll to the panel's bottom edge, so they follow its rounded corners.
      .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: radius, bottomTrailingRadius: radius,
        style: .continuous))
      .background {
        Group {
          if reduceTransparency {
            Color(nsColor: .windowBackgroundColor)
          } else {
            SidebarMaterial()
          }
        }
        .clipShape(shape)
        .overlay { shape.strokeBorder(.primary.opacity(contrast == .increased ? 0.3 : 0.08), lineWidth: 1) }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.14 : 0.05), radius: 5, y: 2)
        // Reach up beneath the toolbar so the traffic lights sit inside the panel.
        .padding(.top, inset).ignoresSafeArea(.container, edges: .top)
      }
      .padding(.horizontal, inset).padding(.bottom, inset)
      .background { Color(nsColor: .workspaceBase).ignoresSafeArea() }
  }
}
extension View {
  func floatingPane() -> some View { modifier(FloatingPane()) }
  func floatingSidebarPanel() -> some View { modifier(FloatingSidebarPanel()) }
}

extension View {
  /// Every pane's action row shares one height and inset, so the editors below
  /// start on the same line in the comparison view.
  func paneActionRow() -> some View {
    padding(.horizontal, 16).frame(height: 44)
  }
}

/// A pane's action row: regular-size bordered buttons with symbol and title, falling
/// back to symbols alone when a narrow split pane cannot fit the titles. Buttons on
/// content surfaces use the standard bordered style; glass is for floating controls.
struct PaneActions<Content: View>: View {
  @ViewBuilder let content: () -> Content
  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 8) { content() }.labelStyle(.titleAndIcon)
      HStack(spacing: 8) { content() }.labelStyle(.iconOnly)
    }
    .buttonStyle(.bordered).buttonBorderShape(.capsule).controlSize(.regular)
    .paneActionRow()
  }
}

/// Run time worth showing: short runs are dominated by worker start-up, so they
/// are omitted rather than presented as the tool's own cost.
func elapsedLabel(_ seconds: Double) -> String? {
  guard seconds >= 0.25 else { return nil }
  return seconds < 1 ? String(format: "%.0f ms", seconds * 1000) : String(format: "%.1f s", seconds)
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
  /// In a window toolbar the system supplies the glass and sizing; adding a small
  /// control size or another glass capsule nests a cramped control inside the item.
  var inToolbar = false
  /// View switchers show symbols only (as Finder's view modes do); titles remain
  /// the accessibility labels.
  var iconOnly = false
  var body: some View {
    Picker("切换", selection: $selection) {
      ForEach(items.indices, id: \.self) { index in
        Group {
          if let symbol = symbols[items[index].1] {
            if iconOnly {
              Label(items[index].0, systemImage: symbol).labelStyle(.iconOnly).help(items[index].0)
            } else {
              Label(items[index].0, systemImage: symbol).labelStyle(.titleAndIcon)
            }
          } else { Text(items[index].0) }
        }.tag(items[index].1)
      }
    }
    .labelsHidden().pickerStyle(.segmented)
    .modifier(SegmentsChrome(inToolbar: inToolbar))
  }
}
private struct SegmentsChrome: ViewModifier {
  let inToolbar: Bool
  func body(content: Content) -> some View {
    if inToolbar {
      content.fixedSize()
    } else {
      content.controlSize(.small).fixedSize().glassEffect(.regular, in: .capsule)
    }
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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var body: some View {
    GeometryReader { bounds in
      let split = visible.count == 2
      let gap = WorkspaceMetrics.paneGap
      let space = max(0, bounds.size.width - gap)
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
            }.foregroundStyle(.secondary).padding(.horizontal, 16).padding(.top, 6).frame(height: 30)
            pane(role).frame(maxWidth: .infinity, maxHeight: .infinity)
          }
            .frame(
              width: split && shown ? (second ? space - left : left) : bounds.size.width,
              height: bounds.size.height, alignment: .topLeading
            )
            .floatingPane()
            .offset(x: second ? left + gap : 0)
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(shown).disabled(!shown)
            .accessibilityElement(children: .contain).accessibilityHidden(!shown)
        }
        if split {
          Rectangle().fill(.clear).frame(width: gap, height: bounds.size.height)
            .overlay {
              // The gap between floating panes is the divider; only a grip remains.
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
            .onTapGesture(count: 2) {
              withAnimation(WorkspaceMotion.layout(reduceMotion: reduceMotion)) { fraction = 0.5 }
            }
            .accessibilityLabel("调整对照面板宽度")
            .accessibilityAdjustableAction { direction in
              withAnimation(WorkspaceMotion.layout(reduceMotion: reduceMotion)) {
                fraction = min(max(fraction + (direction == .increment ? 0.05 : -0.05), 0.25), 0.75)
              }
            }
        }
      // Not clipped: pane shadows fall outside the deck; hidden panes stay within it.
      }.frame(width: bounds.size.width, height: bounds.size.height, alignment: .topLeading)
        .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: visible)
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
