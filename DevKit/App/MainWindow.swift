import DevKitCore
import SwiftUI

struct MainWindow: View {
  @State private var workspace = WindowWorkspace()
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage("showToolConfiguration") private var configurationVisible = true
  @AppStorage(FavoriteTools.key) private var favorites = FavoriteTools.defaults
  /// Incremented to move keyboard focus into the sidebar search field.
  private var searchRequest: Int { workspace.searchRequest }
  private var active: ToolTab? { workspace.active }
  private var favoriteIDs: [String] { FavoriteTools.ids(favorites) }
  private var favoriteTools: [ToolMetadata] {
    favoriteIDs.compactMap { ToolCatalogue.byID[$0] }
  }
  @State private var columns = NavigationSplitViewVisibility.all
  // Keep native toolbar and collapse behavior, with a fixed-width sidebar and
  // a single inset, behind-window material surface.
  var body: some View {
    NavigationSplitView(columnVisibility: $columns) {
      ToolSidebar(workspace: workspace).navigationSplitViewColumnWidth(WorkspaceMetrics.sidebarWidth)
        .background(FixedSidebarWidth(width: WorkspaceMetrics.sidebarWidth))
        // The system toggle is a standalone glass button; over the glass panel it
        // stacks glass on glass and sits flush with the panel's top edge.
        .toolbar(removing: .sidebarToggle)
        .toolbar {
          ToolbarItem { sidebarToggle }.sharedBackgroundVisibility(.hidden)
        }
    } detail: {
      detail
    }
    .frame(minWidth: 900, minHeight: 580)
    // A distinct base layer lets the floating sidebar and content panes read as
    // elevated, instead of merging with a window background of the same tone.
    .containerBackground(Color(nsColor: .workspaceBase), for: .window)
    .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: columns)
    .background(WindowCommandScope(actions: commandActions))
    .onChange(of: searchRequest) { _, _ in columns = .all }
  }
  private var detail: some View {
    GeometryReader { bounds in
      ZStack {
        if let tab = active {
          tab.view
            .frame(width: bounds.size.width, height: bounds.size.height)
            .id(tab.id)
        } else { home }
      }.frame(width: bounds.size.width, height: bounds.size.height).clipped()
    }
    .background { Color(nsColor: .workspaceBase).ignoresSafeArea() }
    .navigationTitle(active?.metadata.name ?? L10n.tr("All Tools"))
    .toolbar { toolbarContent }
    .inspector(isPresented: inspectorVisible) {
      if let active { active.configuration.id(active.id).inspectorColumnWidth(min: 220, ideal: 260, max: 360) }
    }
    .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: inspectorVisible.wrappedValue)
  }
  private var inspectorVisible: Binding<Bool> {
    Binding(get: { configurationVisible && active?.hasConfiguration == true },
      set: { configurationVisible = $0 })
  }
  @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
    if columns == .detailOnly {
      // With the panel hidden, the toggle moves to the leading end of the window toolbar.
      ToolbarItem(placement: .navigation) { sidebarToggle }
    }
    if let active {
      ToolbarItem(placement: .principal) { active.primaryControl.id(active.id) }
    }
    // Tool workspaces add their own trailing group so the primary action stays last;
    // only the WebSocket client, which has no tool workspace, is served from here.
    if let active, active.metadata.id == "websocket" {
      ToolbarItem(placement: .primaryAction) {
        Button { toggleFavorite(active.metadata.id) } label: {
          Label(L10n.tr("Favorites"), systemImage: favoriteIDs.contains(active.metadata.id) ? "star.fill" : "star")
            .contentTransition(.symbolEffect(.replace))
        }.help(favoriteIDs.contains(active.metadata.id) ? L10n.tr("Remove from Favorites") : L10n.tr("Add Current Tool to Favorites"))
      }
      ToolbarSpacer(.fixed, placement: .primaryAction)
      ToolbarItem(placement: .primaryAction) {
        Button { active.bridge.execute() } label: {
          Label(runTitle(active), systemImage: active.bridge.running ? "stop.fill" : "play.fill")
            .labelStyle(.titleAndIcon).padding(.horizontal, 6)
        }.buttonStyle(.borderedProminent)
          .help(active.bridge.running ? L10n.tr("Disconnect") : L10n.tr("Connect ⌘↩︎"))
      }
      if active.hasConfiguration {
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItem(placement: .primaryAction) {
          Button { configurationVisible.toggle() } label: {
            Label(L10n.tr("Inspector"), systemImage: "sidebar.right")
          }.help(L10n.tr("Show or Hide Configuration"))
        }
      }
    }
  }
  private var sidebarToggle: some View {
    let hidden = columns == .detailOnly
    return Button {
      withAnimation(WorkspaceMotion.layout(reduceMotion: reduceMotion)) {
        columns = hidden ? .all : .detailOnly
      }
    } label: {
      Label(hidden ? L10n.tr("Show Sidebar") : L10n.tr("Hide Sidebar"), systemImage: "sidebar.left")
    }.labelStyle(.iconOnly).help(hidden ? L10n.tr("Show Sidebar ⌃⌘S") : L10n.tr("Hide Sidebar ⌃⌘S"))
  }
  private func runTitle(_ tab: ToolTab) -> String {
    if tab.metadata.id == "websocket" { return tab.bridge.running ? L10n.tr("Disconnect") : L10n.tr("Connect") }
    return tab.bridge.running ? L10n.tr("Cancel") : tab.bridge.actionTitle
  }
  private var commandActions: WorkspaceActions {
    workspace.commands
  }
  private var home: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 30) {
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("Everyday tools, ready when you are.")).font(.title.weight(.semibold))
          Text(L10n.tr("Encoding, data, text, and web assets in one native workspace.")).foregroundStyle(.secondary)
          HStack(spacing: 14) {
            Label(L10n.tr("Tools: \(ToolRegistry.all.count)"), systemImage: "square.grid.2x2")
            Label(L10n.tr("Categories: \(ToolCategory.allCases.count)"), systemImage: "folder")
            Label(L10n.tr("Local Processing"), systemImage: "lock.shield")
          }.font(.caption).foregroundStyle(.secondary).padding(.top, 4)
        }.padding(.top, 20)
        if !favoriteTools.isEmpty {
          homeSection(L10n.tr("Favorites"), symbol: "star.fill", tint: .yellow, tools: favoriteTools)
        }
        ForEach(ToolCategory.allCases, id: \.self) { category in
          homeSection(category.title, symbol: category.symbol, tint: category.tint,
            tools: ToolCatalogue.byCategory[category] ?? [])
        }
      }.padding(30).frame(maxWidth: 1180, alignment: .leading).frame(maxWidth: .infinity)
    }
  }
  private func homeSection(_ title: String, symbol: String, tint: Color, tools: [ToolMetadata]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        ToolIconTile(symbol: symbol, tint: tint, size: 22)
        Text(title).font(.headline)
        CountBadge(count: tools.count)
      }
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10, alignment: .leading)],
        alignment: .leading, spacing: 10) {
        ForEach(tools) { item in
          Button { open(item.id) } label: {
            HStack(alignment: .top, spacing: 12) {
              ToolIconTile(symbol: item.symbol, tint: item.category.tint, size: 32)
              VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.system(size: 13, weight: .medium)).foregroundStyle(.primary).lineLimit(1)
                Text(item.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                  .fixedSize(horizontal: false, vertical: true)
              }
              Spacer(minLength: 0)
            }.padding(12).frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
          }.buttonStyle(HoverSurfaceButtonStyle(cornerRadius: 12, resting: 0.035, bordered: true))
            .help(item.summary)
            .contextMenu { Button(favoriteIDs.contains(item.id) ? L10n.tr("Remove from Favorites") : L10n.tr("Favorites")) { toggleFavorite(item.id) } }
        }
      }
    }
  }
  private func open(_ id: String) {
    workspace.open(id)
  }
  private func toggleFavorite(_ id: String) { favorites = FavoriteTools.toggling(id, in: favorites) }
}

/// Search and disclosure changes only invalidate the sidebar, not the active editor.
private struct ToolSidebar: View {
  let workspace: WindowWorkspace
  @State private var query = ""
  @State private var favoritesExpanded = true
  /// The sidebar row last chosen, so a favourite stays highlighted where it was clicked
  /// even though the same tool also appears in its category.
  @State private var sidebarTag: String?
  @State private var expandedCategories: Set<ToolCategory> = [.encoding]
  @AppStorage(FavoriteTools.key) private var favorites = FavoriteTools.defaults
  private var searchRequest: Int { workspace.searchRequest }
  private var favoriteIDs: [String] { FavoriteTools.ids(favorites) }
  private var favoriteTools: [ToolMetadata] { favoriteIDs.compactMap { ToolCatalogue.byID[$0] } }
  private var matches: [ToolMetadata] {
    ToolCatalogue.all.filter {
      (query.isEmpty || $0.searchText.localizedStandardContains(query))
    }
  }
  private static let favoritePrefix = "favorite:"
  private static func toolID(_ tag: String) -> String {
    tag.hasPrefix(favoritePrefix) ? String(tag.dropFirst(favoritePrefix.count)) : tag
  }
  private var sidebarSelection: Binding<String?> {
    Binding(get: {
      guard let id = workspace.navigation.selectedToolID else { return nil }
      if let sidebarTag, Self.toolID(sidebarTag) == id { return sidebarTag }
      return id
    }, set: { tag in
      sidebarTag = tag
      if let tag { open(Self.toolID(tag)) }
    })
  }
  var body: some View {
    VStack(spacing: 0) {
      SidebarSearchField(text: $query, prompt: L10n.tr("Search Tools"), focusRequest: searchRequest) {
        if let first = matches.first { open(first.id) }
      }.padding(.horizontal, 12).padding(.top, 2).padding(.bottom, 8)
      ScrollViewReader { scroll in
        List(selection: sidebarSelection) {
          if !query.isEmpty {
            ForEach(matches) { toolRow($0) }
          } else {
            // Favourites are pinned above the catalogue, as Finder and Music pin theirs,
            // instead of being a separate mode the list has to switch into.
            if !favoriteTools.isEmpty {
              Section {
                if favoritesExpanded {
                  ForEach(favoriteTools) { toolRow($0, tag: Self.favoritePrefix + $0.id) }
                }
              } header: {
                SidebarSectionHeader(title: L10n.tr("Favorites"), symbol: "star.fill", tint: .yellow,
                  count: favoriteTools.count, expanded: $favoritesExpanded)
              }
            }
            ForEach(ToolCategory.allCases, id: \.self) { category in
              let tools = ToolCatalogue.byCategory[category] ?? []
              Section {
                if expandedCategories.contains(category) { ForEach(tools) { toolRow($0) } }
              } header: {
                SidebarSectionHeader(title: category.title, symbol: category.symbol,
                  tint: category.tint, count: tools.count,
                  expanded: Binding(get: { expandedCategories.contains(category) }, set: {
                    if $0 { expandedCategories.insert(category) } else { expandedCategories.remove(category) }
                  }))
              }
            }
          }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .overlay {
          if !query.isEmpty && matches.isEmpty {
            ContentUnavailableView.search(text: query)
          }
        }
        // A bar the list scrolls beneath: the hard edge effect separates the footer
        // from rows passing behind it instead of letting them show through the text.
        .safeAreaBar(edge: .bottom) {
          HStack(spacing: 10) {
            Button { workspace.showOverview() } label: { Label(L10n.tr("All Tools"), systemImage: "square.grid.2x2") }
              .help(L10n.tr("All Tools"))
            Text(L10n.tr("Tools: \(ToolRegistry.all.count)")).font(.callout).foregroundStyle(.secondary)
            Spacer()
            SettingsLink { Label(L10n.tr("Settings"), systemImage: "gearshape") }.help(L10n.tr("Settings"))
          }
          .labelStyle(.iconOnly).buttonStyle(.borderless).controlSize(.large)
          .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .scrollEdgeEffectStyle(.hard, for: .bottom)
        .onChange(of: workspace.navigation.selectedID) { _, _ in
          guard let metadata = workspace.active?.metadata else { return }
          // A favourite that was clicked stays in place; otherwise reveal the category row.
          if sidebarTag == Self.favoritePrefix + metadata.id { return }
          expandedCategories.insert(metadata.category)
          Task { @MainActor in await Task.yield(); scroll.scrollTo(metadata.id, anchor: .center) }
        }
      }
    }
    .floatingSidebarPanel()
  }
  private func toolRow(_ item: ToolMetadata, tag: String? = nil) -> some View {
    // Names only; the description stays available as the row's tooltip.
    Label {
      Text(item.name).lineLimit(2).fixedSize(horizontal: false, vertical: true)
    } icon: {
      ToolIconTile(symbol: item.symbol, tint: item.category.tint, size: 22)
    }
    .padding(.vertical, 3)
    .tag(tag ?? item.id).id(tag ?? item.id).help(item.name + "\n" + item.summary)
    .contextMenu { Button(favoriteIDs.contains(item.id) ? L10n.tr("Remove from Favorites") : L10n.tr("Favorites")) { toggleFavorite(item.id) } }
  }
  private func open(_ id: String) { workspace.open(id) }
  private func toggleFavorite(_ id: String) { favorites = FavoriteTools.toggling(id, in: favorites) }
}

private enum ToolCatalogue {
  static let all = ToolRegistry.all.map { $0.metadata }
  static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
  static let byCategory = Dictionary(grouping: all, by: \.category)
}

/// SwiftUI's column width is only a preference. Lock the owning AppKit sidebar
/// item as well, including divider-driven collapse. Programmatic collapse via
/// columnVisibility (the toolbar button) remains available.
private struct FixedSidebarWidth: NSViewRepresentable {
  let width: CGFloat
  func makeNSView(context: Context) -> SidebarWidthView { SidebarWidthView(width: width) }
  func updateNSView(_ view: SidebarWidthView, context: Context) {
    view.width = width
    view.enforceWidth()
    // Apply after SwiftUI updates the split item during a visibility change.
    DispatchQueue.main.async { [weak view] in view?.enforceWidth() }
  }
  final class SidebarWidthView: NSView {
    var width: CGFloat
    init(width: CGFloat) {
      self.width = width
      super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { nil }
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      enforceWidth()
    }
    override func layout() {
      super.layout()
      enforceWidth()
    }
    func enforceWidth() {
      var ancestor = superview
      while let view = ancestor {
        if let split = view as? NSSplitView,
          let controller = split.delegate as? NSSplitViewController,
          let item = controller.splitViewItems.first(where: {
            $0.behavior == .sidebar && isDescendant(of: $0.viewController.view)
          }) {
          if item.minimumThickness != width { item.minimumThickness = width }
          if item.maximumThickness != width { item.maximumThickness = width }
          if item.canCollapse { item.canCollapse = false }
          if item.canCollapseFromWindowResize { item.canCollapseFromWindowResize = false }
          if item.isSpringLoaded { item.isSpringLoaded = false }
          return
        }
        ancestor = view.superview
      }
    }
  }
}

/// Favourites persist as a comma-separated list; retired JSON tool IDs map to `json`.
enum FavoriteTools {
  static let key = "favorites"
  static let defaults = "base64,json,uuid,timestamp,color,hash"
  static func ids(_ raw: String) -> [String] {
    var seen = Set<String>()
    return raw.split(separator: ",").map {
      ["json-diff", "json-path", "json-schema", "json-to-model"].contains(String($0)) ? "json" : String($0)
    }.filter { seen.insert($0).inserted }
  }
  static func toggling(_ id: String, in raw: String) -> String {
    var list = ids(raw)
    if list.contains(id) { list.removeAll { $0 == id } } else { list.append(id) }
    return list.joined(separator: ",")
  }
}

/// The native search field, placed inside the floating sidebar panel. SwiftUI's
/// sidebar `.searchable` decides its own position in the column, outside the panel.
private struct SidebarSearchField: NSViewRepresentable {
  @Binding var text: String
  let prompt: String
  let focusRequest: Int
  let submit: () -> Void
  func makeNSView(context: Context) -> NSSearchField {
    let field = NSSearchField()
    field.placeholderString = prompt
    field.controlSize = .large
    field.delegate = context.coordinator
    field.setAccessibilityLabel(prompt)
    return field
  }
  func updateNSView(_ field: NSSearchField, context: Context) {
    context.coordinator.parent = self
    if field.stringValue != text { field.stringValue = text }
    if context.coordinator.focusRequest != focusRequest {
      context.coordinator.focusRequest = focusRequest
      field.window?.makeFirstResponder(field)
    }
  }
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  @MainActor final class Coordinator: NSObject, NSSearchFieldDelegate {
    var parent: SidebarSearchField
    var focusRequest: Int
    init(_ parent: SidebarSearchField) {
      self.parent = parent
      focusRequest = parent.focusRequest
    }
    func controlTextDidChange(_ notification: Notification) {
      guard let field = notification.object as? NSSearchField else { return }
      parent.text = field.stringValue
    }
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
      guard selector == #selector(NSResponder.insertNewline(_:)) else { return false }
      parent.submit()
      return true
    }
  }
}
