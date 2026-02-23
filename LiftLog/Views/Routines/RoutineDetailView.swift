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
                if routine.exercises.isEmpty {
                    ContentUnavailableView(
                        "No Exercises",
                        systemImage: "dumbbell",
                        description: Text("Add exercises to this routine.")
                    )
                } else {
                    ForEach(routine.exercises) { exercise in
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
                        .foregroundStyle(.accent)
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
        var exercises = routine.exercises
        exercises.move(fromOffsets: source, toOffset: destination)
        routine.exercises = exercises
    }

    private func removeExercises(at offsets: IndexSet) {
        var exercises = routine.exercises
        exercises.remove(atOffsets: offsets)
        routine.exercises = exercises
    }

    private func applySelection() {
        let existingSet = Set(routine.exercises)
        // Add newly selected exercises
        let newExercises = selectedExercises.subtracting(existingSet)
        routine.exercises.append(contentsOf: newExercises)
        // Remove deselected exercises
        routine.exercises.removeAll { !selectedExercises.contains($0) }
    }
}
