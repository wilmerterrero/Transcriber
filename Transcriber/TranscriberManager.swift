//
//  TranscriberManager.swift
//  AIProxyBootstrap
//
//  Created by Lou Zell
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class TranscriberManager {

    private(set) var isRecording = false
    private let audioRecorder = AudioRecorder()
    private let transcriber = TranscriberDataLoader()
    private let modelContext: ModelContext
    var recordings = [TranscribedAudioRecording]()
    
    // Track the currently playing recording
    private(set) var currentlyPlayingRecording: TranscribedAudioRecording?
    
    init() {
        let context = AppConstants.swiftDataContainer.mainContext
        self.recordings = fetchPersistedRecordings(context)
        self.modelContext = context
    }

    /// This pollutes the manager a bit.
    /// I wrote of a better way to do this, here: https://stackoverflow.com/a/77772091/143447
    /// - Parameter newValue: The value to set `isRecording` to
    private func setIsRecording(_ newValue: Bool) {
        withAnimation(.smooth(duration: 0.75)) {
            self.isRecording = newValue
        }
    }

    /// Start recording an audio file
    func startRecording() async {
        self.setIsRecording(await self.audioRecorder.start())
        if !self.isRecording {
            AppLogger.error("Could not start the audio recorder")
        }
    }

    /// Stop recording the audio file and transcribe it to text with Whisper
    /// - Parameter duration: Annotate the audio file with this duration.
    func stopRecording(duration: String) async {
        if let recording = await self.audioRecorder.stopRecording(duration: duration) {
            let transcript = await self.transcriber.run(onRecording: recording)
            let transcribed = TranscribedAudioRecording(audioRecording: recording, transcript: transcript, createdAt: Date())
            self.modelContext.insert(transcribed)
            self.recordings = fetchPersistedRecordings(self.modelContext)
        }
        self.setIsRecording(false)
    }

    /// Removes a recording from persistent storage and deletes the associated audio file from disk
    /// - Parameter index: the index in `recordings` to delete
    func deleteRecording(at index: Int) {
        FileUtils.deleteFile(at: self.recordings[index].audioRecording.localUrl)
        self.modelContext.delete(self.recordings[index])
        self.recordings = fetchPersistedRecordings(self.modelContext)
    }
    
    /// Start playing a recording, ensuring no other recordings are playing
    func startPlayback(recording: TranscribedAudioRecording) -> Bool {
        // Stop any currently playing recording
        stopCurrentPlayback()
        
        // Set the new currently playing recording and play it
        let success = recording.play()
        if success {
            currentlyPlayingRecording = recording
        }
        return success
    }
    
    /// Pause the currently playing recording
    func pausePlayback(recording: TranscribedAudioRecording) -> Bool {
        guard currentlyPlayingRecording == recording else { return false }
        
        let success = recording.pause()
        if success {
            currentlyPlayingRecording = nil
        }
        return success
    }
    
    /// Stop any currently playing recording
    func stopCurrentPlayback() {
        if let playingRecording = currentlyPlayingRecording {
            _ = playingRecording.stop()
            currentlyPlayingRecording = nil
        }
    }
    
    /// Check if a specific recording is the one currently playing
    func isCurrentlyPlaying(recording: TranscribedAudioRecording) -> Bool {
        return currentlyPlayingRecording == recording && recording.isPlaying
    }
}

private func fetchPersistedRecordings(_ modelContext: ModelContext) -> [TranscribedAudioRecording] {
    do {
        let descriptor = FetchDescriptor<TranscribedAudioRecording>(
            sortBy: [SortDescriptor(\TranscribedAudioRecording.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    } catch {
        AppLogger.error("Could not fetch audio recordings with SwiftData")
        return []
    }
}
