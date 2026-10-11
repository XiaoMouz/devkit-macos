import DevKitCore
import SwiftUI

struct ResultReportView: View {
  let report: ResultReport
  private var tint: Color { report.state == "success" ? .green : ["difference", "warning"].contains(report.state) ? .orange : .red }
  private var symbol: String { report.state == "success" ? "checkmark.seal.fill" : report.state == "difference" ? "plusminus.circle.fill" : "exclamationmark.circle.fill" }
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: symbol).font(.system(size: 24)).foregroundStyle(tint)
          .frame(width: 42, height: 42).background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        VStack(alignment: .leading, spacing: 4) {
          Text(report.title).font(.headline)
          Text(report.detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
      }
      if !report.metrics.isEmpty {
        ViewThatFits(in: .horizontal) {
          HStack(spacing: 10) { metrics }
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], alignment: .leading, spacing: 8) { metrics }
        }
      }
    }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
      .background(tint.opacity(0.045)).textSelection(.enabled)
      .overlay(alignment: .bottom) { Divider() }
  }
  private var metrics: some View {
    ForEach(Array(report.metrics.enumerated()), id: \.offset) { _, metric in
      VStack(alignment: .leading, spacing: 4) {
        Text(metric.value).font(.system(.title3, design: .rounded, weight: .semibold)).monospacedDigit()
        Text(metric.label).font(.caption).foregroundStyle(.secondary)
      }.frame(minWidth: 60, maxWidth: .infinity, alignment: .leading).padding(10)
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }
  }
}
