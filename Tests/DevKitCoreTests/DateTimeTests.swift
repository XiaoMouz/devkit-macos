import Foundation
import Testing
@testable import DevKitCore

@Suite("Local date and timezone workflows") struct DateTimeTests {
  private let shanghai = TimeZone(identifier: "Asia/Shanghai")!
  private let newYork = TimeZone(identifier: "America/New_York")!

  @Test func ordinaryDatesRespectTimezoneAndRejectInvalidWallTimes() throws {
    let date = try #require(Dates.parse("2026-10-12 09:00:00.123", timeZone: shanghai))
    #expect(Dates.iso(date) == "2026-10-12T01:00:00.123Z")
    #expect(Dates.display(date, timeZone: shanghai, milliseconds: true) == "2026-10-12 09:00:00.123")
    #expect(Dates.parse("2026/10/12 09:00", timeZone: shanghai) != nil)
    for invalid in ["2026-02-29 12:00:00", "2026-13-01", "2026-10-12 25:00:00", "2026-10-12 09:00:00 junk"] {
      #expect(Dates.parse(invalid, timeZone: shanghai) == nil)
    }
    #expect(Dates.parse("2024-02-29 12:00:00", timeZone: shanghai) != nil)
    #expect(Dates.parse("2026-03-08 02:30:00", timeZone: newYork) == nil)
  }
  @Test func timestampRoundTripSupportsNegativeAndFractionalValues() async throws {
    var options = TimestampTool.Options(); options.timezone = "Asia/Shanghai"
    for value in ["0", "-1.125", "1700000000.123"] {
      let date = try TimestampTool.date(from: value, options: options)
      #expect(Dates.timestamp(date, milliseconds: false) == value)
      let result = try await TimestampTool.execute(.init(text: value), options: options)
      #expect(!result.text.contains("ISO"))
      #expect(!result.text.contains("T01:"))
      options.unit = "milliseconds"
      let fromMilliseconds = try TimestampTool.date(from: Dates.timestamp(date, milliseconds: true), options: options)
      #expect(abs(fromMilliseconds.timeIntervalSince(date)) < 0.001)
      options.unit = "seconds"
    }
    let local = try await TimestampTool.execute(.init(text: "2026-10-12 09:00:00"), options: options)
    #expect(local.rows.first?.value == "2026-10-12 09:00:00.000")
    options.unit = "milliseconds"
    #expect(TimestampTool.example(for: options).text == "1700000000000")
    await #expect(throws: ToolFailure.self) { try await TimestampTool.execute(.init(text: "1e100"), options: options) }
  }
  @Test func timezoneConversionChangesDisplayNotTheInstant() async throws {
    var options = DateTimeTool.Options()
    options.sourceZone = "Asia/Shanghai"; options.zone = "America/New_York"
    let result = try await DateTimeTool.execute(.init(text: "2026-10-12 09:00:00"), options: options)
    #expect(result.text == "2026-10-11 21:00:00.000")
    #expect(result.rows.first?.value == "2026-10-12 09:00:00.000")
    #expect(result.rows.last?.label.contains("UTC−04:00") == true)
  }
  @Test func calendarDaysAndElapsedDaysHandleDSTSeparately() async throws {
    var options = DateTimeTool.Options(); options.operation = "add-days"; options.zone = "America/New_York"
    let spring = try await DateTimeTool.execute(.init(text: "2026-03-07 12:00:00"), options: options)
    #expect(spring.text == "2026-03-08 12:00:00.000")
    options.operation = "difference"; options.other = spring.text
    let elapsed = try await DateTimeTool.execute(.init(text: "2026-03-07 12:00:00"), options: options)
    #expect(elapsed.rows.first { $0.label == "小时" }?.value == "23.000000")
    options.other = "2026-10-31 12:00:00"
    let negative = try await DateTimeTool.execute(.init(text: "2026-11-01 12:00:00"), options: options)
    #expect(negative.rows.first { $0.label == "小时" }?.value == "-25.000000")
  }
  @Test func sourceBaseExamplesMatchTheChosenBase() async throws {
    var options = NumberBaseTool.Options(); options.to = "10"
    for base in ["2", "8", "10", "16"] {
      options.from = base
      #expect(try await NumberBaseTool.execute(NumberBaseTool.example(for: options), options: options).text == "255")
    }
    #expect(ToolPresentation(id: "jwt", style: .text, values: ["verify": "true"]).action == "验证签名")
    #expect(ToolPresentation(id: "file-checksum", style: .file, values: ["expected": "abc"]).action == "校验文件")
  }

  @Test func cronDisplaysSelectedTimezoneAndAdvancesAcrossDST() async throws {
    var options = CronTool.Options(); options.timezone = "Asia/Shanghai"; options.start = "2026-10-12 09:00:00"; options.count = 2
    let local = try await CronTool.execute(.init(text: "*/15 * * * *"), options: options)
    #expect(local.rows.first?.value == "2026-10-12 09:15:00 · UTC+08:00")
    options.timezone = "America/New_York"; options.start = "2026-03-08 01:45:00"
    let dst = try await CronTool.execute(.init(text: "0 * * * *"), options: options)
    #expect(dst.rows.first?.value == "2026-03-08 03:00:00 · UTC−04:00")
    await #expect(throws: ToolFailure.self) { try await CronTool.execute(.init(text: "99 * * * *"), options: options) }
    options.timezone = "invalid-zone"
    await #expect(throws: ToolFailure.self) { try await CronTool.execute(.init(text: "* * * * *"), options: options) }
  }
}
