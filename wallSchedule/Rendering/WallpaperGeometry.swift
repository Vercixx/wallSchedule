import UIKit

enum WallpaperGeometry {
    static var pointSize: CGSize { UIScreen.main.bounds.size }
    static var scale: CGFloat { UIScreen.main.scale }

    static var pixelSize: CGSize {
        CGSize(width: pointSize.width * scale, height: pointSize.height * scale)
    }
}
