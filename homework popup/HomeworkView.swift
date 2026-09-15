import SwiftUI
public import Combine

struct HomeworkAssignment: Identifiable, Codable {
    let id: UUID
    var title: String
    var subject: String
    var dueDate: Date
    var isCompleted: Bool

    init(title: String, subject: String, dueDate: Date) {
        id = UUID()
        self.title = title
        self.subject = subject
        self.dueDate = dueDate
        isCompleted = false
    }
}

@MainActor
final class HomeworkStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published var assignments: [HomeworkAssignment] {
        didSet {
            save()
        }
    }

    private let saveKey = "homeworkAssignments"

    init() {
        if let data = UserDefaults.standard.data(
            forKey: saveKey
        ),
        let saved = try? JSONDecoder().decode(
            [HomeworkAssignment].self,
            from: data
        ) {
            assignments = saved
        } else {
            assignments = []
        }
    }

    func add(title: String, subject: String, dueDate: Date) {
        let assignment = HomeworkAssignment(
            title: title,
            subject: subject,
            dueDate: dueDate
        )

        assignments.append(assignment)
        sortAssignments()
    }

    func toggle(_ id: UUID) {
        guard let index = assignments.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        objectWillChange.send()
        assignments[index].isCompleted.toggle()
        sortAssignments()
    }

    func delete(_ id: UUID) {
        objectWillChange.send()
        assignments.removeAll { $0.id == id }
    }
    
    func clearFinished() {
        guard assignments.contains(where: { $0.isCompleted }) else {
            return
        }

        objectWillChange.send()
        assignments.removeAll { $0.isCompleted }
    }

    private func sortAssignments() {
        assignments.sort {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }

            return $0.dueDate < $1.dueDate
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(assignments) else {
            return
        }

        UserDefaults.standard.set(data, forKey: saveKey)
    }
}

struct HomeworkView: View {
    @StateObject private var store = HomeworkStore()

    @State private var title = ""
    @State private var subject = ""
    @State private var dueDate =
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Homework")
                .font(.title2.bold())

            TextField("What do you need to do?", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Class or subject", text: $subject)
                .textFieldStyle(.roundedBorder)

            DatePicker(
                "Due",
                selection: $dueDate,
                displayedComponents: [.date, .hourAndMinute]
            )

            Button {
                addHomework()
            } label: {
                Label("Add homework", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

            Divider()

            if store.assignments.isEmpty {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.green)

                    Text("Nothing due!")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.assignments) { assignment in
                            assignmentRow(assignment)
                        }
                    }
                    
                }
                if store.assignments.contains(where: { $0.isCompleted }) {
                    Divider()

                    Button(role: .destructive) {
                        store.clearFinished()
                    } label: {
                        Label(
                            "Clear finished assignments",
                            systemImage: "trash"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.ultraThickMaterial)
    }

    private func assignmentRow(
        _ assignment: HomeworkAssignment
    ) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggle(assignment.id)
            } label: {
                Image(
                    systemName: assignment.isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3)
                .foregroundStyle(
                    assignment.isCompleted ? .green : .secondary
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.title)
                    .strikethrough(assignment.isCompleted)

                if !assignment.subject.isEmpty {
                    Text(assignment.subject)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(
                    assignment.dueDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(
                    isOverdue(assignment) ? .red : .secondary
                )
            }

            Spacer()

            Button {
                store.delete(assignment.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func isOverdue(
        _ assignment: HomeworkAssignment
    ) -> Bool {
        !assignment.isCompleted && assignment.dueDate < Date()
    }

    private func addHomework() {
        let cleanedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedTitle.isEmpty else {
            return
        }

        store.add(
            title: cleanedTitle,
            subject: subject.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            dueDate: dueDate
        )

        title = ""
        subject = ""
    }
}
