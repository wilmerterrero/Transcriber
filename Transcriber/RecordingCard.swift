import SwiftUI
import AVFoundation

struct RecordingCard: View {
    let recording: TranscribedAudioRecording
    let transcriberManager: TranscriberManager
    
    @State private var isPlaying = false
    @State private var playbackTimer: Timer?
    @State private var playbackProgress: Float = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Timestamp
            Text(formattedDate(date: recording.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Title
            Text("Recording")
                .font(.headline)
                .fontWeight(.bold)
            
            // Transcript
            Text(recording.transcript)
                .font(.body)
                .padding(.vertical, 8)
            
            // Audio Player
            HStack(spacing: 6) {
                Button {
                    if isPlaying {
                        pausePlayback()
                    } else {
                        startPlayback()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .buttonStyle(TranscriptionButtonStyle(isPlaying: isPlaying))
                
                Text(recording.audioRecording.duration)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Spacer()
                
                Button {
                    // Edit action would go here
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                
                Button {
                    // More options action would go here
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onAppear {
            // Check if this recording is already playing
            isPlaying = transcriberManager.isCurrentlyPlaying(recording: recording)
            if isPlaying {
                startMonitoringPlayback()
            }
        }
        .onDisappear {
            stopPlayback() // Ensure cleanup on disappear
        }
    }
    
    private func formattedDate(date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today · \(formattedTime(date: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday · \(formattedTime(date: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "\(formatter.string(from: date)) · \(formattedTime(date: date))"
        }
    }
    
    private func formattedTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func startPlayback() {
        // Invalidate any existing timer
        playbackTimer?.invalidate()
        
        // Use the manager to start playback and ensure only one plays at a time
        let success = transcriberManager.startPlayback(recording: recording)
        isPlaying = success
        
        if success {
            startMonitoringPlayback()
        }
    }
    
    private func startMonitoringPlayback() {
        // Start monitoring playback progress
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Update playback progress
            self.playbackProgress = self.recording.currentProgress()
            
            // Check if playback has ended
            if !self.recording.isPlaying && self.isPlaying {
                self.isPlaying = false
                self.playbackProgress = 0
                self.playbackTimer?.invalidate()
            }
        }
    }
    
    private func pausePlayback() {
        if transcriberManager.pausePlayback(recording: recording) {
            isPlaying = false
            playbackTimer?.invalidate()
        }
    }
    
    private func stopPlayback() {
        transcriberManager.stopCurrentPlayback()
        isPlaying = false
        playbackProgress = 0
        playbackTimer?.invalidate()
    }
}

#Preview {
    RecordingCard(
        recording: previewRecording(),
        transcriberManager: TranscriberManager()
    )
}

private func previewRecording() -> TranscribedAudioRecording {
    let audioRecording = AudioRecording(localUrl: URL(fileURLWithPath: "/dev/null"),
                                         duration: "00:26")
    return TranscribedAudioRecording(
        audioRecording: audioRecording,
        transcript: "Ok, I will mix Spanish and English in this note since I'm bilingual...",
        createdAt: Date()
    )
} 