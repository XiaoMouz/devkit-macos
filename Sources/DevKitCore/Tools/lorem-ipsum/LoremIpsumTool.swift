import Foundation

public enum LoremIpsumTool: ToolModule {
  public struct Options: ToolOptions {
    public var language: String = "中文"
    public var count: Int = 3
    public var html: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "lorem-ipsum", "占位文本", .generators, "中英文段落，纯文本或 HTML 输出。", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("language", "语言", \.language, choices: ["中文", "English"]),
      .init("count", "段落数量", \.count, range: 1...100),
      .init("html", "HTML 段落", \.html),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require((1...100).contains(options.count), "段落数量必须为 1–100。")
    let chinese = [
      "好的工具让日常工作更加从容。清晰的结构、自然的交互和可靠的结果，帮助我们专注于真正重要的事情。",
      "每一个想法都从细小的尝试开始。在不断探索与调整中，复杂的问题逐渐变得清晰，新的可能也随之出现。",
      "文字在这里占据合适的位置，为内容留出空间。你可以使用这些段落检查排版、间距与阅读节奏。",
    ]
    let english = [
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer vitae justo at sapien posuere tincidunt. Sed tempor lectus vel neque fermentum, a commodo libero interdum.",
      "Praesent facilisis, arcu eget malesuada consequat, erat lorem dictum sem, vitae efficitur lacus velit vitae augue. Donec ut neque at felis hendrerit lacinia.",
    ]
    let source = options.language == "中文" ? chinese : english
    let paragraphs = (0..<options.count).map { source[$0 % source.count] }
    let output =
      options.html
      ? paragraphs.map { "<p>" + htmlEscape($0) + "</p>" }.joined(separator: "\n")
      : paragraphs.joined(separator: "\n\n")
    return ToolOutput(output, html: options.html ? output : nil)
  }
}
