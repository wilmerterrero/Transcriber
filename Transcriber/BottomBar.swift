import SwiftUI

struct BottomBar: View {
    var onAskAITap: () -> Void
    var onNoteTap: () -> Void
    var onRecordTap: () -> Void
    var isRecording: Bool
    var isProcessing: Bool
    
    var body: some View {
        ZStack {
            // Background buttons row
            HStack(spacing: 12) {
                Button(action: onAskAITap) {
                    Text("Ask AI")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                        )
                        .foregroundColor(.primary)
                }
                
                // Spacer for the record button
                Spacer()
                    .frame(width: 100)
                
                Button(action: onNoteTap) {
                    Text("Note")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                        )
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Gooey button positioned in the center
            HStack {
                Spacer()
                GooeyRecordButton(
                    isRecording: isRecording,
                    isProcessing: isProcessing,
                    onTap: {
                        // We'll pass through the tap to the parent's handler
                        onRecordTap()
                    }
                )
                .offset(y: -30) // Raise the button above the other buttons
                Spacer()
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        BottomBar(
            onAskAITap: {},
            onNoteTap: {},
            onRecordTap: {},
            isRecording: false,
            isProcessing: false
        )
    }
} 
