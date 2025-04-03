//
//  TranscribeView.swift
//  AIProxyBootstrap
//
//  Created by Todd Hamilton
//

import AVFoundation
import SwiftData
import SwiftUI
import UIKit

@MainActor
struct TranscriberView: View {
    let transcriberManager: TranscriberManager
    @Environment(\.colorScheme) private var colorScheme

    var isRecording: Bool {
        transcriberManager.isRecording
    }

    @State private var showDot = false
    @State private var isPulsing = false
    @State private var isProcessing = false

    @State private var isTimerRunning = false
    @State private var startTime = Date()
    @State private var timerString = "0:00"
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var selectedRecording: TranscribedAudioRecording?

    private let startSFX: SystemSoundID = 1113
    private let stopSFX: SystemSoundID = 1114

    private let deviceWidth = UIScreen.main.bounds.width
    private let deviceHeight = UIScreen.main.bounds.height

    private var initialX: Double {
        deviceWidth / 2.0
    }
    private var midY: Double {
        -deviceHeight / 2.0 + 80
    }

    // Colors that adapt based on color scheme
    private var overlayGradientColors: [Color] {
        let baseColor = colorScheme == .dark ? Color.black : Color.white
        return [
            baseColor,
            baseColor.opacity(0.5),
            Color.clear,
        ]
    }

    private var recordButtonEffectColor: Color {
        colorScheme == .dark ? .primary : .secondary
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 12) {
                /// Show the recording detail view
                if selectedRecording != nil {
                    recordingDetailView
                } else {
                    /// Show the recording list
                    NavigationBar()
                    recordingListView
                }
            }
            .padding(.bottom, 100)  // Safe area bottom

            /// Show the recording overlay
            if isRecording {
                recordingOverlay
            }

            /// Show the bottom bar overlay
            if !isRecording {
                bottomBarOverlay
            }

            /// Show the record button
            Group {
                recordButtonEffect
                recordButton
            }
            .padding(.bottom, -30)
        }
        .onDisappear {
            // Stop any playing audio when view disappears
            transcriberManager.stopCurrentPlayback()
        }
        .onChange(of: UIApplication.shared.applicationState) { _, newState in
            if newState != .active {
                // Stop playback when app goes to background
                transcriberManager.stopCurrentPlayback()
            }
        }
    }

    @ViewBuilder
    private var recordingDetailView: some View {
        // Recording Detail View
        VStack(alignment: .leading, spacing: 12) {
            // Back button
            Button {
                self.selectedRecording = nil
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                        .font(.golosText(size: 16))
                }
                .foregroundColor(.blue)
                .padding(.horizontal)
            }

            if let selectedRecording = selectedRecording {
                RecordingRowView(
                    recording: selectedRecording,
                    transcriberManager: transcriberManager,
                    isDetailView: true
                )
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var recordingListView: some View {
        VStack(spacing: 8) {
            // Recordings list
            if transcriberManager.recordings.count > 0 {
                ScrollView {
                    LazyVStack {
                        ForEach(transcriberManager.recordings) { recording in
                            RecordingRowView(
                                recording: recording,
                                transcriberManager: transcriberManager,
                                onTap: {
                                    self.selectedRecording = recording
                                }
                            )
                            .contentShape(Rectangle())
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                self.transcriberManager.deleteRecording(at: index)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .zIndex(1)  // Ensure list is above other elements
            } else {
                NoRecordingsView()
                    .zIndex(1)
            }
        }
    }

    @ViewBuilder
    private var recordButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            /// Start  recording
            if !isRecording {
                Task {
                    await transcriberManager.startRecording()
                }
                AudioServicesPlaySystemSound(startSFX)
                timerString = "0.00"
                startTime = Date()
                // start UI updates
                self.startTimer()
                withAnimation(.smooth(duration: 0.75)) {
                    showDot = true
                }
                withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
                isTimerRunning = true
            } else {
                /// Stop recording
                Task {
                    await transcriberManager.stopRecording(duration: self.timerString)
                    withAnimation(.bouncy) {
                        isProcessing = false
                    }
                }

                AudioServicesPlaySystemSound(stopSFX)
                self.stopTimer()
                isTimerRunning = false
                withAnimation(.smooth(duration: 0.75)) {
                    showDot = false
                }
                withAnimation(.default) {
                    isProcessing = true
                    isPulsing = false
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: isRecording ? 8 : 45, style: .continuous)
                    .fill(.red.gradient)
                    .frame(width: isRecording ? 40 : 85, height: isRecording ? 40 : 85)
                    .opacity(isProcessing ? 0 : 1)
                if isRecording {
                    ProgressView()
                        .opacity(isProcessing ? 1.0 : 0)
                        .tint(.primary)
                        .colorScheme(colorScheme == .dark ? .dark : .light)
                } else {
                    Image(systemName: "waveform")
                        .font(.title)
                        .foregroundColor(.white)
                        .transition(.scale)
                }

            }
        }
        .buttonStyle(RecordButton())
        .disabled(isProcessing ? true : false)
        .zIndex(3)  // Button above gooey effect
    }

    @ViewBuilder
    private var recordButtonEffect: some View {
        GeometryReader { geometry in
            /// Gooey button effect
            Canvas { context, size in
                let circle0 = context.resolveSymbol(id: 0)!
                let circle1 = context.resolveSymbol(id: 1)!
                context.addFilter(.alphaThreshold(min: 0.25, color: recordButtonEffectColor))
                context.addFilter(.blur(radius: 15))
                context.drawLayer { context in
                    context.draw(circle0, at: CGPoint(x: initialX, y: geometry.size.height - 80))
                    context.draw(circle1, at: CGPoint(x: initialX, y: geometry.size.height - 80))
                }
            } symbols: {
                Circle()
                    .frame(width: 80, height: 80)
                    .scaleEffect(isProcessing ? 0.75 : 1, anchor: .center)
                    .tag(0)
                Circle()
                    .frame(width: 80, height: 80)
                    .tag(1)
                    .scaleEffect(showDot ? 1 : 0.5, anchor: .center)
                    .scaleEffect(isPulsing ? 1.15 : 1, anchor: .center)
                    .offset(y: showDot ? midY : 0)
            }
        }
        .allowsHitTesting(false)  // Ensure gooey effect doesn't block button
    }

    @ViewBuilder
    private var recordingOverlay: some View {
        ZStack {
            VStack(spacing: 4) {
                Text(isProcessing ? "Processing" : "Recording")
                    .font(.golosText(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Text(isProcessing ? "This may take a second" : "\(self.timerString)s")
                    .font(.golosText(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .onReceive(timer) { _ in
                        if self.isTimerRunning {
                            timerString = String(
                                format: "%.2f", (Date().timeIntervalSince(self.startTime)))
                        }
                    }
            }
            .offset(y: -140)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(.ultraThinMaterial)
        .transition(.opacity)
        .allowsHitTesting(false)  // Prevent overlay from blocking touches
        .zIndex(2)  // Overlay above list but not interactive
    }

    @ViewBuilder
    private var bottomBarOverlay: some View {
        let semiOpaque = colorScheme == .dark ? Color.black.opacity(0.5) : Color.white.opacity(0.5)
        let solid = colorScheme == .dark ? Color.black : Color.white

        return Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.4), location: 0.4),
                        .init(color: .black, location: 1.0),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: semiOpaque, location: 0.4),
                        .init(color: solid, location: 1.0),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .bottom)
            .blur(radius: 15)
            .ignoresSafeArea(edges: .bottom)
    }

    func stopTimer() {
        self.timer.upstream.connect().cancel()
    }

    func startTimer() {
        self.timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    }

    // Methods to handle recording
    private func startRecording() {
        Task {
            await transcriberManager.startRecording()
        }
        AudioServicesPlaySystemSound(startSFX)
        timerString = "0.00"
        startTime = Date()
        // start UI updates
        self.startTimer()
        withAnimation(.smooth(duration: 0.75)) {
            showDot = true
        }
        withAnimation(.smooth(duration: 0.75).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
        isTimerRunning = true
    }

    private func stopRecording() {
        Task {
            await transcriberManager.stopRecording(duration: self.timerString)
            withAnimation(.bouncy) {
                isProcessing = false
            }
        }

        AudioServicesPlaySystemSound(stopSFX)
        stopRecordingUI()
    }

    private func stopRecordingUI() {
        self.stopTimer()
        isTimerRunning = false
        withAnimation(.smooth(duration: 0.75)) {
            showDot = false
        }
        withAnimation(.default) {
            isProcessing = true
            isPulsing = false
        }
    }
}

#Preview {
    TranscriberView(transcriberManager: TranscriberManager())
}
