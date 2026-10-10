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
  private var favoriteIDs: [String] { favorites.split(separator: ",").map(String.init) }
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
      HStack {
        Spacer().frame(width: 76)
        Button { sidebarVisible.toggle() } label: { Image(systemName: "sidebar.left") }
          .buttonStyle(.plain).help("收放工具列表").accessibilityLabel("收放工具列表")
        Spacer(minLength: 0)
      }.padding(.leading, 12).frame(width: sidebarVisible ? WorkspaceChromeMetrics.sidebarWidth : 128)
      HStack(spacing: 12) {
        if let active {
          Text(active.metadata.name).font(.system(size: 15, weight: .semibold))
            .lineLimit(1).help(active.metadata.summary).layoutPriority(1)
          Button { toggleFavorite(active.metadata.id) } label: {
            Image(systemName: favoriteIDs.contains(active.metadata.id) ? "star.fill" : "star")
              .font(.system(size: 12)).foregroundStyle(.secondary)
          }.buttonStyle(.plain).help("收藏当前工具").accessibilityLabel("收藏当前工具")
          active.primaryControl.id(active.id)
          Spacer(minLength: 10)
          Button { active.bridge.execute() } label: {
            Label(runTitle(active), systemImage: active.bridge.running ? "stop.fill" : "play")
              .font(.system(size: 12, weight: .medium))
          }.buttonStyle(.glass).help("执行 ⌘↩︎").accessibilityLabel(runTitle(active))
          if active.hasConfiguration {
            Button { configurationVisible.toggle() } label: {
              Label("配置", systemImage: "sidebar.right").font(.system(size: 12))
                .padding(.horizontal, 8).padding(.vertical, 7)
                .background(configurationVisible ? Color.primary.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 7))
            }.buttonStyle(.plain).help("收放工具配置").accessibilityLabel("收放工具配置")
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
    return tab.bridge.running ? "取消" : tab.metadata.network ? "发送请求" : tab.metadata.inputStyle == .generator ? "生成" : "转换"
  }
  private var sidebar: some View {
    VStack(spacing: 0) {
      HStack(spacing: 5) {
        sidebarMode("工具", symbol: "square.grid.2x2", value: "tools")
        sidebarMode("收藏", symbol: "star", value: "favorites")
        Spacer()
      }.padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 7)
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
        TextField("搜索工具", text: $query).textFieldStyle(.plain).focused($searchFocused)
          .onSubmit { if let first = matches.first { open(first.id) } }
        if !query.isEmpty {
          Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
            .buttonStyle(.plain).help("清除搜索")
        }
      }.font(.system(size: 12)).padding(.horizontal, 16).padding(.vertical, 8)
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
                  Text(category.rawValue).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }.padding(.vertical, 5)
              }
            }
            if matches.isEmpty {
              Text(section == "favorites" && query.isEmpty ? "点击工具标题旁的星标添加收藏" : "没有匹配的工具")
                .font(.caption).foregroundStyle(.secondary).padding(14)
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
          .buttonStyle(.plain).help("工具总览")
        Text("\(matches.count) 个工具").font(.system(size: 11)).foregroundStyle(.secondary)
        Spacer()
        SettingsLink { Image(systemName: "gearshape") }.buttonStyle(.plain).help("设置")
      }.foregroundStyle(.secondary).padding(.horizontal, 16).padding(.vertical, 12)
    }
  }
  private func sidebarMode(_ name: String, symbol: String, value: String) -> some View {
    Button { section = value } label: {
      Label(name, systemImage: symbol).font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(section == value ? Color.primary.opacity(0.08) : .clear, in: Capsule())
    }.buttonStyle(.plain).foregroundStyle(section == value ? .primary : .secondary)
      .accessibilityValue(section == value ? "已选中" : "")
  }
  private func toolRow(_ item: ToolMetadata) -> some View {
    Button { open(item.id) } label: {
      HStack(spacing: 10) {
        Image(systemName: item.symbol).font(.system(size: 13)).frame(width: 24, height: 24)
          .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
        VStack(alignment: .leading, spacing: 3) {
          Text(item.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
          Text(item.summary).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
        }
        Spacer(minLength: 0)
      }.padding(.horizontal, 8).padding(.vertical, 7).frame(maxWidth: .infinity, alignment: .leading)
        .background(workspace.navigation.selectedToolID == item.id ? Color.primary.opacity(0.09) : .clear,
          in: RoundedRectangle(cornerRadius: 8)).contentShape(Rectangle())
    }.buttonStyle(.plain).id(item.id).help(item.summary)
      .contextMenu { Button(favoriteIDs.contains(item.id) ? "取消收藏" : "收藏") { toggleFavorite(item.id) } }
  }
  private var commandActions: WorkspaceActions {
    WorkspaceActions(run: { active?.bridge.execute() }, copy: { active?.bridge.copy() }, search: {
      sidebarVisible = true; section = "tools"; searchFocused = true
    }, selectPane: active?.metadata.inputStyle == .generator || active?.metadata.id == "websocket"
      ? nil : { active?.bridge.selectPane($0) })
  }
  private var home: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        VStack(alignment: .leading, spacing: 7) {
          Text("开发日常，随手可用。").font(.largeTitle.weight(.semibold))
          Text("编码、数据、文本与前端资源。在一个原生工作空间完成。").foregroundStyle(.secondary)
        }.padding(.top, 20)
        ForEach(ToolCategory.allCases, id: \.self) { category in
          VStack(alignment: .leading, spacing: 12) {
            Label(category.rawValue, systemImage: category.symbol).font(.headline)
            LazyVGrid(
              columns: [GridItem(.adaptive(minimum: 210), alignment: .leading)],
              alignment: .leading, spacing: 10
            ) {
              ForEach(ToolRegistry.all.map { $0.metadata }.filter { $0.category == category }) {
                item in
                Button {
                  open(item.id)
                } label: {
                  HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.symbol).font(.title3).foregroundStyle(.tint).frame(
                      width: 24)
                    VStack(alignment: .leading, spacing: 5) {
                      Text(item.name).foregroundStyle(.primary)
                      Text(item.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                  }.padding(14).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain)
              }
            }
          }
        }
      }.padding(30)
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
