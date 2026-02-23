import SwiftUI

struct AddSetRow: View {
    let setNumber: Int
    @Binding var weight: String
    @Binding var reps: String
    @Binding var isWarmup: Bool
    var onComplete: () -> Void
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"

    @State private var isCompleted = false

    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(setNumber)")
                .font(.caption.weight(.bold))
                .frame(width: 24, height: 24)
                .background(isWarmup ? .yellow.opacity(0.2) : .accent.opacity(0.15))
                .foregroundStyle(isWarmup ? .orange : .accent)
                .clipShape(Circle())

            // Weight
            VStack(alignment: .leading, spacing: 1) {
                Text(weightUnit)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                TextField("0", text: $weight)
                    .keyboardType(.decimalPad)
                    .font(.body.monospacedDigit().weight(.medium))
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
            }

            // Reps
            VStack(alignment: .leading, spacing: 1) {
                Text("reps")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                TextField("0", text: $reps)
                    .keyboardType(.numberPad)
                    .font(.body.monospacedDigit().weight(.medium))
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
            }

            // Warmup toggle
            Button {
                isWarmup.toggle()
            } label: {
                Image(systemName: isWarmup ? "flame.fill" : "flame")
                    .font(.caption)
                    .foregroundStyle(isWarmup ? .orange : .quaternary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Complete button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isCompleted = true
                }
                onComplete()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .quaternary)
            }
            .buttonStyle(.plain)
            .disabled(isCompleted)
        }
        .padding(.vertical, 4)
    }
}
