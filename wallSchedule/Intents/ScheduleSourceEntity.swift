import AppIntents

struct ScheduleSourceEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Источник расписания"
    static var defaultQuery = ScheduleSourceQuery()

    static let meID = "me"

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct ScheduleSourceQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ScheduleSourceEntity] {
        Self.allEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ScheduleSourceEntity] {
        Self.allEntities()
    }

    private static func allEntities() -> [ScheduleSourceEntity] {
        let me = ScheduleSourceEntity(id: ScheduleSourceEntity.meID, name: "Мои уроки")
        let friends = FriendsStore.load().map { ScheduleSourceEntity(id: $0.id.uuidString, name: $0.name) }
        return [me] + friends
    }
}
