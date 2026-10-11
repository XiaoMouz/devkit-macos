import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ImageCodec {
  public static func source(_ input: ToolInput) throws -> CGImageSource {
    guard let data = input.file, let source = CGImageSourceCreateWithData(data as CFData, nil)
    else { throw ToolFailure("请选择系统支持的图片文件。") }
    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
      let w = properties[kCGImagePropertyPixelWidth as String] as? Int,
      let h = properties[kCGImagePropertyPixelHeight as String] as? Int,
      w > 0, h > 0
    else { throw ToolFailure("图片格式不受支持、文件损坏或缺少有效尺寸；SVG 请使用 SVG 工作台。") }
    try require(w <= 20000 && h <= 20000 && Int64(w) * Int64(h) <= 40_000_000,
      "图片超过 4000 万像素或单边超过 20000 像素。")
    return source
  }
  public static func decode(_ input: ToolInput) throws -> CGImage {
    let source = try source(input)
    guard
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: 20000,
        ] as CFDictionary)
    else { throw ToolFailure("无法解码图片。") }
    return image
  }
  public static func resize(
    _ image: CGImage, width: Int, height: Int, fill: Bool = false, white: Bool = false
  ) throws -> CGImage {
    try require(
      width > 0 && height > 0 && width <= 10000 && height <= 10000 && width * height <= 20_000_000,
      "输出图片限制为 2000 万像素，单边不超过 10000。")
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { throw ToolFailure("无法创建图片缓冲区。") }
    if white {
      context.setFillColor(CGColor(gray: 1, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    let ratios = [Double(width) / Double(image.width), Double(height) / Double(image.height)]
    let scale = fill ? ratios.max()! : ratios.min()!
    let w = Double(image.width) * scale
    let h = Double(image.height) * scale
    context.interpolationQuality = .high
    context.draw(
      image,
      in: CGRect(x: (Double(width) - w) / 2, y: (Double(height) - h) / 2, width: w, height: h))
    guard let result = context.makeImage() else { throw ToolFailure("无法生成图片。") }
    return result
  }
  public static func encode(
    _ image: CGImage, format: String = "png", quality: Double = 0.85, name: String = "result"
  ) throws -> Artifact {
    let type: UTType = format == "jpeg" ? .jpeg : format == "heic" ? .heic : .png
    try require(
      (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains(type.identifier),
      "当前系统不支持此格式编码。")
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)
    else { throw ToolFailure("无法创建图片输出。") }
    let prepared =
      format == "jpeg"
      ? try resize(image, width: image.width, height: image.height, white: true) : image
    CGImageDestinationAddImage(
      destination, prepared, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    try require(CGImageDestinationFinalize(destination), "图片编码失败。")
    return Artifact(
      name + "." + (format == "jpeg" ? "jpg" : format),
      type.preferredMIMEType ?? "application/octet-stream", data as Data)
  }
}
