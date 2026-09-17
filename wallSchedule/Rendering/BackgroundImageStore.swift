import UIKit

// Downscales/recompresses on save — PhotosPicker originals can be many MB, wallpaper canvas isn't.
enum BackgroundImageStore {
    private static var maxDimension: CGFloat {
        max(WallpaperGeometry.pixelSize.width, WallpaperGeometry.pixelSize.height)
    }

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("background.jpg")
    }

    static func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    static func save(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: targetSize)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { return }

        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? jpeg.write(to: fileURL, options: .atomic)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
