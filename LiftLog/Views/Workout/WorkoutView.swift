import SwiftUI
import SwiftData
import Charts

struct WorkoutView: View {
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var allEntries: [WorkoutEntry]
    @Environment(\.modelContext) private var context
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"

    // MARK: - Computed Properties

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Late Night Grind"
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "☀️"
        case 12..<17: return "💪"
        case 17..<22: return "🔥"
        default: return "🌙"
        }
    }

    private var motivationalMessage: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Start your day strong!"
        case 12..<17: return "Keep the momentum going!"
        case 17..<22: return "Time to crush it!"
        default: return "Dedication has no schedule."
        }
    }

    private var totalWorkoutDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(allEntries.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(allEntries.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        let today = calendar.startOfDay(for: .now)

        // Check if most recent workout was today or yesterday
        guard let first = uniqueDays.first else { return 0 }
        let diff = calendar.dateComponents([.day], from: first, to: today).day ?? 0
        guard diff <= 1 else { return 0 }

        for i in 0..<uniqueDays.count {
            let expected = calendar.date(byAdding: .day, value: -(i + diff), to: today)!
            if calendar.isDate(uniqueDays[i], inSameDayAs: expected) {
                streak += 1
            } else { break }
        }
        return streak
    }

    private var daysTrainedThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        let uniqueDays = Set(
            allEntries
                .filter { $0.date >= startOfWeek }
                .map { calendar.startOfDay(for: $0.date) }
        )
        return uniqueDays.count
    }

    private var thisWeekVolume: Double {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        return allEntries
            .filter { $0.date >= startOfWeek }
            .flatMap { $0.sets }
            .reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    // Volume trend data for last 14 days
    private var volumeTrendData: [(date: Date, volume: Double)] {
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: .now)!
        let recentEntries = allEntries.filter { $0.date >= twoWeeksAgo }

        var dailyVolume: [Date: Double] = [:]
        for entry in recentEntries {
            let day = calendar.startOfDay(for: entry.date)
            let vol = entry.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            dailyVolume[day, default: 0] += vol
        }

        return dailyVolume
            .map { (date: $0.key, volume: $0.value) }
            .sorted { $0.date < $1.date }
    }

    // Top lifts this week (exercises with highest weight)
    private var topLiftsThisWeek: [(name: String, weight: Double)] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        let weekEntries = allEntries.filter { $0.date >= startOfWeek }

        var bestByExercise: [String: Double] = [:]
        for entry in weekEntries {
            guard let name = entry.exercise?.name else { continue }
            let maxW = entry.sets.map(\.weight).max() ?? 0
            if maxW > (bestByExercise[name] ?? 0) {
                bestByExercise[name] = maxW
            }
        }

        return bestByExercise
            .map { (name: $0.key, weight: $0.value) }
            .sorted { $0.weight > $1.weight }
    }

    private var recentDates: [Date] {
        let calendar = Calendar.current
        var seen: Set<DateComponents> = []
        var dates: [Date] = []
        for entry in allEntries {
            let comp = calendar.dateComponents([.year, .month, .day], from: entry.date)
            if seen.insert(comp).inserted {
                dates.append(entry.date)
            }
            if dates.count >= 5 { break }
        }
        return dates
    }

    private func entriesForDate(_ date: Date) -> [WorkoutEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    quickStatsRow
                    startWorkoutButton

                    if !volumeTrendData.isEmpty {
                        volumeTrendSection
                    }

                    if !topLiftsThisWeek.isEmpty {
                        topLiftsSection
                    }

                    if !routines.isEmpty {
                        routinesSection
                    }

                    recentWorkoutsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Workout")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Streak ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: min(CGFloat(daysTrainedThisWeek) / 7.0, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange, Color.accentColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(daysTrainedThisWeek)")
                            .font(.title2.weight(.heavy))
                        Text("/7")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greeting) \(greetingEmoji)")
                        .font(.title3.weight(.bold))
                    Text(motivationalMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.3), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            StatPill(icon: "calendar", label: "Workouts", value: "\(totalWorkoutDays)")
            StatPill(icon: "flame.fill", label: "Streak", value: "\(currentStreak)d")
            StatPill(icon: "scalemass", label: "Volume", value: formatVolume(thisWeekVolume))
        }
        .padding(.horizontal)
    }

    // MARK: - Start Workout Button

    private var startWorkoutButton: some View {
        NavigationLink {
            ActiveWorkoutView(routine: nil)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                Text("Start Empty Workout")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Volume Trend

    private var volumeTrendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.accentColor)
                Text("Volume Trend")
                    .font(.headline)
                Spacer()
                Text("Last 14 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Chart(volumeTrendData, id: \.date) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(30)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 120)
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }

    // MARK: - Top Lifts

    private var topLiftsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Top Lifts This Week")
                    .font(.headline)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(topLiftsThisWeek.prefix(6), id: \.name) { lift in
                        VStack(spacing: 6) {
                            Text("\(Int(lift.weight))")
                                .font(.title3.weight(.bold))
                            Text(weightUnit)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(lift.name)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 90)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Routines

    private var routinesSection: some View {
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
                            RoutineCard(routine: routine)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Recent Workouts

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            recentWorkoutsHeader
            if recentDates.isEmpty {
                emptyWorkoutsView
            } else {
                recentWorkoutsList
            }
        }
    }

    private var recentWorkoutsHeader: some View {
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
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.horizontal)
    }

    private var emptyWorkoutsView: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor.opacity(0.3))
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
    }

    private var recentWorkoutsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(recentDates, id: \.self) { date in
                WorkoutDayCard(
                    date: date,
                    entries: entriesForDate(date),
                    weightUnit: weightUnit,
                    onDelete: { deleteEntries(for: date) }
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func deleteEntries(for date: Date) {
        let entries = entriesForDate(date)
        for entry in entries {
            context.delete(entry)
        }
        try? context.save()
    }

    private func formatVolume(_ vol: Double) -> String {
        if vol >= 1000 {
            return String(format: "%.1fk", vol / 1000)
        }
        return "\(Int(vol))"
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Routine Card

struct RoutineCard: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardHeader
            Text(routine.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
            exerciseList
        }
        .padding()
        .frame(width: 180, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
    }

    private var cardHeader: some View {
        HStack {
            Image(systemName: "bolt.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Spacer()
            Text("\(routine.orderedExercises.count)")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
        }
    }

    private var exerciseList: some View {
        HStack(spacing: 4) {
            ForEach(Array(routine.orderedExercises.prefix(2)), id: \.id) { ex in
                Text(ex.name)
                    .font(.caption2)
                    .lineLimit(1)
            }
            if routine.orderedExercises.count > 2 {
                Text("+\(routine.orderedExercises.count - 2)")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .foregroundStyle(.tertiary)
    }
}

// MARK: - Workout Day Card

struct WorkoutDayCard: View {
    let date: Date
    let entries: [WorkoutEntry]
    let weightUnit: String
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardHeader
            exerciseRows
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Workout", systemImage: "trash")
            }
        }
    }

    private var cardHeader: some View {
        HStack {
            Text(date, style: .date)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(entries.count) exercise\(entries.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var exerciseRows: some View {
        ForEach(entries) { entry in
            if let exerciseName = entry.exercise?.name {
                HStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 6, height: 6)
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
}
