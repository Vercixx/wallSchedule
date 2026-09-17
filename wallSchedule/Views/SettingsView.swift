import SwiftUI

struct SettingsView: View {
    @Binding var isLoggedIn: Bool

    var body: some View {
        NavigationStack {
            Form {
                Button("Выйти", role: .destructive) {
                    TokenStore.clear()
                    AuthEduClient.clearBootstrapCache()
                    isLoggedIn = false
                }
            }
            .navigationTitle("Настройки")
        }
    }
}
