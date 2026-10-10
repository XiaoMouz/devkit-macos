import CryptoKit
import Foundation

public enum Digest {
  public static func compute(_ data: Data, algorithm: String) -> String {
    switch algorithm {
    case "MD5": hex(Insecure.MD5.hash(data: data))
    case "SHA-1": hex(Insecure.SHA1.hash(data: data))
    case "SHA-512": hex(SHA512.hash(data: data))
    default: hex(SHA256.hash(data: data))
    }
  }
}
