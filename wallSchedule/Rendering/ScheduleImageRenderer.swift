import SwiftUI
import UIKit

struct ScheduleWallpaperView: View {
    let lessons: [Lesson]
    let settings: RenderSettings

    var body: some View {
        ZStack {
            background
            VStack(alignment: .leading, spacing: 16) {
                ForEach(lessons) { lesson in
                    Text(lesson.displayLine)
                        .font(lessonFont)
                        .foregroundStyle(settings.textColor)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(width: WallpaperGeometry.pointSize.width, height: WallpaperGeometry.pointSize.height)
    }

    private var lessonFont: Font {
        guard settings.fontFamily != SystemFonts.systemSentinel else {
            return .system(size: settings.textSize, weight: .semibold)
        }
        return .custom(settings.fontFamily, size: settings.textSize).weight(.semibold)
    }

    @ViewBuilder
    private var background: some View {
        if let data = BackgroundImageStore.load(), let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: WallpaperGeometry.pointSize.width, height: WallpaperGeometry.pointSize.height)
                .clipped()
                .overlay(Color.black.opacity(0.35))
        } else {
            settings.backgroundColor.ignoresSafeArea()
        }
    }
}

enum ScheduleImageRenderer {
    // ImageRenderer must run on the main actor; AppIntent.perform() can run off-main.
    @MainActor
    static func renderPNG(lessons: [Lesson], settings: RenderSettings) -> Data? {
        let view = ScheduleWallpaperView(lessons: lessons, settings: settings)
        let renderer = ImageRenderer(content: view)
        renderer.scale = WallpaperGeometry.scale
        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
    }
}
