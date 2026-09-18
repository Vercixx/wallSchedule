import SwiftUI

struct ClassScheduleView: View {
    @Binding var schedule: FriendSchedule
    var isSelf: Bool = false

    @State private var selectedDay = Weekday(rawValue: Calendar.current.component(.weekday, from: Date())) ?? .monday
    @State private var newSubject = ""
    @State private var newRoom = ""
    @State private var isRefreshing = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Picker("День", selection: $selectedDay) {
                ForEach(Weekday.allCases) { day in
                    Text(day.displayName).tag(day)
                }
            }

            Section("Уроки") {
                ForEach(entries) { entry in
                    HStack {
                        TextField("Предмет", text: binding(for: entry.id, \.subject))
                        TextField("Кабинет", text: binding(for: entry.id, \.room))
                    }
                }
                .onDelete(perform: deleteEntries)
                .onMove(perform: moveEntries)

                HStack {
                    TextField("Предмет", text: $newSubject)
                    TextField("Кабинет", text: $newRoom)
                    Button("+", action: addEntry)
                        .disabled(newSubject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                PhotoScheduleCaptureButton(
                    label: isSelf ? "Распознать по фото" : "Заполнить по фото",
                    targetClassName: isSelf ? AuthEduClient.cachedClassName() : schedule.name
                ) { entries in
                    schedule.lessonsByWeekday[selectedDay.rawValue] = entries
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle(isSelf ? (AuthEduClient.cachedClassName() ?? "Мой класс") : schedule.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { EditButton() }
            if isSelf {
                ToolbarItem(placement: .primaryAction) {
                    Button(isRefreshing ? "Обновление…" : "Обновить") {
                        Task { await refresh() }
                    }
                    .disabled(isRefreshing)
                }
            }
        }
    }

    private var entries: [ManualLessonEntry] {
        schedule.lessonsByWeekday[selectedDay.rawValue] ?? []
    }

    private func binding(for id: UUID, _ keyPath: WritableKeyPath<ManualLessonEntry, String>) -> Binding<String> {
        Binding(
            get: { entries.first(where: { $0.id == id })?[keyPath: keyPath] ?? "" },
            set: { newValue in
                guard var day = schedule.lessonsByWeekday[selectedDay.rawValue],
                      let index = day.firstIndex(where: { $0.id == id }) else { return }
                day[index][keyPath: keyPath] = newValue
                schedule.lessonsByWeekday[selectedDay.rawValue] = day
            }
        )
    }

    private func addEntry() {
        let subject = newSubject.trimmingCharacters(in: .whitespacesAndNewlines)
        let room = newRoom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subject.isEmpty else { return }
        var day = entries
        day.append(ManualLessonEntry(subject: subject, room: room))
        schedule.lessonsByWeekday[selectedDay.rawValue] = day
        newSubject = ""
        newRoom = ""
    }

    private func deleteEntries(_ offsets: IndexSet) {
        var day = entries
        day.remove(atOffsets: offsets)
        schedule.lessonsByWeekday[selectedDay.rawValue] = day
    }

    private func moveEntries(_ source: IndexSet, _ destination: Int) {
        var day = entries
        day.move(fromOffsets: source, toOffset: destination)
        schedule.lessonsByWeekday[selectedDay.rawValue] = day
    }

    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    private func refresh() async {
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }
        do {
            let lessons = try await AuthEduClient.shared.todaySchedule(bypassRateLimit: true)
            schedule.lessonsByWeekday[todayWeekday] = lessons.map {
                ManualLessonEntry(subject: $0.subject, room: $0.room)
            }
        } catch {
            errorMessage = "\(error)"
        }
    }
}
