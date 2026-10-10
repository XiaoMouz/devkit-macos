import Foundation
import zlib

public enum ZlibCodec {
  public static func process(_ data: Data, decompress: Bool, format: String) throws -> Data {
    var stream = z_stream()
    let bits: Int32 = format == "gzip" ? 31 : format == "deflate" ? -15 : 15
    let start =
      decompress
      ? inflateInit2_(&stream, bits, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
      : deflateInit2_(
        &stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, bits, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION,
        Int32(MemoryLayout<z_stream>.size))
    try require(start == Z_OK, "无法初始化压缩器。")
    defer { if decompress { inflateEnd(&stream) } else { deflateEnd(&stream) } }
    return try data.withUnsafeBytes { bytes in
      stream.next_in = UnsafeMutablePointer(mutating: bytes.bindMemory(to: UInt8.self).baseAddress)
      stream.avail_in = UInt32(data.count)
      var output = Data()
      var buffer = [UInt8](repeating: 0, count: 65536)
      var status: Int32 = Z_OK
      repeat {
        status = buffer.withUnsafeMutableBufferPointer { pointer in
          stream.next_out = pointer.baseAddress
          stream.avail_out = UInt32(pointer.count)
          return decompress ? inflate(&stream, Z_NO_FLUSH) : deflate(&stream, Z_FINISH)
        }
        try require(
          status == Z_OK || status == Z_STREAM_END || (!decompress && status == Z_BUF_ERROR),
          "压缩数据损坏、格式不符或内容不完整。")
        let produced = buffer.count - Int(stream.avail_out)
        try require(output.count + produced <= Limits.outputBytes, "解压结果超过 32 MiB 上限。")
        output.append(contentsOf: buffer.prefix(produced))
        if status != Z_STREAM_END && produced == 0 && stream.avail_in == 0 {
          throw ToolFailure("压缩数据不完整。")
        }
      } while status != Z_STREAM_END
      try require(stream.avail_in == 0, "检测到尾随数据或多段压缩流；请分别处理。")
      return output
    }
  }
}
