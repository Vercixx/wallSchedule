import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @State private var settings = RenderSettings.load()
    @State private var hasBackgroundImage = BackgroundImageStore.load() != nil
    @State private var selectedPhoto: PhotosPickerItem?

    private static let previewLessons = [
        Lesson(index: 1, subject: "Алгебра", room: "204", startAt: Date()),
        Lesson(index: 2, subject: "Русский язык", room: "201", startAt: Date()),
        Lesson(index: 3, subject: "Физика", room: "310", startAt: Date()),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Предпросмотр") {
                    GeometryReader { geo in
                        let native = WallpaperGeometry.pointSize
                        let scale = geo.size.width / native.width
                        ScheduleWallpaperView(lessons: Self.previewLessons, settings: settings)
                            .frame(width: native.width, height: native.height)
                            .scaleEffect(scale)
                            .frame(width: geo.size.width, height: native.height * scale)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(height: 300)
                }
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
                        get: { settings.fontFamily },
                        set: { settings.fontFamily = $0; settings.save() }
                    )) {
                        ForEach(SystemFonts.familyNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Размер текста: \(Int(settings.textSize))")
                        Slider(
                            value: Binding(
                                get: { settings.textSize },
                                set: { settings.textSize = $0; settings.save() }
                            ),
                            in: 20...60,
                            step: 2
                        )
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
                    TodayOverrideStore.clear()
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
