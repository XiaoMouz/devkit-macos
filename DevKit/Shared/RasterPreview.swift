import AppKit
import ImageIO

enum RasterPreview {
  static let mimeTypes: Set<String> = [
    "image/png", "image/jpeg", "image/heic", "image/heif", "image/webp", "image/gif",
    "image/tiff", "image/bmp", "image/x-icon",
  ]
  static func image(_ data: Data) -> NSImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      let type = CGImageSourceGetType(source) as String?,
      [
        "public.png", "public.jpeg", "public.heic", "public.heif", "org.webmproject.webp",
        "com.compuserve.gif", "public.tiff", "com.microsoft.bmp", "com.microsoft.ico",
      ].contains(type),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
      let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
      let height = properties[kCGImagePropertyPixelHeight as String] as? Int,
      width > 0, height > 0, width <= 20000, height <= 20000, width * height <= 40_000_000,
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: 1600,
        ] as CFDictionary)
    else { return nil }
    return NSImage(cgImage: image, size: .zero)
  }
}
