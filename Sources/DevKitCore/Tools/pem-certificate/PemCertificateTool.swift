import Foundation
import Security

public enum PemCertificateTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "pem-certificate", "PEM 与证书", .security, "本地 X.509 证书主题、有效期与 SHA-256 指纹。", sample: "",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let data: Data
    if let file = input.file {
      data = file
    } else {
      try require(
        input.text.contains("-----BEGIN CERTIFICATE-----"), "请输入 PEM X.509 CERTIFICATE，或选择 DER 证书。")
      let payload =
        input.text.components(separatedBy: "-----BEGIN CERTIFICATE-----").dropFirst().first?
        .components(separatedBy: "-----END CERTIFICATE-----").first ?? ""
      data = try Base64Codec.decode(payload)
    }
    guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
      throw ToolFailure("无法解析 X.509 证书。")
    }
    let subject = SecCertificateCopySubjectSummary(certificate) as String? ?? "未知"
    var rows = [
      ResultRow("主题", subject), ResultRow("SHA-256", Digest.compute(data, algorithm: "SHA-256")),
    ]
    if let values = SecCertificateCopyValues(
      certificate,
      [kSecOIDX509V1ValidityNotBefore, kSecOIDX509V1ValidityNotAfter, kSecOIDX509V1IssuerName]
        as CFArray, nil) as? [String: Any]
    {
      for (key, label) in [
        (kSecOIDX509V1ValidityNotBefore as String, "生效时间"),
        (kSecOIDX509V1ValidityNotAfter as String, "到期时间"),
      ] {
        if let entry = values[key] as? [String: Any],
          let number = entry[kSecPropertyKeyValue as String] as? NSNumber
        {
          rows.append(
            ResultRow(label, Dates.display(Date(timeIntervalSinceReferenceDate: number.doubleValue))))
        }
      }
    }
    return ToolOutput(
      rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows,
      note: "时间按当前时区 \(TimeZone.current.identifier) 显示。仅解析首张证书；未进行信任链或吊销状态验证。")
  }
}
