import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = TokenStore.load() != nil
    @State private var lessons: [Lesson] = []
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var showingClasses = false

    var body: some View {
        Group {
            if isLoggedIn {
                scheduleScreen
            } else {
                LoginView { isLoggedIn = true }
            }
        }
        .task(id: isLoggedIn) {
            if isLoggedIn { await loadCached() }
        }
    }

    private var scheduleScreen: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            Button(isRefreshing ? "Обновление…" : "Обновить") {
                Task { await refresh() }
            }
            .disabled(isRefreshing)
            Button("Классы") {
                showingClasses = true
            }
            Button("Выйти", role: .destructive) {
                TokenStore.clear()
                AuthEduClient.clearBootstrapCache()
                lessons = []
                isLoggedIn = false
            }
        }
        .padding()
        .sheet(isPresented: $showingClasses) {
            ClassesListView()
        }
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
