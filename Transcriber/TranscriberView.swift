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

    // Navigation path state
    @State private var navigationPath: [TranscribedAudioRecording] = []

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

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

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

    private var recordButtonEffectColor: Color {
        colorScheme == .dark ? .primary : .secondary
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // --- Main Content Area with Navigation ---
            NavigationStack(path: $navigationPath) {
                recordingListView  // Root view of the NavigationStack
                    .navigationDestination(for: TranscribedAudioRecording.self) { recording in
                        // Destination view when a recording is tapped
                        recordingDetailView(recording: recording)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("yvo")
                                .font(.logoText(size: 43))
                                .foregroundColor(.red)
                                .padding(.top, 12)
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack(spacing: 16) {
                                Button {
                                    // Handle grid button action here
                                } label: {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16))
                                        .foregroundColor(textColor)
                                }
                                
                                Button {
                                    // Handle settings button action here
                                } label: {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 16))
                                        .foregroundColor(textColor)
                                }
                            }
                            .padding(.trailing)
                        }
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: 15)
                            
                            HStack(spacing: 12) {
                                // Main search container
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                        .opacity(0.8)
                                    
                                    TextField("Search", text: $searchText)
                                        .font(.golosText(size: 18))
                                        .submitLabel(.search)
                                        .focused($isSearchFocused)
                                    
                                    if !searchText.isEmpty {
                                        Button {
                                            searchText = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .frame(height: 45)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                                
                                // Cancel button (outside the search container)
                                if isSearchFocused {
                                    Button {
                                        isSearchFocused = false
                                    } label: {
                                        Text("Cancel")
                                            .foregroundColor(.accentColor)
                                            .font(.golosText(size: 16))
                                    }
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                            .animation(.spring(response: 0.3), value: isSearchFocused)
                            .padding(.horizontal)
                            
                            Spacer()
                                .frame(height: 15)
                        }
                        .background(Color(.systemBackground))
                    }
                    // Remove the default navigation title visibility
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }

            // Show the bottom bar overlay (only when not recording)
            if !isRecording {
                bottomBarOverlay
            }

            // Show the action buttons (only on recording list - when path is empty)
            if navigationPath.isEmpty {  // Show only when at the root list view
                Group {
                    actionButtonsEffect
                    actionButtons
                }
                .padding(.bottom, -30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.7), value: navigationPath.isEmpty
                )
                .zIndex(3)  // Ensure button and effect are above overlays
            }
        }
        .onAppear {
            stopTimer()  // Ensure timer is stopped initially
        }
        .onDisappear {
            // Stop any playing audio when view disappears
            transcriberManager.stopCurrentPlayback()
            stopTimer()  // Stop timer if view disappears while recording
        }
        .onChange(of: UIApplication.shared.applicationState) { _, newState in
            if newState != .active {
                // Stop playback when app goes to background
                transcriberManager.stopCurrentPlayback()
                // Optionally stop recording if needed when backgrounded
                // if isRecording { stopRecording() }
            }
        }
    }

    // --- Subviews ---

    // Detail view is now a standalone view function receiving the recording
    @ViewBuilder
    private func recordingDetailView(recording: TranscribedAudioRecording) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // NavigationStack provides the back button automatically
            RecordingRowView(
                recording: recording,
                transcriberManager: transcriberManager,
                isDetailView: true  // Keep this if RecordingRowView uses it for styling/layout
            )
            Spacer()  // Push content to the top
        }
        .padding(.horizontal)  // Add padding if needed for the detail content
        .navigationTitle(formattedDate(recording.createdAt))  // Example: Set detail view title
        .navigationBarTitleDisplayMode(.inline)  // Optional: Adjust title display
        .onDisappear {
            // Stop playback specifically when navigating *away* from this detail view
            transcriberManager.stopCurrentPlayback()
        }
    }

    @ViewBuilder
    private var recordingListView: some View {
        VStack(spacing: 0) {
            if transcriberManager.recordings.isEmpty {
                NoRecordingsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(transcriberManager.recordings.enumerated()), id: \.element.id)
                        { index, recording in
                            let isLastElement = index == transcriberManager.recordings.count - 1

                            RecordingRowView(
                                recording: recording,
                                transcriberManager: transcriberManager,
                                isDetailView: false,
                                onTap: {
                                    navigationPath.append(recording)
                                }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                            .padding(.bottom, isLastElement ? 100 : 0)  // Add extra padding for last element
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(alignment: .center, spacing: 20) {
            if !isRecording {
                askAIButton
            }
            recordButton
            if !isRecording {
                createNoteButton
            }
        }
    }

    @ViewBuilder
    private var recordButton: some View {
        Button {
            handleRecordButtonTap()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: isRecording ? 8 : 45, style: .continuous)
                    .fill(.red.gradient)
                    .frame(width: isRecording ? 40 : 85, height: isRecording ? 40 : 85)
                    .opacity(isProcessing ? 0 : 1)

                if isProcessing {  // Show ProgressView centered when processing
                    ProgressView()
                        .tint(colorScheme == .dark ? .white : .black)  // Ensure visibility
                } else if isRecording {
                    // Keep the square shape while recording, but empty inside (matching original logic)
                    // If you want an icon *during* recording (e.g., stop square), add it here.
                } else {
                    Image(systemName: "waveform")  // Mic icon when ready to record
                        .font(.title)
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            // Apply animation to the ZStack contents for smoother transitions
            .animation(.smooth(duration: 0.3), value: isRecording)
            .animation(.smooth(duration: 0.3), value: isProcessing)
        }
        .buttonStyle(ActionButton())
        .disabled(isProcessing)  // Disable button only while processing spinner is shown
        // Removed .zIndex(4) - Handled by the Group's zIndex
    }

    @ViewBuilder
    private var createNoteButton: some View {
        BaseButton(action: {}, label: "Note", icon: "pencil", color: .gray)
    }

    @ViewBuilder
    private var askAIButton: some View {
        BaseButton(action: {}, label: "Ask", icon: "sparkles", color: .purple)
    }

    @ViewBuilder
    private var actionButtonsEffect: some View {
        Canvas { context, size in
            // Ensure drawing calculations use the actual size from GeometryReader
            let drawCenter = CGPoint(x: size.width / 2, y: size.height - 80)

            guard let circle0 = context.resolveSymbol(id: 0),
                let circle1 = context.resolveSymbol(id: 1)
            else {
                return
            }

            context.addFilter(.alphaThreshold(min: 0.25, color: recordButtonEffectColor))
            context.addFilter(.blur(radius: 15))
            context.drawLayer { ctx in
                ctx.draw(circle0, at: drawCenter)
                ctx.draw(circle1, at: drawCenter)
            }
        } symbols: {
            // Base circle matching the button's resting state
            Circle()
                .frame(width: 85, height: 85)  // Match resting button size
                .scaleEffect(isProcessing ? 0.75 : 1, anchor: .center)  // Shrink when processing
                .tag(0)

            // Animated circle for the gooey effect
            Circle()
                .frame(width: 85, height: 85)  // Match resting button size
                .tag(1)
                .scaleEffect(showDot ? 1 : 0.5, anchor: .center)  // Scale based on recording state
                .scaleEffect(isPulsing ? 1.15 : 1, anchor: .center)  // Pulsate when recording
                .offset(y: showDot ? midY : 0)  // Move up when recording
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Allow canvas to fill space for positioning
        .allowsHitTesting(false)
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
                        guard isTimerRunning else { return }
                        timerString = String(format: "%.2f", Date().timeIntervalSince(startTime))
                    }
            }
            .offset(y: -140)  // Adjust offset as needed based on layout changes
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(.ultraThinMaterial)
        .transition(.opacity)
        .allowsHitTesting(false)
        .zIndex(2)  // Ensure overlay is above NavigationStack content but below button
    }

    @ViewBuilder
    private var bottomBarOverlay: some View {
        let semiOpaque = colorScheme == .dark ? Color.black.opacity(0.5) : Color.white.opacity(0.4)
        let solid = colorScheme == .dark ? Color.black : Color.white

        Group {
            if colorScheme == .dark {
                Rectangle()
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
            } else {
                // Light mode approach with softer transitions
                Rectangle()
                    .fill(Color.white.opacity(0.01))  // Very subtle base fill
                    .background(
                        // Use a blur for softness instead of sharp edges
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .blur(radius: 5)
                    )
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.1), location: 0.2),  // Very soft start
                                .init(color: .black.opacity(0.4), location: 0.5),  // Gradual middle
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
                                .init(color: .clear, location: 0.1),  // Extended clear area
                                .init(color: semiOpaque.opacity(0.3), location: 0.5),  // Lower opacity, moved down
                                .init(color: solid.opacity(0.7), location: 1.0),  // Reduced opacity
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .frame(height: 135)
        .frame(maxWidth: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }

    // --- Helper Functions ---

    // Combined start/stop logic into one handler
    private func handleRecordButtonTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if !isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }

    private func startRecording() {
        print("UI: Start Recording")
        // Update Manager State
        Task {
            await transcriberManager.startRecording()
        }

        // Play SFX
        AudioServicesPlaySystemSound(startSFX)

        // Reset Timer
        timerString = "0.00"
        startTime = Date()
        startTimer()  // Activate the timer publisher

        // Start UI Animations
        withAnimation(.smooth(duration: 0.75)) {
            showDot = true  // Trigger gooey effect up-movement
        }
        // Use a separate animation state for pulsing to avoid conflicts
        isPulsing = true  // Will be picked up by the repeating animation modifier

        // Update Recording State Flag
        isTimerRunning = true  // Let the timer update the string
        // isRecording is derived from transcriberManager.isRecording
    }

    private func stopRecording() {
        print("UI: Stop Recording")
        let currentDuration = String(format: "%.2f", Date().timeIntervalSince(startTime))

        // Stop Timer & UI Updates First
        stopTimer()  // Deactivate the timer publisher
        isTimerRunning = false  // Prevent further updates from any stray timer events

        // Trigger Processing State & Animations
        withAnimation(.smooth(duration: 0.3)) {  // Short animation for processing state
            isProcessing = true
            showDot = false  // Trigger gooey effect down-movement
        }
        isPulsing = false  // Stop pulsing animation

        // Update Manager State (asynchronously)
        Task {
            await transcriberManager.stopRecording(duration: currentDuration)
            // Once manager confirms done, stop processing UI
            withAnimation(.bouncy) {
                isProcessing = false
            }
        }

        // Play SFX
        AudioServicesPlaySystemSound(stopSFX)
    }

    // Renamed from stopRecordingUI to avoid confusion with the main stopRecording action
    func stopTimer() {
        print("UI: Stopping Timer")
        self.timer.upstream.connect().cancel()
        isTimerRunning = false
    }

    func startTimer() {
        print("UI: Starting Timer")
        // Recreate the publisher to ensure it starts fresh
        self.timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
        isTimerRunning = true
    }

    // Helper for formatting date in navigation title
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .safeAreaInsets ?? .zero
    }

    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

// MARK: - Custom Shape for Specific Rounded Corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct BaseButton: View {
    let action: () -> Void
    let label: String
    let icon: String
    let color: Color
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Text(label)
                    .font(.golosText(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 55, height: 55)
            .background(
                RoundedRectangle(cornerRadius: 27.5)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(ActionButton())
    }
}

#Preview {
    TranscriberView(transcriberManager: TranscriberManager())
}
