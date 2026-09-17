import SwiftUI

struct LoginView: View {
    @State private var tokenText = ""
    var onSaved: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Paste your bearer token")
                .font(.headline)
            Text("Captured from the official Дневник.ру / Моя Школа app via mitmproxy or Charles.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            TextEditor(text: $tokenText)
                .frame(height: 120)
                .border(Color.secondary.opacity(0.3))
            Button("Save") {
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
    }
}
