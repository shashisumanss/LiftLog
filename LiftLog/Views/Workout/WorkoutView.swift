import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var allEntries: [WorkoutEntry]
    @Environment(\.modelContext) private var context
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @State private var showingActiveWorkout = false

    private var recentDates: [Date] {
        let calendar = Calendar.current
        var seen: Set<DateComponents> = []
        var dates: [Date] = []
        for entry in allEntries {
            let comp = calendar.dateComponents([.year, .month, .day], from: entry.date)
            if seen.insert(comp).inserted {
                dates.append(entry.date)
            }
            if dates.count >= 10 { break }
        }
        return dates
    }

    private func entriesForDate(_ date: Date) -> [WorkoutEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Start
                    VStack(spacing: 12) {
                        NavigationLink {
                            ActiveWorkoutView(routine: nil)
                        } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Start Empty Workout")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.accent.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)

                    // Start from Routine
                    if !routines.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Start from Routine")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(routines) { routine in
                                        NavigationLink {
                                            ActiveWorkoutView(routine: routine)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(routine.name)
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundStyle(.primary)
                                                Text("\(routine.exercises.count) exercises")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                HStack(spacing: 4) {
                                                    ForEach(routine.exercises.prefix(3)) { ex in
                                                        Text(ex.name)
                                                            .font(.caption2)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                .foregroundStyle(.tertiary)
                                            }
                                            .padding()
                                            .frame(width: 180, alignment: .leading)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .strokeBorder(.accent.opacity(0.2), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Recent History
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Recent Workouts")
                                .font(.headline)
                            Spacer()
                            if !recentDates.isEmpty {
                                NavigationLink {
                                    WorkoutHistoryView()
                                } label: {
                                    Text("View All")
                                        .font(.subheadline)
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                        .padding(.horizontal)

                        if recentDates.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.accent.opacity(0.3))
                                Text("No workouts yet")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Hit the button above to start your first workout!")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .padding(.horizontal)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(recentDates, id: \.self) { date in
                                    let entries = entriesForDate(date)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(date, style: .date)
                                            .font(.subheadline.weight(.semibold))
                                        ForEach(entries) { entry in
                                            if let exerciseName = entry.exercise?.name {
                                                HStack {
                                                    Text(exerciseName)
                                                        .font(.caption)
                                                    Spacer()
                                                    Text("\(entry.sets.count) sets · \(Int(entry.maxWeight)) \(weightUnit)")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteEntries(for: date)
                                        } label: {
                                            Label("Delete Workout", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Workout")
        }
    }

    private func deleteEntries(for date: Date) {
        let entries = entriesForDate(date)
        for entry in entries {
            context.delete(entry)
        }
        try? context.save()
    }
}
