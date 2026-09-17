import SwiftUI

struct FriendEditorView: View {
    @Binding var friend: FriendSchedule
    @State private var selectedDay = Weekday(rawValue: Calendar.current.component(.weekday, from: Date())) ?? .monday
    @State private var newSubject = ""
    @State private var newRoom = ""

    var body: some View {
        Form {
            Picker("День", selection: $selectedDay) {
                ForEach(Weekday.allCases) { day in
                    Text(day.displayName).tag(day)
                }
            }

            Section("Уроки") {
                ForEach(entries) { entry in
                    Text("\(entry.subject) (\(entry.room))")
                }
                .onDelete(perform: deleteEntries)
                .onMove(perform: moveEntries)

                HStack {
                    TextField("Предмет", text: $newSubject)
                    TextField("Кабинет", text: $newRoom)
                    Button("+", action: addEntry)
                        .disabled(newSubject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle(friend.name)
        .toolbar { EditButton() }
    }

    private var entries: [ManualLessonEntry] {
        friend.lessonsByWeekday[selectedDay.rawValue] ?? []
    }

    private func addEntry() {
        let subject = newSubject.trimmingCharacters(in: .whitespacesAndNewlines)
        let room = newRoom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subject.isEmpty else { return }
        var day = entries
        day.append(ManualLessonEntry(subject: subject, room: room))
        friend.lessonsByWeekday[selectedDay.rawValue] = day
        newSubject = ""
        newRoom = ""
    }

    private func deleteEntries(_ offsets: IndexSet) {
        var day = entries
        day.remove(atOffsets: offsets)
        friend.lessonsByWeekday[selectedDay.rawValue] = day
    }

    private func moveEntries(_ source: IndexSet, _ destination: Int) {
        var day = entries
        day.move(fromOffsets: source, toOffset: destination)
        friend.lessonsByWeekday[selectedDay.rawValue] = day
    }
}
