import SwiftUI

struct LoginView: View {
    @State private var tokenText = ""
    @State private var showingGuide = false
    var onSaved: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Вставьте токен доступа")
                .font(.headline)
            Text("Получите его через приложение Proxygen из официального приложения Дневник.ру / Моя Школа.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Как получить токен?") {
                showingGuide = true
            }
            .font(.footnote)
            TextEditor(text: $tokenText)
                .frame(height: 120)
                .border(Color.secondary.opacity(0.3))
            Button("Сохранить") {
                let trimmed = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                TokenStore.save(trimmed)
                AuthEduClient.clearBootstrapCache()
                onSaved()
            }
            .buttonStyle(.borderedProminent)
            .disabled(tokenText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .sheet(isPresented: $showingGuide) {
            TokenGuideView()
        }
    }
}
