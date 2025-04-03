import SwiftUI
import AVFoundation

struct GooeyRecordButton: View {
    var isRecording: Bool
    var isProcessing: Bool
    var onTap: () -> Void
    
    var body: some View {
        ZStack {
            // Record button
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: isRecording ? 8 : 45, style: .continuous)
                        .fill(.red.gradient)
                        .frame(width: isRecording ? 40 : 85, height: isRecording ? 40 : 85)
                        .opacity(isProcessing ? 0 : 1)
                    
                    if isRecording {
                        ProgressView()
                            .opacity(isProcessing ? 1.0 : 0)
                            .tint(.primary)
                            .colorInvert()
                    } else {
                        Image(systemName: "waveform")
                            .font(.title)
                            .foregroundColor(.white)
                            .transition(.scale)
                    }
                }
            }
            .buttonStyle(RecordButton())
            .disabled(isProcessing)
        }
        .frame(width: 100, height: 100)  // Fixed dimensions for the component
    }
}

#Preview {
    GooeyRecordButton(
        isRecording: false,
        isProcessing: false,
        onTap: {}
    )
} 
