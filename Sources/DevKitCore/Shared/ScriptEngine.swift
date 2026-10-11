import Foundation
import JavaScriptCore

public enum ScriptEngine {
  /// Runs only our bundled parsers. User text is passed as data; it is never evaluated.
  /// The containing worker is terminated by its parent on cancellation or deadline.
  public static func execute<O: Encodable>(_ id: String, input: ToolInput, options: O) throws
    -> ToolOutput
  {
    guard let context = JSContext(),
      let url = Bundle.module.url(
        forResource: "engines", withExtension: "js", subdirectory: "Resources")
    else {
      throw ToolFailure("本地解析器资源缺失，请重新构建应用。", code: "resource")
    }
    var exception: String?
    context.exceptionHandler = { _, value in exception = value?.toString() }
    context.evaluateScript(try String(contentsOf: url, encoding: .utf8))
    if let exception { throw ToolFailure("解析器加载失败：\(exception)", code: "resource") }
    let encoder = JSONEncoder()
    context.setObject(id, forKeyedSubscript: "__id" as NSString)
    context.setObject(try utf8(encoder.encode(input)), forKeyedSubscript: "__input" as NSString)
    context.setObject(try utf8(encoder.encode(options)), forKeyedSubscript: "__options" as NSString)
    var response: String?
    let callback: @convention(block) (String) -> Void = { response = $0 }
    context.setObject(callback, forKeyedSubscript: "__complete" as NSString)
    context.evaluateScript(
      "devkitExecute(__id, JSON.parse(__input), JSON.parse(__options)).then(__complete)")
    let deadline = Date().addingTimeInterval(12)
    while response == nil && exception == nil && Date() < deadline {
      RunLoop.current.run(until: Date().addingTimeInterval(0.001))
    }
    if let exception { throw ToolFailure(exception) }
    guard let response else { throw ToolFailure("解析超时。请减少输入。", code: "timeout") }
    let result = try JSONDecoder().decode(WorkerResponse.self, from: Data(response.utf8))
    if let error = result.error {
      if ["code-format", "code-minify", "svg", "text-replace"].contains(id),
        error.message.range(of: "[一-龥]", options: .regularExpression) == nil {
        throw ToolFailure("输入语法无效，请根据下面的位置或说明修正。\n" + error.message, code: error.code)
      }
      throw error
    }
    guard let output = result.output else { throw ToolFailure("解析器未返回结果。", code: "internal") }
    return output
  }
}
