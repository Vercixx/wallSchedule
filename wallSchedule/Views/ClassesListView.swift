import SwiftUI

struct ClassesListView: View {
    @State private var friends = FriendsStore.load()
    @State private var newName = ""
    @State private var myClassName = AuthEduClient.cachedClassName()

    var body: some View {
        NavigationStack {
            List {
                Section("Мой класс") {
                    NavigationLink(myClassName ?? "Мой класс") {
                        MyClassView()
                    }
                }
                Section("Классы друзей") {
                    ForEach(friends) { friend in
                        NavigationLink(friend.name) {
                            FriendEditorView(friend: bindingFor(friend))
                        }
                    }
                    .onDelete { offsets in
                        friends.remove(atOffsets: offsets)
                        FriendsStore.save(friends)
                    }
                    HStack {
                        TextField("Название класса", text: $newName)
                        Button("Добавить") {
                            let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            friends.append(FriendSchedule(name: trimmed))
                            FriendsStore.save(friends)
                            newName = ""
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("Классы")
            .task {
                if myClassName == nil {
                    myClassName = await AuthEduClient.shared.resolveClassName()
                }
            }
        }
    }

    private func bindingFor(_ friend: FriendSchedule) -> Binding<FriendSchedule> {
        guard let index = friends.firstIndex(where: { $0.id == friend.id }) else {
            return .constant(friend)
        }
        return Binding(
            get: { friends[index] },
            set: { friends[index] = $0; FriendsStore.save(friends) }
        )
    }
}
