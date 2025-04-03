//
//  TranscribedAudioRecording.swift
//  Transcriber
//
//  Created by Lou Zell
//

import AVFoundation
import Foundation
import SwiftData

/// Encapsulates a transcribed audio recording
@Model
final class TranscribedAudioRecording {
    @Relationship(deleteRule: .cascade) var audioRecording: AudioRecording
    let transcript: String
    let createdAt: Date
    @Transient var player: AVAudioPlayer?

    init(audioRecording: AudioRecording, transcript: String, createdAt: Date) {
        self.audioRecording = audioRecording
        self.transcript = transcript
        self.createdAt = createdAt
    }

    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }

    @discardableResult
    func play() -> Bool {
        guard let resolvedURL = self.audioRecording.resolvedURL else {
            AppLogger.error("The audio recording model does not have an associated audio file")
            return false
        }
        AppLogger.info("Playing file at \(resolvedURL), which exists? \(FileManager.default.fileExists(atPath: resolvedURL.path))")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            // If we already have a player, just resume playback
            if let player = self.player {
                player.play()
                return true
            } else {
                // Create a new player
                self.player = try AVAudioPlayer(contentsOf: resolvedURL)
                self.player?.play()
                return self.player != nil
            }
        } catch {
            AppLogger.error("Could not play audio file. Error: \(error.localizedDescription)")
            return false
        }
    }
    
    @discardableResult
    func pause() -> Bool {
        guard let player = self.player else {
            return false
        }
        
        if player.isPlaying {
            player.pause()
            return true
        }
        return false
    }
    
    @discardableResult
    func stop() -> Bool {
        guard let player = self.player else {
            return false
        }
        
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
            return true
        }
        return false
    }
    
    func currentProgress() -> Float {
        guard let player = self.player, player.duration > 0 else {
            return 0
        }
        
        return Float(player.currentTime / player.duration)
    }
    
    func duration() -> TimeInterval {
        return player?.duration ?? 0
    }
}
