import AppKit
import ImageIO

enum RasterPreview {
  static let mimeTypes: Set<String> = [
    "image/png", "image/jpeg", "image/heic", "image/heif", "image/webp", "image/gif",
    "image/tiff", "image/bmp", "image/x-icon",
  ]
  static func image(_ data: Data) -> NSImage? {
    thumbnail(data).map { NSImage(cgImage: $0, size: .zero) }
  }
  static func thumbnail(_ data: Data) -> CGImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
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
    return image
  }
}

/// Serialize decoding so rapid tool/image switches cannot start an unbounded
/// number of full raster decodes. Cancelled queued views are skipped.
actor RasterThumbnailLoader {
  static let shared = RasterThumbnailLoader()
  func thumbnail(_ data: Data) -> CGImage? {
    guard !Task.isCancelled else { return nil }
    return autoreleasepool { RasterPreview.thumbnail(data) }
  }
}
