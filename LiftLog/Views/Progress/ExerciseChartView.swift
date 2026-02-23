import SwiftUI
import Charts

struct ExerciseChartView: View {
    let exercise: Exercise
    @State private var selectedRange: DateRange = .month
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"

    enum DateRange: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case threeMonths = "3M"
        case all = "All"

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .week: return calendar.date(byAdding: .day, value: -7, to: .now)
            case .month: return calendar.date(byAdding: .month, value: -1, to: .now)
            case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: .now)
            case .all: return nil
            }
        }
    }

    private var filteredEntries: [WorkoutEntry] {
        let sorted = exercise.entries.sorted { $0.date < $1.date }
        guard let start = selectedRange.startDate else { return sorted }
        return sorted.filter { $0.date >= start }
    }

    private struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let maxWeight: Double
        let volume: Double // weight × reps summed across sets
    }

    private var chartData: [ChartDataPoint] {
        filteredEntries.map { entry in
            let maxW = entry.sets.map(\.weight).max() ?? 0
            let vol = entry.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            return ChartDataPoint(date: entry.date, maxWeight: maxW, volume: vol)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Date range picker
                Picker("Range", selection: $selectedRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if chartData.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.line.downtrend.xyaxis",
                        description: Text("Log workouts with \(exercise.name) to see your progress charts.")
                    )
                    .padding(.top, 40)
                } else {
                    // Max Weight Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max Weight")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(chartData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", point.maxWeight)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.accent)

                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", point.maxWeight)
                            )
                            .foregroundStyle(.accent)
                            .symbolSize(40)

                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", point.maxWeight)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.accent.opacity(0.1))
                        }
                        .chartYAxisLabel(weightUnit)
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    // Volume Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Volume (Weight × Reps)")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(chartData) { point in
                            BarMark(
                                x: .value("Date", point.date),
                                y: .value("Volume", point.volume)
                            )
                            .foregroundStyle(.accent.gradient)
                            .cornerRadius(4)
                        }
                        .chartYAxisLabel(weightUnit)
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    // Summary stats
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Summary")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 12) {
                            MiniStat(title: "Sessions", value: "\(chartData.count)")
                            MiniStat(title: "Best", value: "\(Int(chartData.map(\.maxWeight).max() ?? 0)) \(weightUnit)")
                            MiniStat(title: "Avg Volume", value: "\(Int(chartData.map(\.volume).reduce(0, +) / max(Double(chartData.count), 1)))")
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct MiniStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
