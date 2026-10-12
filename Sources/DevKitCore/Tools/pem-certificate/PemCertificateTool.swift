import Foundation
import Security

public enum PemCertificateTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "pem-certificate", "PEM and Certificates", .security, "Inspect local X.509 certificate subjects, validity, and SHA-256 fingerprints.", sample: "",
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
        input.text.contains("-----BEGIN CERTIFICATE-----"), L10n.tr("Enter a PEM X.509 CERTIFICATE or choose a DER certificate."))
      let payload =
        input.text.components(separatedBy: "-----BEGIN CERTIFICATE-----").dropFirst().first?
        .components(separatedBy: "-----END CERTIFICATE-----").first ?? ""
      data = try Base64Codec.decode(payload)
    }
    guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
      throw ToolFailure(L10n.tr("Could not parse the X.509 certificate."))
    }
    let subject = SecCertificateCopySubjectSummary(certificate) as String? ?? L10n.tr("Unknown")
    var rows = [
      ResultRow(L10n.tr("Certificate Subject"), subject), ResultRow("SHA-256", Digest.compute(data, algorithm: "SHA-256")),
    ]
    if let values = SecCertificateCopyValues(
      certificate,
      [kSecOIDX509V1ValidityNotBefore, kSecOIDX509V1ValidityNotAfter, kSecOIDX509V1IssuerName]
        as CFArray, nil) as? [String: Any]
    {
      for (key, label) in [
        (kSecOIDX509V1ValidityNotBefore as String, L10n.tr("Valid From")),
        (kSecOIDX509V1ValidityNotAfter as String, L10n.tr("Expires At")),
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
      note: L10n.tr("Times use the current time zone, \(TimeZone.current.identifier). Only the first certificate is parsed. The trust chain and revocation status are not verified."))
  }
}
