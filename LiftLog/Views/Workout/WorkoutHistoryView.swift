import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var allEntries: [WorkoutEntry]
    @Environment(\.modelContext) private var context
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"

    private var groupedByDate: [(date: Date, entries: [WorkoutEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped
            .map { (date: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if groupedByDate.isEmpty {
                ContentUnavailableView(
                    "No Workout History",
                    systemImage: "clock",
                    description: Text("Complete a workout to see it here.")
                )
            } else {
                ForEach(groupedByDate, id: \.date) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            if let exercise = entry.exercise {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(exercise.name)
                                        .font(.body.weight(.medium))
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
                        .onDelete { offsets in
                            deleteEntries(from: group.entries, at: offsets)
                        }
                    } header: {
                        Text(group.date, style: .date)
                    }
                }
            }
        }
        .navigationTitle("Workout History")
        .navigationBarTitleDisplayMode(.large)
    }

    private func deleteEntries(from entries: [WorkoutEntry], at offsets: IndexSet) {
        for index in offsets {
            context.delete(entries[index])
        }
        try? context.save()
    }
}
