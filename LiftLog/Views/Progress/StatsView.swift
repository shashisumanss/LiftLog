import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var allEntries: [WorkoutEntry]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"

    private var totalWorkoutDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(allEntries.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)) ?? .now
        let uniqueDays = Set(
            allEntries
                .filter { $0.date >= startOfWeek }
                .map { calendar.startOfDay(for: $0.date) }
        )
        return uniqueDays.count
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(allEntries.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        // Allow today or yesterday as start
        if !uniqueDays.contains(checkDate) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        for day in uniqueDays {
            if calendar.isDate(day, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if day < checkDate {
                break
            }
        }
        return streak
    }

    private var totalSets: Int {
        allEntries.reduce(0) { $0 + $1.sets.count }
    }

    private var personalRecords: [(exercise: Exercise, weight: Double)] {
        exercises.compactMap { exercise in
            let maxW = exercise.entries.flatMap { $0.sets }.map(\.weight).max()
            guard let w = maxW, w > 0 else { return nil }
            return (exercise, w)
        }
        .sorted { $0.weight > $1.weight }
    }

    private var recentEntries: [WorkoutEntry] {
        Array(allEntries.prefix(15))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12) {
                        SummaryCard(title: "Workouts", value: "\(totalWorkoutDays)", icon: "flame.fill", color: .orange)
                        SummaryCard(title: "This Week", value: "\(thisWeekCount)", icon: "calendar", color: .blue)
                        SummaryCard(title: "Streak", value: "\(currentStreak) day\(currentStreak == 1 ? "" : "s")", icon: "bolt.fill", color: .yellow)
                        SummaryCard(title: "Total Sets", value: "\(totalSets)", icon: "repeat", color: .green)
                    }
                    .padding(.horizontal)

                    // Personal Records
                    if !personalRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                Text("Personal Records")
                                    .font(.headline)
                            }
                            .padding(.horizontal)

                            LazyVStack(spacing: 6) {
                                ForEach(personalRecords.prefix(8), id: \.exercise.id) { record in
                                    NavigationLink {
                                        ExerciseChartView(exercise: record.exercise)
                                    } label: {
                                        HStack {
                                            Text(record.exercise.name)
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text("\(Int(record.weight)) \(weightUnit)")
                                                .font(.subheadline.weight(.bold).monospacedDigit())
                                                .foregroundStyle(.accent)
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        if recentEntries.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.largeTitle)
                                    .foregroundStyle(.quaternary)
                                Text("Complete workouts to see your progress")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(recentEntries) { entry in
                                    if let exercise = entry.exercise {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(exercise.name)
                                                    .font(.subheadline.weight(.medium))
                                                Text(entry.date, style: .date)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("\(entry.sets.count) sets")
                                                    .font(.caption.weight(.medium))
                                                Text("\(Int(entry.maxWeight)) \(weightUnit)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
