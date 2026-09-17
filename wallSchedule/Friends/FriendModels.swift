import Foundation

struct ManualLessonEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var subject: String
    var room: String
}

struct FriendSchedule: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var lessonsByWeekday: [Int: [ManualLessonEntry]] = [:]

    // startAt is display-only here — order in lessonsByWeekday is the real source of truth.
    func todayLessons(now: Date = Date()) -> [Lesson] {
        let weekday = Calendar.current.component(.weekday, from: now)
        let entries = lessonsByWeekday[weekday] ?? []
        return entries.enumerated().map { offset, entry in
            Lesson(index: offset + 1, subject: entry.subject, room: entry.room, startAt: Date(timeIntervalSince1970: TimeInterval(offset)))
        }
    }
}

enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .sunday: "Воскресенье"
        case .monday: "Понедельник"
        case .tuesday: "Вторник"
        case .wednesday: "Среда"
        case .thursday: "Четверг"
        case .friday: "Пятница"
        case .saturday: "Суббота"
        }
    }
}
