import SwiftUI
import UIKit

struct ScheduleWallpaperView: View {
    let lessons: [Lesson]
    let settings: RenderSettings

    var body: some View {
        ZStack {
            settings.backgroundColor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                ForEach(lessons) { lesson in
                    Text(lesson.displayLine)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(settings.textColor)
                }
            }
            .padding(48)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 1290, height: 2796)
    }
}

enum ScheduleImageRenderer {
    // ImageRenderer must run on the main actor; AppIntent.perform() can run off-main.
    @MainActor
    static func renderPNG(lessons: [Lesson], settings: RenderSettings) -> Data? {
        let view = ScheduleWallpaperView(lessons: lessons, settings: settings)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
    }
}
