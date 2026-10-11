import Foundation

public enum AutomationInstallation {
  public static var loginShell: String {
    guard let shell = getpwuid(getuid())?.pointee.pw_shell else { return "/bin/zsh" }
    return String(cString: shell)
  }

  /// Add an idempotent PATH block while preserving existing startup configuration.
  /// Both login and interactive sessions must discover the same command.
  @discardableResult public static func configureCommandPath(home: URL, shell: String,
    environment: [String: String] = ProcessInfo.processInfo.environment) throws -> [URL] {
    let manager = FileManager.default
    let files: [URL]
    switch URL(fileURLWithPath: shell).lastPathComponent {
    case "zsh":
      let root = environment["ZDOTDIR"].flatMap { $0.hasPrefix("/") ? URL(fileURLWithPath: $0) : nil } ?? home
      files = [root.appendingPathComponent(".zprofile"), root.appendingPathComponent(".zshrc")]
    case "bash":
      let login = [".bash_profile", ".bash_login", ".profile"].map { home.appendingPathComponent($0) }
        .first { manager.fileExists(atPath: $0.path) } ?? home.appendingPathComponent(".bash_profile")
      files = [login, home.appendingPathComponent(".bashrc")]
    default:
      throw ToolFailure("CLI 已安装；暂不支持自动配置此 Shell，请将 ~/.local/bin 加入 PATH。", code: "install-path")
    }
    let block = """
      # >>> DevKit CLI >>>
      case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
      esac
      # <<< DevKit CLI <<<
      """
    for file in files {
      let resolved = file.resolvingSymlinksInPath()
      if manager.fileExists(atPath: resolved.path) {
        let content = try String(contentsOf: resolved, encoding: .utf8)
        if content.contains(block) { continue }
        let handle = try FileHandle(forWritingTo: resolved)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(("\n" + block + "\n").utf8))
      } else {
        try manager.createDirectory(at: resolved.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data((block + "\n").utf8).write(to: resolved, options: .withoutOverwriting)
      }
    }
    return files
  }

  public static var skillURL: URL? {
    Bundle.module.url(forResource: "devkit", withExtension: nil, subdirectory: "Resources/Skills")
  }

  /// Only a link recorded by this installation can be moved to a new application location.
  /// Existing user files and unrelated symlinks are never replaced.
  public static func installLink(source: URL, destination: URL, previousSource: String? = nil) throws {
    let manager = FileManager.default
    guard manager.fileExists(atPath: source.path) else {
      throw ToolFailure("应用资源缺失，请重新构建 DevKit。", code: "resource")
    }
    let existing = try? manager.destinationOfSymbolicLink(atPath: destination.path)
    if existing == source.path { return }
    if let existing {
      guard existing == previousSource else { throw conflict(destination) }
    } else if manager.fileExists(atPath: destination.path) { throw conflict(destination) }
    try manager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    if existing != nil {
      // Prepare the replacement before removing the old managed link; rename is atomic.
      let temporary = destination.deletingLastPathComponent().appendingPathComponent(".devkit-\(UUID().uuidString)")
      try manager.createSymbolicLink(at: temporary, withDestinationURL: source)
      defer { try? manager.removeItem(at: temporary) }
      guard rename(temporary.path, destination.path) == 0 else {
        throw ToolFailure("无法更新安装链接。", code: "install")
      }
    } else {
      try manager.createSymbolicLink(at: destination, withDestinationURL: source)
    }
  }

  public static func isInstalled(source: URL, destination: URL) -> Bool {
    (try? FileManager.default.destinationOfSymbolicLink(atPath: destination.path)) == source.path
      && FileManager.default.fileExists(atPath: source.path)
  }

  private static func conflict(_ destination: URL) -> ToolFailure {
    ToolFailure("\(destination.path) 已存在其他文件或链接，请先手动调整位置。", code: "install-conflict")
  }
}
