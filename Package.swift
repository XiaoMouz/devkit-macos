// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "DevKit",
  platforms: [.macOS("26.0")],
  products: [
    .library(name: "DevKitCore", targets: ["DevKitCore"]),
    .executable(name: "DevKitWorker", targets: ["DevKitWorker"]),
  ],
  targets: [
    .target(
      name: "DevKitCore",
      exclude: [
        "Tools/code-format/Engine.mjs",
        "Tools/code-minify/Engine.mjs",
        "Tools/cron/Engine.mjs",
        "Tools/curl-convert/Engine.mjs",
        "Tools/json-diff/Engine.mjs",
        "Tools/json-path/Engine.mjs",
        "Tools/json-schema/Engine.mjs",
        "Tools/json-to-model/Engine.mjs",
        "Tools/json/Engine.mjs",
        "Tools/markdown/Engine.mjs",
        "Tools/mock-data/Engine.mjs",
        "Tools/number-base/Engine.mjs",
        "Tools/regex/Engine.mjs",
        "Tools/svg/Engine.mjs",
        "Tools/text-replace/Engine.mjs",
      ], resources: [.copy("Resources")]),
    .executableTarget(name: "DevKitWorker", dependencies: ["DevKitCore"]),
    .target(
      name: "DevKitSession", dependencies: ["DevKitCore"], path: "DevKit/Shared",
      exclude: [
        "CodeEditor.swift", "SafePreview.swift", "ToolOptionsForm.swift", "ToolWorkspace.swift",
        "WorkspaceColumns.swift", "WorkspaceStyle.swift", "ToolChrome.swift", "ScenarioInput.swift", "ScenarioControls.swift", "ResultReportView.swift", "WorkspaceParameters.swift",
      ],
      sources: [
        "ToolSession.swift", "WorkspaceBridge.swift", "WorkerRunner.swift", "Clipboard.swift",
        "RasterPreview.swift",
      ]),
    .testTarget(name: "DevKitSessionTests", dependencies: ["DevKitSession", "DevKitCore"]),

    .testTarget(
      name: "DevKitCoreTests", dependencies: ["DevKitCore"], resources: [.copy("Fixtures")]),
  ]
)
