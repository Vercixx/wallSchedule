import SwiftUI

struct MyClassView: View {
    @State private var lessons: [Lesson] = []
    @State private var isRefreshing = false
    @State private var errorMessage: String?

    var body: some View {
        List {
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
