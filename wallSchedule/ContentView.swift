import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = TokenStore.load() != nil

    var body: some View {
        if isLoggedIn {
            TabView {
                ClassesListView()
                    .tabItem { Label("Классы", systemImage: "list.bullet") }
                SettingsView(isLoggedIn: $isLoggedIn)
                    .tabItem { Label("Настройки", systemImage: "gearshape") }
            }
        } else {
            LoginView { isLoggedIn = true }
        }
    }
}
