import SwiftUI

struct RecordingControls: View {
    var timerValue: String
    var onCancelTap: () -> Void
    var onPauseTap: () -> Void
    var onDoneTap: () -> Void
    var isPaused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onCancelTap) {
                Text("Cancel")
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .strokeBorder(Color.red, lineWidth: 1)
                    )
            }
            
            Text(timerValue)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            
            Button(action: onPauseTap) {
                Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.primary)
            }
            
            Button(action: onDoneTap) {
                Text("Done")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    RecordingControls(
        timerValue: "00:19",
        onCancelTap: {},
        onPauseTap: {},
        onDoneTap: {},
        isPaused: false
    )
} 