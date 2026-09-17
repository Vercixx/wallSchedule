import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @State private var settings = RenderSettings.load()
    @State private var hasBackgroundImage = BackgroundImageStore.load() != nil
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Обои") {
                    ColorPicker("Цвет фона", selection: Binding(
                        get: { settings.backgroundColor },
                        set: { settings.backgroundHex = $0.hexString; settings.save() }
                    ))
                    ColorPicker("Цвет текста", selection: Binding(
                        get: { settings.textColor },
                        set: { settings.textHex = $0.hexString; settings.save() }
                    ))
                    Picker("Шрифт", selection: Binding(
                        get: { settings.fontDesign },
                        set: { settings.fontDesign = $0; settings.save() }
                    )) {
                        ForEach(FontDesignOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    PhotosPicker("Фон из Фото", selection: $selectedPhoto, matching: .images)
                    if hasBackgroundImage {
                        Button("Сбросить фон", role: .destructive) {
                            BackgroundImageStore.clear()
                            hasBackgroundImage = false
                        }
                    }
                }
                Button("Выйти", role: .destructive) {
                    TokenStore.clear()
                    AuthEduClient.clearBootstrapCache()
                    isLoggedIn = false
                }
            }
            .navigationTitle("Настройки")
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    guard let newValue, let data = try? await newValue.loadTransferable(type: Data.self) else { return }
                    BackgroundImageStore.save(data)
                    hasBackgroundImage = true
                }
            }
        }
    }
}
