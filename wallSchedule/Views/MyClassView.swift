import SwiftUI

struct MyClassView: View {
    @State private var lessons: [Lesson] = []
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var hasOverride = TodayOverrideStore.load() != nil

    var body: some View {
        List {
            if hasOverride {
                HStack {
                    Text("Показано расписание по фото")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Сбросить") {
                        TodayOverrideStore.clear()
                        hasOverride = false
                        Task { await loadCached() }
                    }
                    .font(.footnote)
                }
            }
            if lessons.isEmpty {
                Text("Расписание ещё не загружено.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(lessons) { lesson in
                    Text(lesson.displayLine)
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            PhotoScheduleCaptureButton(
                label: "Распознать изменения по фото",
                targetClassName: AuthEduClient.cachedClassName()
            ) { entries in
                let overrideLessons = entries.enumerated().map { offset, entry in
                    Lesson(index: offset + 1, subject: entry.subject, room: entry.room, startAt: Date(timeIntervalSince1970: TimeInterval(offset)))
                }
                TodayOverrideStore.save(overrideLessons)
                hasOverride = true
                lessons = overrideLessons
            }
        }
        .navigationTitle(AuthEduClient.cachedClassName() ?? "Мой класс")
        .toolbar {
            Button(isRefreshing ? "Обновление…" : "Обновить") {
                Task { await refresh() }
            }
            .disabled(isRefreshing)
        }
        .task { await loadCached() }
    }

    private func loadCached() async {
        if let override = TodayOverrideStore.load() {
            lessons = override
            return
        }
        if let cached = await ScheduleCache.shared.load() {
            lessons = cached.lessons
        }
    }

    private func refresh() async {
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }
        do {
            lessons = try await AuthEduClient.shared.todaySchedule(bypassRateLimit: true)
        } catch {
            errorMessage = "\(error)"
        }
    }
}
