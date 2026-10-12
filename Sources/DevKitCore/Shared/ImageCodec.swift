import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ImageCodec {
  public static func source(_ input: ToolInput) throws -> CGImageSource {
    guard let data = input.file, let source = CGImageSourceCreateWithData(data as CFData, nil)
    else { throw ToolFailure(L10n.tr("Choose an image file supported by the system.")) }
    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
      let w = properties[kCGImagePropertyPixelWidth as String] as? Int,
      let h = properties[kCGImagePropertyPixelHeight as String] as? Int,
      w > 0, h > 0
    else { throw ToolFailure(L10n.tr("The image format is unsupported, the file is damaged, or its dimensions are invalid. Use the SVG workspace for SVG files.")) }
    try require(w <= 20000 && h <= 20000 && Int64(w) * Int64(h) <= 40_000_000,
      L10n.tr("Image exceeds 40 megapixels or 20,000 pixels on one side."))
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
    else { throw ToolFailure(L10n.tr("Could not decode the image.")) }
    return image
  }
  public static func resize(
    _ image: CGImage, width: Int, height: Int, fill: Bool = false, white: Bool = false
  ) throws -> CGImage {
    try require(
      width > 0 && height > 0 && width <= 10000 && height <= 10000 && width * height <= 20_000_000,
      L10n.tr("Output images are limited to 20 megapixels and 10,000 pixels on one side."))
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { throw ToolFailure(L10n.tr("Could not create the image buffer.")) }
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
    guard let result = context.makeImage() else { throw ToolFailure(L10n.tr("Could not generate the image.")) }
    return result
  }
  public static func encode(
    _ image: CGImage, format: String = "png", quality: Double = 0.85, name: String = "result"
  ) throws -> Artifact {
    let type: UTType = format == "jpeg" ? .jpeg : format == "heic" ? .heic : .png
    try require(
      (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains(type.identifier),
      L10n.tr("This system does not support encoding this format."))
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)
    else { throw ToolFailure(L10n.tr("Could not create the image output.")) }
    let prepared =
      format == "jpeg"
      ? try resize(image, width: image.width, height: image.height, white: true) : image
    CGImageDestinationAddImage(
      destination, prepared, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    try require(CGImageDestinationFinalize(destination), L10n.tr("Image encoding failed."))
    return Artifact(
      name + "." + (format == "jpeg" ? "jpg" : format),
      type.preferredMIMEType ?? "application/octet-stream", data as Data)
  }
}
