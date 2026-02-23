import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"

    private var sortedEntries: [WorkoutEntry] {
        exercise.entries.sorted { $0.date > $1.date }
    }

    private var personalRecord: Double {
        exercise.entries.flatMap { $0.sets }.map(\.weight).max() ?? 0
    }

    var body: some View {
        List {
            Section {
                HStack {
                    StatCard(title: "Category", value: exercise.category, icon: "tag.fill")
                    StatCard(title: "Workouts", value: "\(exercise.entries.count)", icon: "flame.fill")
                    StatCard(title: "PR", value: personalRecord > 0 ? "\(Int(personalRecord)) \(weightUnit)" : "—", icon: "trophy.fill")
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Workout History") {
                if sortedEntries.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Log a workout with this exercise to see your history here.")
                    )
                } else {
                    ForEach(sortedEntries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.date, style: .date)
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 12) {
                                Label("\(entry.sets.count) sets", systemImage: "repeat")
                                Label("\(Int(entry.maxWeight)) \(weightUnit) max", systemImage: "scalemass")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            // Set breakdown
                            HStack(spacing: 8) {
                                ForEach(entry.sortedSets) { set in
                                    Text("\(Int(set.weight))×\(set.reps)")
                                        .font(.caption2.monospaced())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(set.isWarmup ? .yellow.opacity(0.15) : .accent.opacity(0.1))
                                        .foregroundStyle(set.isWarmup ? .orange : .accent)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
