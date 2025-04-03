//
//  AppConstants.swift
//  AIProxyBootstrap
//
//  Created by Lou Zell
//

import Foundation
import SwiftData
import AIProxy

/// Use this actor for audio work
@globalActor actor AudioActor {
    static let shared = AudioActor()
}

enum AppConstants {

    static let swiftDataModels: [any PersistentModel.Type] = [AudioRecording.self, TranscribedAudioRecording.self]
    static let swiftDataContainer = try! ModelContainer(for: AudioRecording.self, TranscribedAudioRecording.self)

    static let audioSampleQueue = DispatchQueue(label: "com.AIProxyBootstrap.audioSampleQueue")

    /* Uncomment for BYOK use cases */
    static let openAIService = AIProxy.openAIService(
        partialKey: "v2|c198a9e0|ALgbQxBXmKWLyIcC",
        serviceURL: "https://api.aiproxy.pro/4ea46bb6/cbcbab3b"
    )
}
