import SwiftUI
import AVKit

struct TokenGuideView: View {
    @State private var player = Bundle.main.url(forResource: "proxygen-guide", withExtension: "mov").map(AVPlayer.init(url:))

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
            } else {
                VStack(spacing: 12) {
                    Text("Видео-инструкция не найдена")
                        .font(.headline)
                    Text("Положите proxygen-guide.mov в wallSchedule/Resources — текст озвучки см. в README.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
}
