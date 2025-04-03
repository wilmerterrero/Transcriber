//
//  RecordingRowView.swift
//  AIProxyBootstrap
//
//  Created by Todd Hamilton
//

import AVFoundation
import SwiftUI

struct RecordingRowView: View {
    let recording: TranscribedAudioRecording
    let transcriberManager: TranscriberManager

    var isDetailView: Bool = false
    var onTap: (() -> Void)? = nil

    @State private var startAnimation = false
    @State private var isPlaying = false
    @State private var isPressed = false
    @State private var playbackTimer: Timer?
    @State private var playbackProgress: Float = 0

    var body: some View {
        detailView
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
    }

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Timestamp
            Text(formattedDate(date: recording.createdAt))
                .font(.golosText(size: 12))
                .foregroundColor(.secondary)

            // Title
            Text("Recording")
                .font(.golosText(size: 16, weight: .medium))

            // Transcript
            Text(recording.transcript)
                .font(.golosText(size: 14))
                .lineLimit(isDetailView ? nil : 2)
                .padding(.vertical, 8)

            // Action Buttons
            HStack(alignment: .center) {
                Button {
                    if isPlaying {
                        pausePlayback()
                    } else {
                        startPlayback()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))

                        Text("\(recording.audioRecording.duration)s")
                            .font(.golosText(size: 14))
                    }
                }
                .buttonStyle(
                    CustomPlayButtonStyle(
                        isPlaying: isPlaying, isPressed: $isPressed, progress: playbackProgress)
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isPressed = false
                            }
                        }
                )

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        // Edit action would go here
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }

                    Menu {
                        Text("Create")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .disabled(true)

                        ForEach(
                            [
                                "summary-key": ("Summary", "pencil.and.outline"),
                                "meeting-report-key": ("Meeting report", "doc.text"),
                                "main-points-key": ("Main points", "list.bullet"),
                                "to-do-list-key": ("To-do list", "checklist"),
                                "translate-key": ("Translate", "character.bubble"),
                                "tweet-key": ("Tweet", "megaphone"),
                                "blog-post-key": ("Blog post", "square.and.pencil"),
                                "email-key": ("Email", "envelope"),
                                "cleanup-key": ("Cleanup", "eraser"),
                            ].sorted(by: { $0.key < $1.key }), id: \.key
                        ) { key, value in
                            Button {
                                handleOptionSelected(key)
                            } label: {
                                Label(value.0, systemImage: value.1)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .opacity(startAnimation ? 1 : 0)
        .offset(y: startAnimation ? 0 : -10)
        .onAppear {
            withAnimation(.smooth.delay(0.2)) {
                startAnimation = true
            }
            // Check if this recording is already playing
            isPlaying = transcriberManager.isCurrentlyPlaying(recording: recording)
            if isPlaying {
                startMonitoringPlayback()
            }
        }
        .onDisappear {
            stopPlayback()  // Ensure cleanup on disappear
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

    private func handleOptionSelected(_ option: String) {
        print("Selected option: \(option)")
        // Implement the actions for each option here
    }
}

struct CustomPlayButtonStyle: ButtonStyle {
    var isPlaying: Bool
    @Binding var isPressed: Bool
    var progress: Float

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isPlaying ? .white : Color.secondary)
            .padding(.leading, 4)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .background(
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Base background (gray capsule)
                        Capsule()
                            .fill(Color.secondary.opacity(0.14))
                            .frame(width: geometry.size.width, height: geometry.size.height)

                        // Progress background (blue capsule) that grows progressively
                        if isPlaying {
                            Capsule()
                                .fill(Color.blue.opacity(0.5))
                                .frame(
                                    width: max(
                                        0,
                                        min(
                                            geometry.size.width,
                                            geometry.size.width * CGFloat(progress))),
                                    height: geometry.size.height
                                )
                                .clipShape(Rectangle())  // Use a plain Rectangle as the shape
                        }
                    }
                }
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    VStack {
        RecordingRowView(
            recording: previewRecording(),
            transcriberManager: TranscriberManager()
        )
    }
    .padding()
}

private func previewRecording() -> TranscribedAudioRecording {
    let audioRecording = AudioRecording(
        localUrl: URL(fileURLWithPath: "/dev/null"),
        duration: "1.2s")
    return TranscribedAudioRecording(
        audioRecording: audioRecording,
        transcript: "hello world",
        createdAt: Date()
    )
}
