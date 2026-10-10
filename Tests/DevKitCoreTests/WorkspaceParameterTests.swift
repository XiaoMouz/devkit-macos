import Testing
@testable import DevKitCore

@Suite("Visible task parameters")
struct WorkspaceParameterTests {
  @Test func allParametersStayVisibleWhenTheyFit() {
    let hash = WorkspaceParameterPlan(toolID: "hash", availableFields: ["algorithm", "uppercase"])
    let row = hash.layout(availableWidth: 400, minimumWidths: ["algorithm":140, "uppercase":70])
    #expect(row.rows == [["algorithm", "uppercase"]])
    #expect(row.overflow.isEmpty)
    let indent = WorkspaceParameterPlan(toolID: "code-format", availableFields: ["indent"])
    #expect(indent.layout(availableWidth: 400, minimumWidths: ["indent":110]).rows == [["indent"]])
  }
  @Test func usesAtMostTwoRowsAndReservesSpaceForMore() {
    let ids = ["a", "b", "c", "d", "e", "f"]
    let widths = Dictionary(uniqueKeysWithValues: ids.map { ($0, 120.0) })
    let plan = WorkspaceParameterPlan(toolID: "future", availableFields: ids)
    let two = plan.layout(availableWidth: 400, minimumWidths: widths)
    #expect(two.rows.count == 2 && two.overflow.isEmpty)
    let narrow = plan.layout(availableWidth: 250, minimumWidths: widths)
    #expect(narrow.rows.count == 2 && !narrow.overflow.isEmpty)
    for (index, row) in narrow.rows.enumerated() {
      let controls = Double(row.count) * 120 + Double(max(0, row.count - 1)) * 14
      let more = index == narrow.rows.count - 1 ? 104.0 + (row.isEmpty ? 0 : 14) : 0
      #expect(controls + more <= 250)
    }
    #expect(narrow.rows.flatMap { $0 } + narrow.overflow == ids)
  }
  @Test func wideningRestoresHiddenFieldsAndDoesNotRequireValueChanges() {
    let plan = WorkspaceParameterPlan(toolID: "hmac", availableFields: HmacTool.fields.map(\.id))
    let widths = ["algorithm":140.0, "keyFormat":146.0, "key":180.0, "output":122.0]
    let narrow = plan.layout(availableWidth: 280, minimumWidths: widths)
    #expect(!narrow.overflow.isEmpty)
    let wide = plan.layout(availableWidth: 800, minimumWidths: widths)
    #expect(wide.rows.count == 1 && wide.overflow.isEmpty)
    #expect(wide.rows.flatMap { $0 } == plan.fieldIDs)
  }
  @Test func emptyAndFutureFieldsRemainSafe() {
    let empty = WorkspaceParameterPlan(toolID: "json", availableFields: [])
    #expect(empty.layout(availableWidth: 500, minimumWidths: [:]).rows.isEmpty)
    let ids = ["algorithm", "key", "keyFormat", "output", "requiredFutureField", "key"]
    let plan = WorkspaceParameterPlan(toolID: "hmac", availableFields: ids)
    #expect(Set(plan.fieldIDs) == Set(ids) && plan.fieldIDs.count == Set(ids).count)
    let tiny = plan.layout(availableWidth: 110, minimumWidths: ["algorithm":180])
    #expect(tiny.rows == [[]] && tiny.overflow == plan.fieldIDs)
  }
}
