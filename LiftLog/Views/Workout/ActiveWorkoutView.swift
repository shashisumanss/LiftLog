import SwiftUI
import SwiftData

// MARK: - View Model for tracking workout state

@Observable
final class ActiveWorkoutViewModel {
    var exerciseEntries: [ExerciseWorkoutState] = []
    var startTime = Date()
    var isFinished = false

    struct SetState: Identifiable {
        let id = UUID()
        var weight: String = ""
        var reps: String = ""
        var isWarmup: Bool = false
        var isCompleted: Bool = false
    }

    struct ExerciseWorkoutState: Identifiable {
        let id = UUID()
        let exercise: Exercise
        var sets: [SetState] = [SetState()]
    }

    func addExercise(_ exercise: Exercise) {
        guard !exerciseEntries.contains(where: { $0.exercise.id == exercise.id }) else { return }
        exerciseEntries.append(ExerciseWorkoutState(exercise: exercise))
    }

    func addSet(to entryIndex: Int) {
        exerciseEntries[entryIndex].sets.append(SetState())
    }

    func removeSet(from entryIndex: Int, at setIndex: Int) {
        exerciseEntries[entryIndex].sets.remove(at: setIndex)
    }

    func completeSet(entryIndex: Int, setIndex: Int) {
        exerciseEntries[entryIndex].sets[setIndex].isCompleted = true
    }
}

// MARK: - Active Workout View

struct ActiveWorkoutView: View {
    let routine: Routine?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActiveWorkoutViewModel()
    @State private var showingExercisePicker = false
    @State private var selectedExercises: Set<Exercise> = []
    @State private var showingFinishAlert = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var elapsedSeconds: Int = 0

    var body: some View {
        List {
            // Timer header
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(routine?.name ?? "Quick Workout")
                            .font(.headline)
                        Text(formattedTime)
                            .font(.system(.title2, design: .monospaced).weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }
                    Spacer()
                    Button {
                        showingFinishAlert = true
                    } label: {
                        Text("Finish")
                            .font(.subheadline.weight(.bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }

            // Exercise sections
            ForEach(Array(viewModel.exerciseEntries.enumerated()), id: \.element.id) { entryIndex, entry in
                Section {
                    // Sets
                    ForEach(Array(entry.sets.enumerated()), id: \.element.id) { setIndex, setItem in
                        AddSetRow(
                            setNumber: setIndex + 1,
                            weight: binding(for: entryIndex, set: setIndex, keyPath: \.weight),
                            reps: binding(for: entryIndex, set: setIndex, keyPath: \.reps),
                            isWarmup: binding(for: entryIndex, set: setIndex, keyPath: \.isWarmup),
                            onComplete: {
                                viewModel.completeSet(entryIndex: entryIndex, setIndex: setIndex)
                            }
                        )
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            viewModel.removeSet(from: entryIndex, at: index)
                        }
                    }

                    // Add set button
                    Button {
                        withAnimation {
                            viewModel.addSet(to: entryIndex)
                        }
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                } header: {
                    Text(entry.exercise.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Add exercise button
            Section {
                Button {
                    selectedExercises = Set(viewModel.exerciseEntries.map(\.exercise))
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onReceive(timer) { _ in
            elapsedSeconds += 1
        }
        .onAppear {
            setupFromRoutine()
        }
        .sheet(isPresented: $showingExercisePicker, onDismiss: applyExerciseSelection) {
            ExercisePickerView(selected: $selectedExercises)
        }
        .alert("Finish Workout?", isPresented: $showingFinishAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Save & Finish") { saveWorkout() }
        } message: {
            Text("This will save all completed sets to your workout history.")
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func setupFromRoutine() {
        guard let routine, viewModel.exerciseEntries.isEmpty else { return }
        for exercise in routine.orderedExercises {
            viewModel.addExercise(exercise)
        }
    }

    private func applyExerciseSelection() {
        let existing = Set(viewModel.exerciseEntries.map(\.exercise.id))
        for exercise in selectedExercises where !existing.contains(exercise.id) {
            viewModel.addExercise(exercise)
        }
    }

    private func binding(for entryIndex: Int, set setIndex: Int, keyPath: WritableKeyPath<ActiveWorkoutViewModel.SetState, String>) -> Binding<String> {
        Binding(
            get: { viewModel.exerciseEntries[entryIndex].sets[setIndex][keyPath: keyPath] },
            set: { viewModel.exerciseEntries[entryIndex].sets[setIndex][keyPath: keyPath] = $0 }
        )
    }

    private func binding(for entryIndex: Int, set setIndex: Int, keyPath: WritableKeyPath<ActiveWorkoutViewModel.SetState, Bool>) -> Binding<Bool> {
        Binding(
            get: { viewModel.exerciseEntries[entryIndex].sets[setIndex][keyPath: keyPath] },
            set: { viewModel.exerciseEntries[entryIndex].sets[setIndex][keyPath: keyPath] = $0 }
        )
    }

    private func saveWorkout() {
        let now = Date()
        for entry in viewModel.exerciseEntries {
            let completedSets = entry.sets.filter { $0.isCompleted }
            guard !completedSets.isEmpty else { continue }

            let workoutEntry = WorkoutEntry(exercise: entry.exercise, date: now)
            context.insert(workoutEntry)

            for (index, setData) in completedSets.enumerated() {
                let weight = Double(setData.weight) ?? 0
                let reps = Int(setData.reps) ?? 0
                guard weight > 0 || reps > 0 else { continue }

                let setEntry = SetEntry(
                    setNumber: index + 1,
                    weight: weight,
                    reps: reps,
                    isWarmup: setData.isWarmup
                )
                setEntry.workoutEntry = workoutEntry
                context.insert(setEntry)
            }
        }

        try? context.save()
        dismiss()
    }
}
