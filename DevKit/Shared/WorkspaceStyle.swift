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

/// Title and actions share one fixed-height header. Narrow panes use icon buttons.
struct PaneActions<Content: View>: View {
  var title: String = ""
  var role: WorkspacePane = .input
  var format: String? = nil
  @ViewBuilder let content: () -> Content
  var body: some View {
    GlassEffectContainer(spacing: 8) {
      ViewThatFits(in: .horizontal) {
        row(compact: false).labelStyle(.titleAndIcon)
        row(compact: true).labelStyle(.iconOnly)
      }
    }
    .buttonStyle(.glass).buttonBorderShape(.capsule).controlSize(.small)
    .paneActionRow()
    .overlay(alignment: .bottom) { Divider().opacity(0.55) }
  }
  private func row(compact: Bool) -> some View {
    HStack(spacing: 8) {
      let tint: Color = role == .output ? .purple : role == .secondary ? .orange : .blue
      ToolIconTile(symbol: role == .output ? "arrow.down.right" : "square.and.pencil", tint: tint, size: 22)
      Text(title).font(.system(size: 12, weight: .semibold)).lineLimit(1).fixedSize()
      if let format, !compact {
        Text(format).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
          .padding(.horizontal, 5).padding(.vertical, 3)
          .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 4))
          .fixedSize()
      }
      if role == .output {
        Image(systemName: "lock").font(.system(size: 10)).foregroundStyle(.secondary)
          .help("只读").accessibilityLabel("只读")
      }
      Spacer(minLength: 8)
      content().fixedSize()
    }
  }
}

struct PaneStatus {
  let title: String
  let symbol: String
  let tint: Color
  var detail: String? = nil
  var elapsed: String? = nil
}

struct PaneStatusLabel: View {
  let status: PaneStatus
  @State private var detailsPresented = false
  var body: some View {
    HStack(spacing: 8) {
      if let detail = status.detail {
        Button { detailsPresented.toggle() } label: {
          Label(status.title, systemImage: status.symbol).lineLimit(1)
        }.buttonStyle(.plain).foregroundStyle(status.tint).help(detail)
          .popover(isPresented: $detailsPresented) {
            ScrollView { Text(detail).font(.body).foregroundStyle(.primary).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(16) }
              .frame(width: 340, height: 180)
          }
      } else {
        Label(status.title, systemImage: status.symbol).foregroundStyle(status.tint).lineLimit(1)
      }
      if let elapsed = status.elapsed { Text(elapsed).monospacedDigit().foregroundStyle(.secondary) }
    }
  }
}

struct WorkspaceEmptyState<Actions: View>: View {
  let title: String
  let detail: String
  let symbol: String
  var tint: Color = .blue
  @ViewBuilder var actions: () -> Actions
  var body: some View {
    VStack(spacing: 12) {
      ToolIconTile(symbol: symbol, tint: tint, size: 44).padding(.bottom, 3).allowsHitTesting(false)
      Text(title).font(.system(size: 14, weight: .medium)).allowsHitTesting(false)
      Text(detail).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).allowsHitTesting(false)
      GlassEffectContainer(spacing: 8) {
        actions().font(.caption).buttonStyle(.glass).buttonBorderShape(.capsule).tint(tint)
      }
    }.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
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
  @ViewBuilder var body: some View {
    if inToolbar {
      nativePicker.fixedSize()
    } else {
      GlassEffectContainer(spacing: 4) {
        HStack(spacing: 4) {
          ForEach(items.indices, id: \.self) { index in
            Button { selection = items[index].1 } label: {
              itemLabel(at: index).padding(.horizontal, 3)
            }
            .modifier(GlassSelectionStyle(selected: selection == items[index].1))
            .accessibilityLabel(items[index].0)
            .accessibilityAddTraits(selection == items[index].1 ? .isSelected : [])
          }
        }.buttonBorderShape(.capsule).controlSize(.small).fixedSize()
          .onMoveCommand { direction in
            guard let current = items.firstIndex(where: { $0.1 == selection }) else { return }
            let step = direction == .left ? -1 : direction == .right ? 1 : 0
            let next = current + step
            if items.indices.contains(next) { selection = items[next].1 }
          }
      }
    }
  }
  private var nativePicker: some View {
    Picker("切换", selection: $selection) {
      ForEach(items.indices, id: \.self) { index in
        itemLabel(at: index).tag(items[index].1)
      }
    }
    .labelsHidden().pickerStyle(.segmented)
  }
  @ViewBuilder private func itemLabel(at index: Int) -> some View {
    if let symbol = symbols[items[index].1] {
      if iconOnly {
        Label(items[index].0, systemImage: symbol).labelStyle(.iconOnly).help(items[index].0)
      } else {
        Label(items[index].0, systemImage: symbol).labelStyle(.titleAndIcon)
      }
    } else { Text(items[index].0) }
  }
}
private struct GlassSelectionStyle: ViewModifier {
  let selected: Bool
  func body(content: Content) -> some View {
    if selected {
      content.buttonStyle(.glassProminent)
    } else {
      content.buttonStyle(.glass)
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
struct WorkspacePaneDeck<Pane: View, Actions: View>: View {
  let roles: [WorkspacePane]
  let visible: [WorkspacePane]
  var titles: [WorkspacePane: String] = [:]
  var formats: [WorkspacePane: String] = [:]
  @ViewBuilder let actions: (WorkspacePane) -> Actions
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
            PaneActions(title: titles[role] ?? role.rawValue, role: role, format: formats[role]) { actions(role) }
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
