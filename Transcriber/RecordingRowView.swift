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
        VStack(alignment: .leading, spacing: 12) {
            // Title + Timestamp
            HStack {
                Text(generateSmartTitle(for: recording.transcript))
                    .font(.golosText(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                Text(formattedDate(date: recording.createdAt))
                    .font(.golosText(size: 12))
                    .foregroundColor(.secondary)
            }

            // Transcript Preview
            Text(recording.transcript)
                .font(.golosText(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(isDetailView ? nil : 3)
                .frame(maxWidth: .infinity, alignment: .leading)  // Force frame expansion and align content within frame
                .multilineTextAlignment(.leading)  // Explicitly align text lines to the left

            // Tags (AI-generated)
            if let tags = aiTags(for: recording.transcript) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Bottom Bar (play, edit, more)
            HStack {
                playButton

                Spacer()

                HStack(spacing: 16) {
                    Button {
                        // Edit action
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }

                    Menu {
                        ForEach(actionMenuItems, id: \.key) { key, value in
                            Text("Create")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .disabled(true)

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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var playButton: some View {
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
    }

    private var actionMenuItems: [(key: String, value: (String, String))] {
        return [
            "summary-key": ("Summary", "pencil.and.outline"),
            "meeting-report-key": ("Meeting report", "doc.text"),
            "main-points-key": ("Main points", "list.bullet"),
            "to-do-list-key": ("To-do list", "checklist"),
            "translate-key": ("Translate", "character.bubble"),
            "tweet-key": ("Tweet", "megaphone"),
            "blog-post-key": ("Blog post", "square.and.pencil"),
            "email-key": ("Email", "envelope"),
            "cleanup-key": ("Cleanup", "eraser"),
        ].sorted(by: { $0.key < $1.key })
    }

    private func generateSmartTitle(for transcript: String) -> String {
        // Extract a smart title from the transcript
        let words = transcript.components(separatedBy: .whitespacesAndNewlines)
        let wordLimit = 4

        if words.count <= wordLimit {
            return transcript
        } else {
            return words.prefix(wordLimit).joined(separator: " ") + "..."
        }
    }

    private func aiTags(for transcript: String) -> [String]? {
        // This now uses Faker to generate random tags for demo purposes
        // In production, you would use NLP to extract real topics from the transcript
        guard !transcript.isEmpty else { return nil }

        // Common categories of tags that might be relevant for transcripts
        let businessTags = ["meeting", "strategy", "planning", "followup", "interview", "call"]
        let personalTags = ["reminder", "idea", "thought", "note", "task", "daily"]
        let emotionTags = ["important", "urgent", "interesting", "review", "insight"]

        // Randomly select 2-3 tags from different categories
        var selectedTags = Set<String>()

        // Add 1 random business tag
        if let businessTag = businessTags.randomElement() {
            selectedTags.insert(businessTag)
        }

        // Maybe add a personal tag (50% chance)
        if Bool.random() {
            if let personalTag = personalTags.randomElement() {
                selectedTags.insert(personalTag)
            }
        }

        // Maybe add an emotion tag (70% chance)
        if Double.random(in: 0...1) < 0.7 {
            if let emotionTag = emotionTags.randomElement() {
                selectedTags.insert(emotionTag)
            }
        }

        return selectedTags.isEmpty ? nil : Array(selectedTags)
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
