import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }

            RoutinesListView()
                .tabItem {
                    Label("Routines", systemImage: "list.bullet.rectangle")
                }

            ExercisesListView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell")
                }

            StatsView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
