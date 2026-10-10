import Foundation
import Testing

@testable import DevKitCore

@Suite("Window navigation regressions") struct WorkspaceNavigationTests {
  @Test func tabAndSidebarAlwaysReferToTheSameTool() {
    var model = WorkspaceNavigation()
    let base64 = model.open("base64")
    let json = model.open("json")
    #expect(model.selectedToolID == "json")
    model.select(base64.id)
    #expect(model.selectedToolID == "base64")
    model.select(json.id)
    #expect(model.selectedToolID == "json")
  }
  @Test func closingBackgroundTabKeepsSelectionAndClosingActiveChoosesNeighbor() {
    var model = WorkspaceNavigation()
    let first = model.open("base64")
    let second = model.open("json")
    let third = model.open("uuid")
    model.close(first.id)
    #expect(model.selectedID == third.id)
    model.close(third.id)
    #expect(model.selectedID == second.id)
    #expect(model.selectedToolID == "json")
    model.close(second.id)
    #expect(model.selectedToolID == nil)
  }
  @Test func duplicateSessionsStayIndependentAndSidebarReusesAnOpenTool() {
    var model = WorkspaceNavigation()
    let first = model.open("base64")
    let second = model.open("base64", newInstance: true)
    #expect(first.id != second.id)
    #expect(model.tabs.count == 2)
    #expect(model.selectedToolID == "base64")
    model.close(second.id)
    #expect(model.selectedID == first.id)
    #expect(model.open("base64").id == first.id)
  }
  @Test func overviewAndStaleSelectionDoNotDestroyTabs() {
    var model = WorkspaceNavigation()
    let tab = model.open("json")
    model.showOverview()
    #expect(model.selectedToolID == nil)
    #expect(model.tabs == [tab])
    model.select(UUID())
    #expect(model.selectedID == nil)
    model.select(tab.id)
    #expect(model.selectedToolID == "json")
  }
}
