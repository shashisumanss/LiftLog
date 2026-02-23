import SwiftUI
import SwiftData

struct RoutinesListView: View {
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if routines.isEmpty {
                    ContentUnavailableView(
                        "No Routines",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Create your first routine to organize your workouts.")
                    )
                } else {
                    ForEach(routines) { routine in
                        NavigationLink {
                            RoutineDetailView(routine: routine)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routine.name)
                                    .font(.body.weight(.semibold))
                                Text("\(routine.exercises.count) exercise\(routine.exercises.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !routine.exercises.isEmpty {
                                    Text(routine.exercises.prefix(3).map(\.name).joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete(perform: deleteRoutines)
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRoutineView()
            }
        }
    }

    private func deleteRoutines(at offsets: IndexSet) {
        for index in offsets {
            context.delete(routines[index])
        }
    }
}
