import DevKitCore
import SwiftUI

struct MainWindow: View {
  @State private var workspace = WindowWorkspace()
  @State private var query = ""
  @State private var section = "tools"
  @State private var expandedCategories: Set<ToolCategory> = [.encoding]
  @AppStorage("showToolConfiguration") private var configurationVisible = true
  @AppStorage(FavoriteTools.key) private var favorites = FavoriteTools.defaults
  @FocusState private var searchFocused: Bool
  private var cachedTools: [ToolTab] { workspace.tabs }
  private var active: ToolTab? { workspace.active }
  private var favoriteIDs: [String] { FavoriteTools.ids(favorites) }
  private var allTools: [ToolMetadata] { ToolRegistry.all.map { $0.metadata } }
  private var favoriteTools: [ToolMetadata] {
    favoriteIDs.compactMap { id in allTools.first { $0.id == id } }
  }
  private var matches: [ToolMetadata] {
    ToolRegistry.all.map { $0.metadata }.filter {
      (section != "favorites" || favoriteIDs.contains($0.id)) &&
      (query.isEmpty || "\($0.name) \($0.id) \($0.summary) \($0.category.rawValue)".localizedStandardContains(query))
    }
  }
  @State private var columns = NavigationSplitViewVisibility.all
  // System containers own the Liquid Glass chrome: the split view floats the
  // sidebar, the unified toolbar groups its items, and the inspector slides in.
  var body: some View {
    NavigationSplitView(columnVisibility: $columns) {
      sidebar.navigationSplitViewColumnWidth(min: 210, ideal: 236, max: 320)
    } detail: {
      detail
    }
    .searchable(text: $query, placement: .sidebar, prompt: "搜索工具")
    .searchFocused($searchFocused)
    .onSubmit(of: .search) { if let first = matches.first { open(first.id) } }
    .frame(minWidth: 900, minHeight: 580)
    // The editor surface is the window's base layer, so the floating sidebar and the
    // toolbar's glass read against it instead of a lighter window background.
    .containerBackground(Color(nsColor: .textBackgroundColor), for: .window)
    .focusedSceneValue(\.workspaceActions, commandActions)
    .background(WindowCommandScope(actions: commandActions))
    .onAppear { if cachedTools.isEmpty { open("base64") } }
  }
  private var detail: some View {
    GeometryReader { bounds in
      ZStack {
        if workspace.navigation.selectedID == nil { home }
        ForEach(cachedTools) { tab in
          let shown = tab.id == workspace.navigation.selectedID
          tab.view
            .environment(\.workspaceActive, shown)
            .frame(width: bounds.size.width, height: bounds.size.height)
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(shown)
            .accessibilityHidden(!shown)
            .id(tab.id)
        }
      }.frame(width: bounds.size.width, height: bounds.size.height).clipped()
    }
    .background(Color(nsColor: .textBackgroundColor))
    .navigationTitle(active?.metadata.name ?? "工具总览")
    .navigationSubtitle(active?.metadata.summary ?? "\(ToolRegistry.all.count) 个工具")
    .toolbar { toolbarContent }
    .inspector(isPresented: inspectorVisible) {
      if let active { active.configuration.id(active.id).inspectorColumnWidth(min: 220, ideal: 260, max: 360) }
    }
  }
  private var inspectorVisible: Binding<Bool> {
    Binding(get: { configurationVisible && active?.hasConfiguration == true },
      set: { configurationVisible = $0 })
  }
  @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
    if let active {
      ToolbarItem(placement: .principal) { active.primaryControl.id(active.id) }
    }
    // Tool workspaces add their own trailing group so the primary action stays last;
    // only the WebSocket client, which has no tool workspace, is served from here.
    if let active, active.metadata.id == "websocket" {
      ToolbarItem(placement: .primaryAction) {
        Button { toggleFavorite(active.metadata.id) } label: {
          Label("收藏", systemImage: favoriteIDs.contains(active.metadata.id) ? "star.fill" : "star")
            .contentTransition(.symbolEffect(.replace))
        }.help(favoriteIDs.contains(active.metadata.id) ? "取消收藏" : "收藏当前工具")
      }
      ToolbarSpacer(.fixed, placement: .primaryAction)
      ToolbarItem(placement: .primaryAction) {
        Button { active.bridge.execute() } label: {
          Label(runTitle(active), systemImage: active.bridge.running ? "stop.fill" : "play.fill")
            .labelStyle(.titleAndIcon).padding(.horizontal, 6)
        }.buttonStyle(.glassProminent)
          .help(active.bridge.running ? "断开" : "连接 ⌘↩︎")
      }
      if active.hasConfiguration {
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItem(placement: .primaryAction) {
          Button { configurationVisible.toggle() } label: {
            Label("检查器", systemImage: "sidebar.right")
          }.help("显示或隐藏配置")
        }
      }
    }
  }
  private func runTitle(_ tab: ToolTab) -> String {
    if tab.metadata.id == "websocket" { return tab.bridge.running ? "断开" : "连接" }
    // The selected operation is already named by the principal control,
    // so the primary action stays a neutral verb instead of repeating it.
    return tab.bridge.running ? "取消" : "执行"
  }
  private var sidebar: some View {
    ScrollViewReader { scroll in
      List(selection: Binding(get: { workspace.navigation.selectedToolID },
        set: { if let id = $0 { open(id) } })) {
        if section == "favorites" || !query.isEmpty {
          ForEach(matches) { toolRow($0) }
        } else {
          ForEach(ToolCategory.allCases, id: \.self) { category in
            Section(isExpanded: Binding(get: { expandedCategories.contains(category) }, set: {
              if $0 { expandedCategories.insert(category) } else { expandedCategories.remove(category) }
            })) {
              ForEach(matches.filter { $0.category == category }) { toolRow($0) }
            } header: {
              HStack(spacing: 6) {
                Image(systemName: category.symbol).foregroundStyle(category.tint)
                Text(category.rawValue)
                Spacer(minLength: 6)
                Text("\(matches.filter { $0.category == category }.count)").monospacedDigit()
                  .foregroundStyle(.tertiary)
              }
            }
          }
        }
      }
      .listStyle(.sidebar)
      .overlay {
        if matches.isEmpty {
          ContentUnavailableView(section == "favorites" && query.isEmpty ? "还没有收藏" : "没有匹配的工具",
            systemImage: section == "favorites" && query.isEmpty ? "star" : "magnifyingglass",
            description: Text(section == "favorites" && query.isEmpty ? "在工具栏点击星标添加收藏" : "换个关键词试试"))
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) {
        // Verbatim titles: "工具" is also a menu-bar key in en.lproj, and translating
        // only one segment would mix languages inside a single control.
        Picker("显示", selection: $section) {
          Label { Text(verbatim: "工具") } icon: { Image(systemName: "square.grid.2x2") }.tag("tools")
          Label { Text(verbatim: "收藏") } icon: { Image(systemName: "star") }.tag("favorites")
        }.pickerStyle(.segmented).labelsHidden().padding(.horizontal, 12).padding(.vertical, 6)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        HStack {
          Button { workspace.showOverview() } label: { Label("工具总览", systemImage: "square.grid.2x2") }
            .labelStyle(.iconOnly).help("工具总览")
          Text("\(matches.count) 个工具").font(.caption).foregroundStyle(.secondary)
          Spacer()
          SettingsLink { Label("设置", systemImage: "gearshape") }.labelStyle(.iconOnly).help("设置")
        }.buttonStyle(.borderless).padding(.horizontal, 14).padding(.vertical, 10)
      }
      .onChange(of: workspace.navigation.selectedID) { _, _ in
        if let metadata = active?.metadata {
          expandedCategories.insert(metadata.category)
          Task { @MainActor in await Task.yield(); scroll.scrollTo(metadata.id, anchor: .center) }
        }
      }
    }
  }
  private func toolRow(_ item: ToolMetadata) -> some View {
    Label {
      VStack(alignment: .leading, spacing: 2) {
        Text(item.name).lineLimit(1)
        Text(item.summary).font(.caption).foregroundStyle(.secondary).lineLimit(1)
      }
    } icon: {
      ToolIconTile(symbol: item.symbol, tint: item.category.tint, size: 22)
    }
    .tag(item.id).id(item.id).help(item.summary)
    .contextMenu { Button(favoriteIDs.contains(item.id) ? "取消收藏" : "收藏") { toggleFavorite(item.id) } }
  }
  private var commandActions: WorkspaceActions {
    WorkspaceActions(run: { active?.bridge.execute() }, copy: { active?.bridge.copy() }, search: {
      columns = .all; section = "tools"; searchFocused = true
    }, selectPane: active?.metadata.id == "websocket"
      ? nil : { active?.bridge.selectPane($0) })
  }
  private var home: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 30) {
        VStack(alignment: .leading, spacing: 8) {
          Text("开发日常，随手可用。").font(.title.weight(.semibold))
          Text("编码、数据、文本与前端资源。在一个原生工作空间完成。").foregroundStyle(.secondary)
          HStack(spacing: 14) {
            Label("\(ToolRegistry.all.count) 个工具", systemImage: "square.grid.2x2")
            Label("\(ToolCategory.allCases.count) 个分类", systemImage: "folder")
            Label("本地处理", systemImage: "lock.shield")
          }.font(.caption).foregroundStyle(.secondary).padding(.top, 4)
        }.padding(.top, 20)
        if !favoriteTools.isEmpty {
          homeSection("收藏", symbol: "star.fill", tint: .yellow, tools: favoriteTools)
        }
        ForEach(ToolCategory.allCases, id: \.self) { category in
          homeSection(category.rawValue, symbol: category.symbol, tint: category.tint,
            tools: allTools.filter { $0.category == category })
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
            .contextMenu { Button(favoriteIDs.contains(item.id) ? "取消收藏" : "收藏") { toggleFavorite(item.id) } }
        }
      }
    }
  }
  private func open(_ id: String) {
    workspace.open(id)
  }
  private func toggleFavorite(_ id: String) { favorites = FavoriteTools.toggling(id, in: favorites) }
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
