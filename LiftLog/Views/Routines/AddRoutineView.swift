import SwiftUI
import SwiftData

struct AddRoutineView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedExercises: Set<Exercise> = []
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Info") {
                    TextField("Routine Name", text: $name)
                }

                Section("Exercises (\(selectedExercises.count))") {
                    if selectedExercises.isEmpty {
                        Text("No exercises selected")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(selectedExercises).sorted(by: { $0.name < $1.name })) { exercise in
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Text(exercise.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        Label("Select Exercises", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView(selected: $selectedExercises)
            }
        }
    }

    private func save() {
        let routine = Routine(
            name: name.trimmingCharacters(in: .whitespaces),
            exercises: Array(selectedExercises)
        )
        context.insert(routine)
        dismiss()
    }
}
