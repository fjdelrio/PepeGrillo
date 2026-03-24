import Foundation

struct PersonProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var notes: String = ""
    var lastUpdated: Date = Date()
}

/// Ultra-simple local persistence (Codable JSON in Documents).
@MainActor
final class PeopleStore: ObservableObject {
    @Published private(set) var people: [PersonProfile] = []

    private let fileURL: URL

    init(filename: String = "pepegrillo_people.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func upsert(_ person: PersonProfile) {
        if let idx = people.firstIndex(where: { $0.id == person.id }) {
            people[idx] = person
        } else {
            people.insert(person, at: 0)
        }
        save()
    }

    func delete(_ person: PersonProfile) {
        people.removeAll { $0.id == person.id }
        save()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            self.people = try JSONDecoder().decode([PersonProfile].self, from: data)
        } catch {
            self.people = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(people)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // ignore for MVP
        }
    }
}
