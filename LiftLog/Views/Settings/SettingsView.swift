import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @Environment(\.modelContext) private var context
    @State private var showingClearAlert = false
    @State private var showingClearSuccess = false

    var body: some View {
        NavigationStack {
            List {
                // Units
                Section {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("Pounds (lbs)").tag("lbs")
                        Text("Kilograms (kg)").tag("kg")
                    }
                } header: {
                    Label("Units", systemImage: "scalemass")
                } footer: {
                    Text("All weights will be displayed in the selected unit. This does not convert existing data.")
                }

                // Data Management
                Section {
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        Label("Clear Workout History", systemImage: "trash")
                    }
                } header: {
                    Label("Data", systemImage: "externaldrive")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Platform")
                        Spacer()
                        Text("iOS 17+")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Framework")
                        Spacer()
                        Text("SwiftUI + SwiftData")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }

                // Credits
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "dumbbell.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)
                        Text("LiftLog")
                            .font(.title2.weight(.bold))
                        Text("Track your lifts. Beat your PRs.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All History?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("This will permanently delete all workout entries and sets. Your exercises and routines will be kept.")
            }
            .alert("History Cleared", isPresented: $showingClearSuccess) {
                Button("OK") {}
            } message: {
                Text("All workout history has been deleted.")
            }
        }
    }

    private func clearHistory() {
        do {
            try context.delete(model: SetEntry.self)
            try context.delete(model: WorkoutEntry.self)
            try context.save()
            showingClearSuccess = true
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
}
