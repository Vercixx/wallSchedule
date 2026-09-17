import SwiftUI
import AVKit

struct TokenGuideView: View {
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "proxygen-guide", withExtension: "mp4") {
                VideoPlayer(player: AVPlayer(url: url))
            } else {
                VStack(spacing: 12) {
                    Text("Видео-инструкция не найдена")
                        .font(.headline)
                    Text("Положите proxygen-guide.mp4 в wallSchedule/Resources — текст озвучки см. в README.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
}
