import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Binding var selected: Set<Exercise>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var grouped: [String: [Exercise]] {
        Dictionary(grouping: filtered) { $0.category }
    }

    private var filtered: [Exercise] {
        if searchText.isEmpty { return allExercises }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var sortedCategories: [String] {
        grouped.keys.sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedCategories, id: \.self) { category in
                    Section(category) {
                        ForEach(grouped[category] ?? []) { exercise in
                            Button {
                                toggleSelection(exercise)
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selected.contains(exercise) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.accent)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done (\(selected.count))") { dismiss() }
                        .bold()
                }
            }
        }
    }

    private func toggleSelection(_ exercise: Exercise) {
        if selected.contains(exercise) {
            selected.remove(exercise)
        } else {
            selected.insert(exercise)
        }
    }
}
