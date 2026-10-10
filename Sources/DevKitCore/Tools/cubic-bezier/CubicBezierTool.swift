import Foundation

public enum CubicBezierTool: ToolModule {
  public struct Options: ToolOptions {
    public var x1: String = "0.25"
    public var y1: String = "0.1"
    public var x2: String = "0.25"
    public var y2: String = "1"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "cubic-bezier", "缓动曲线", .css, "控制点与曲线预览；横轴控制点限制在 0–1。", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("x1", "x₁", \.x1),
      .init("y1", "y₁", \.y1),
      .init("x2", "x₂", \.x2),
      .init("y2", "y₂", \.y2),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let x1 = Double(options.x1), let y1 = Double(options.y1), let x2 = Double(options.x2),
      let y2 = Double(options.y2), [x1, y1, x2, y2].allSatisfy({ $0.isFinite }),
      (0...1).contains(x1), (0...1).contains(x2), abs(y1) <= 10, abs(y2) <= 10
    else { throw ToolFailure("x 范围 0–1，y 范围 -10–10。") }
    let value = "cubic-bezier(\(x1), \(y1), \(x2), \(y2))"
    let svg =
      "<svg viewBox='-30 -30 360 360' width='360' height='360'><path d='M0 0 V300 H300' fill='none' stroke='gray'/><path d='M0 300 C\(x1 * 300) \(300 - y1 * 300),\(x2 * 300) \(300 - y2 * 300),300 0' stroke='#3478f6' fill='none' stroke-width='4'/><path d='M0 300 L\(x1 * 300) \(300 - y1 * 300) M300 0 L\(x2 * 300) \(300 - y2 * 300)' stroke='#999' fill='none'/></svg>"
    return ToolOutput(value, html: svg, note: "静态曲线：横轴时间，纵轴进度；不播放自动动画。")
  }
}
