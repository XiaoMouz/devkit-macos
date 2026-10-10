import DevKitCore
import SwiftUI

struct MainWindow: View {
  @State private var workspace = WindowWorkspace()
  @State private var query = ""
  @State private var sidebarVisible = true
  @State private var section = "tools"
  @State private var expandedCategories: Set<ToolCategory> = [.encoding]
  @AppStorage("showToolConfiguration") private var configurationVisible = true
  @AppStorage("favorites") private var favorites = "base64,json,uuid,timestamp,color,hash"
  @FocusState private var searchFocused: Bool
  private var cachedTools: [ToolTab] { workspace.tabs }
  private var active: ToolTab? { workspace.active }
  private var favoriteIDs: [String] { Array(Set(favorites.split(separator: ",").map { ["json-diff", "json-path", "json-schema", "json-to-model"].contains(String($0)) ? "json" : String($0) })) }
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
  var body: some View {
    VStack(spacing: 0) {
      header
      HStack(spacing: 0) {
        if sidebarVisible {
          sidebar.frame(width: WorkspaceChromeMetrics.sidebarWidth)
            .overlay(alignment: .trailing) { WorkspaceBoundary() }
        }
        HStack(spacing: 0) {
          GeometryReader { bounds in
            ZStack {
              if workspace.navigation.selectedID == nil { home }
              ForEach(cachedTools) { tab in
                tab.view
                  .frame(width: bounds.size.width, height: bounds.size.height)
                  .opacity(tab.id == workspace.navigation.selectedID ? 1 : 0)
                  .allowsHitTesting(tab.id == workspace.navigation.selectedID)
                  .accessibilityHidden(tab.id != workspace.navigation.selectedID)
                  .id(tab.id)
              }
            }.frame(width: bounds.size.width, height: bounds.size.height).clipped()
          }
          if configurationVisible, let active, active.hasConfiguration {
            Divider()
            active.configuration.id(active.id).frame(width: 240)
              .background(Color(nsColor: .textBackgroundColor)).accessibilityLabel("工具配置")
          }
        }.background(Color(nsColor: .textBackgroundColor))
          .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12))
      }
    }
    .frame(minWidth: 900, minHeight: 580)
    .ignoresSafeArea(.container, edges: .top)
    .background { WorkspaceGlass().ignoresSafeArea() }
    .background(WorkspaceWindowChrome())
    .focusedSceneValue(\.workspaceActions, commandActions)
    .background(WindowCommandScope(actions: commandActions))
    .onAppear { if cachedTools.isEmpty { open("base64") } }
  }
  private var header: some View {
    HStack(spacing: 0) {
      WorkspaceSidebarControl(sidebarVisible: sidebarVisible) { sidebarVisible.toggle() }
        .frame(width: sidebarVisible ? WorkspaceChromeMetrics.sidebarWidth : 128)
        .overlay(alignment: .trailing) { if sidebarVisible { WorkspaceBoundary() } }
      HStack(spacing: 12) {
        if let active {
          ToolIconTile(symbol: active.metadata.symbol, tint: active.metadata.category.tint, size: 22)
          Text(active.metadata.name).font(.system(size: 15, weight: .semibold))
            .lineLimit(1).help(active.metadata.summary).layoutPriority(1)
          Button { toggleFavorite(active.metadata.id) } label: {
            Image(systemName: favoriteIDs.contains(active.metadata.id) ? "star.fill" : "star")
              .font(.system(size: 12))
              .foregroundStyle(favoriteIDs.contains(active.metadata.id) ? AnyShapeStyle(Color.yellow) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
              .contentTransition(.symbolEffect(.replace))
          }.buttonStyle(.glass).controlSize(.small).help("收藏当前工具").accessibilityLabel("收藏当前工具")
          active.primaryControl.id(active.id)
          Spacer(minLength: 10)
          Button { active.bridge.execute() } label: {
            Label(runTitle(active), systemImage: active.bridge.running ? "stop.fill" : "play")
              .font(.system(size: 12, weight: .medium))
          }.buttonStyle(.glass).help("执行 ⌘↩︎").accessibilityLabel(runTitle(active))
          if active.hasConfiguration {
            Button { configurationVisible.toggle() } label: {
              Label("配置", systemImage: "sidebar.right").font(.system(size: 12))
            }.buttonStyle(.glass).tint(configurationVisible ? Color.primary.opacity(0.12) : nil)
              .accessibilityValue(configurationVisible ? "已展开" : "已收起").help("收放工具配置").accessibilityLabel("收放工具配置")
          }
        } else {
          Text("工具总览").font(.system(size: 15, weight: .semibold))
          Spacer()
        }
      }.padding(.horizontal, 16)
    }.frame(height: WorkspaceChromeMetrics.headerHeight)
  }
  private func runTitle(_ tab: ToolTab) -> String {
    if tab.metadata.id == "websocket" { return tab.bridge.running ? "断开" : "连接" }
    return tab.bridge.running ? "取消" : tab.bridge.actionTitle
  }
  private var sidebar: some View {
    VStack(spacing: 0) {
      HStack(spacing: 5) {
        WorkspaceSegments(items: [("工具", "tools"), ("收藏", "favorites")], selection: $section,
          symbols: ["tools": "square.grid.2x2", "favorites": "star"])
        Spacer()
      }.padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 7)
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
        TextField("搜索工具", text: $query).textFieldStyle(.plain).focused($searchFocused)
          .onSubmit { if let first = matches.first { open(first.id) } }
        if !query.isEmpty {
          Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
            .buttonStyle(.plain).foregroundStyle(.tertiary).help("清除搜索")
        }
      }.font(.system(size: 12)).padding(.horizontal, 10).frame(height: 28)
        .background(.primary.opacity(searchFocused ? 0.08 : 0.05),
          in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 12).padding(.vertical, 4)
      ScrollViewReader { scroll in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            if section == "favorites" || !query.isEmpty {
              ForEach(matches) { toolRow($0) }
            } else {
              ForEach(ToolCategory.allCases, id: \.self) { category in
                DisclosureGroup(isExpanded: Binding(get: { expandedCategories.contains(category) }, set: {
                  if $0 { expandedCategories.insert(category) } else { expandedCategories.remove(category) }
                })) {
                  ForEach(matches.filter { $0.category == category }) { toolRow($0) }
                } label: {
                  HStack(spacing: 6) {
                    Image(systemName: category.symbol).font(.system(size: 10, weight: .medium))
                      .foregroundStyle(category.tint).frame(width: 14)
                    Text(category.rawValue).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    Spacer(minLength: 6)
                    CountBadge(count: matches.filter { $0.category == category }.count)
                  }.contentShape(Rectangle())
                }.padding(.vertical, 5)
              }
            }
            if matches.isEmpty {
              VStack(spacing: 8) {
                Image(systemName: section == "favorites" && query.isEmpty ? "star" : "magnifyingglass")
                  .font(.system(size: 20)).foregroundStyle(.tertiary)
                Text(section == "favorites" && query.isEmpty ? "点击工具标题旁的星标添加收藏" : "没有匹配的工具")
                  .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
              }.frame(maxWidth: .infinity).padding(.vertical, 24).padding(.horizontal, 10)
            }
          }.padding(.horizontal, 10).padding(.vertical, 8)
        }
        .onChange(of: workspace.navigation.selectedID) { _, _ in
          if let metadata = active?.metadata {
            expandedCategories.insert(metadata.category)
            Task { @MainActor in await Task.yield(); scroll.scrollTo(metadata.id, anchor: .center) }
          }
        }
      }
      HStack {
        Button { workspace.showOverview() } label: { Image(systemName: "square.grid.2x2") }
          .buttonStyle(.glass).controlSize(.small).help("工具总览")
        Text("\(matches.count) 个工具").font(.system(size: 11)).foregroundStyle(.secondary)
        Spacer()
        SettingsLink { Image(systemName: "gearshape") }.buttonStyle(.glass).controlSize(.small).help("设置")
      }.foregroundStyle(.secondary).padding(.horizontal, 16).padding(.vertical, 12)
    }
  }
  private func toolRow(_ item: ToolMetadata) -> some View {
    let selected = workspace.navigation.selectedToolID == item.id
    return Button { open(item.id) } label: {
      HStack(spacing: 10) {
        ToolIconTile(symbol: item.symbol, tint: item.category.tint, emphasized: selected)
        VStack(alignment: .leading, spacing: 3) {
          Text(item.name).font(.system(size: 12, weight: selected ? .semibold : .medium)).lineLimit(1)
          Text(item.summary).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
        }
        Spacer(minLength: 0)
      }.padding(.horizontal, 8).padding(.vertical, 7).frame(maxWidth: .infinity, alignment: .leading)
    }.buttonStyle(HoverSurfaceButtonStyle(selected: selected)).id(item.id).help(item.summary)
      .accessibilityAddTraits(selected ? .isSelected : [])
      .contextMenu { Button(favoriteIDs.contains(item.id) ? "取消收藏" : "收藏") { toggleFavorite(item.id) } }
  }
  private var commandActions: WorkspaceActions {
    WorkspaceActions(run: { active?.bridge.execute() }, copy: { active?.bridge.copy() }, search: {
      sidebarVisible = true; section = "tools"; searchFocused = true
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
  private func toggleFavorite(_ id: String) {
    var ids = favoriteIDs
    if ids.contains(id) { ids.removeAll { $0 == id } } else { ids.append(id) }
    favorites = ids.joined(separator: ",")
  }
}
