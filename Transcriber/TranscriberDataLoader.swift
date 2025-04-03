//
//  TranscriberDataLoader.swift
//  AIProxyBootstrap
//
//  Created by Lou Zell
//

import Foundation
import AIProxy
import Fakery

/// Interfaces with OpenAI to convert a recording into a transcript
final actor TranscriberDataLoader {
    
    /// Run the OpenAI transcriber on an audio recording
    /// - Parameter recording: the audio recording to transcribe
    /// - Returns: a transcript of the recording created by OpenAI's Whisper model
    func run(onRecording recording: AudioRecording) async -> String {
        do {
            let requestBody = OpenAICreateTranscriptionRequestBody(
                file: try Data(contentsOf: recording.localUrl),
                model: "whisper-1"
            )
            let response = try await AppConstants.openAIService.createTranscriptionRequest(body: requestBody)
            return response.text
        } catch {
            AppLogger.error("Could not get transcript from OpenAI: \(error.localizedDescription)")
            return "Transcription Error"
        }
    }
}

/// Fake implementation of the transcriber service for debug builds
final actor FakeTranscriberService: TranscriberService {
    private let faker = Faker()
    
    func run(onRecording recording: AudioRecording) async -> String {
        // Generate a realistic looking transcript using Fakery
        // Simulate different lengths of transcripts based on recording duration
        let durationStr = recording.duration
        var paragraphCount = 3
        
        // Crude approximation - longer recordings get more paragraphs
        if let durationInSecs = Double(durationStr.replacingOccurrences(of: "s", with: "")) {
            paragraphCount = min(10, max(1, Int(durationInSecs / 5)))
        }
        
        // Generate a realistic looking transcript
        let transcript = faker.lorem.paragraphs(amount: paragraphCount)
        
        // Simulate network delay (0.5-1.5 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
        
        AppLogger.info("Generated fake transcript with \(paragraphCount) paragraphs")
        return transcript
    }
}

/// Protocol defining the transcription service interface
protocol TranscriberService {
    func run(onRecording recording: AudioRecording) async -> String
}

extension TranscriberDataLoader: TranscriberService {}
