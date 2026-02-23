import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var context
    @State private var showingExercisePicker = false
    @State private var selectedExercises: Set<Exercise> = []

    var body: some View {
        List {
            Section {
                TextField("Routine Name", text: $routine.name)
                    .font(.headline)
            }

            Section("Exercises") {
                if routine.orderedExercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "dumbbell",
                        description: Text("Add exercises to this routine.")
                    )
                } else {
                    ForEach(routine.orderedExercises) { exercise in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.body.weight(.medium))
                                Text(exercise.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .onMove(perform: moveExercises)
                    .onDelete(perform: removeExercises)
                }
            }

            Section {
                Button {
                    selectedExercises = Set(routine.exercises)
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercises", systemImage: "plus.circle")
                }
            }

            Section {
                NavigationLink {
                    ActiveWorkoutView(routine: routine)
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingExercisePicker, onDismiss: applySelection) {
            ExercisePickerView(selected: $selectedExercises)
        }
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var exercises = routine.orderedExercises
        exercises.move(fromOffsets: source, toOffset: destination)
        routine.setExercises(exercises)
    }

    private func removeExercises(at offsets: IndexSet) {
        var exercises = routine.orderedExercises
        exercises.remove(atOffsets: offsets)
        routine.setExercises(exercises)
    }

    private func applySelection() {
        let existing = routine.orderedExercises
        let existingSet = Set(existing.map { $0.id })
        // Start with existing order
        var result = existing.filter { selectedExercises.contains($0) }
        // Append newly selected exercises
        for ex in selectedExercises where !existingSet.contains(ex.id) {
            result.append(ex)
        }
        routine.setExercises(result)
    }
}
