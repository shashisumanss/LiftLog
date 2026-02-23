import SwiftUI
import SwiftData

struct ExercisesListView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.modelContext) private var context
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var newExerciseName = ""
    @State private var newExerciseCategory = "Chest"

    private let categories = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Cardio", "Olympic"]

    private var filtered: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var grouped: [String: [Exercise]] {
        Dictionary(grouping: filtered) { $0.category }
    }

    private var sortedCategories: [String] {
        grouped.keys.sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedCategories, id: \.self) { category in
                    Section {
                        ForEach(grouped[category] ?? []) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.name)
                                            .font(.body.weight(.medium))
                                        Text("\(exercise.entries.count) workout\(exercise.entries.count == 1 ? "" : "s") logged")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if exercise.isCustom {
                                        Text("Custom")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.15))
                                            .foregroundStyle(Color.accentColor)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            deleteExercises(in: category, at: offsets)
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: iconForCategory(category))
                                .foregroundStyle(Color.accentColor)
                            Text(category)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
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
                addExerciseSheet
            }
            .overlay {
                if filtered.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }

    private var addExerciseSheet: some View {
        NavigationStack {
            Form {
                TextField("Exercise Name", text: $newExerciseName)
                Picker("Category", selection: $newExerciseCategory) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetAddForm()
                        showingAddSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExercise()
                    }
                    .bold()
                    .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addExercise() {
        let exercise = Exercise(
            name: newExerciseName.trimmingCharacters(in: .whitespaces),
            category: newExerciseCategory,
            isCustom: true
        )
        context.insert(exercise)
        resetAddForm()
        showingAddSheet = false
    }

    private func resetAddForm() {
        newExerciseName = ""
        newExerciseCategory = "Chest"
    }

    private func deleteExercises(in category: String, at offsets: IndexSet) {
        let categoryExercises = grouped[category] ?? []
        for index in offsets {
            let exercise = categoryExercises[index]
            if exercise.isCustom {
                context.delete(exercise)
            }
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Chest": return "figure.strengthtraining.traditional"
        case "Back": return "figure.rowing"
        case "Legs": return "figure.walk"
        case "Shoulders": return "figure.arms.open"
        case "Arms": return "dumbbell"
        case "Core": return "figure.core.training"
        case "Cardio": return "figure.run"
        case "Olympic": return "figure.highintensity.intervaltraining"
        default: return "figure.mixed.cardio"
        }
    }
}
