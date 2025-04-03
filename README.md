# Transcriber

A SwiftUI app that records audio and uses OpenAI's Whisper model to transcribe it to text.

![Transcriber App Preview](https://via.placeholder.com/800x450.png?text=Transcriber+App+Preview)

## Features

- 🎙️ **Record Audio**: Simple interface to record voice memos
- 🤖 **AI Transcription**: Converts speech to text using OpenAI's Whisper model
- 📝 **View Transcripts**: Review and manage your transcribed recordings
- 🔊 **Playback**: Listen to your recorded audio files
- 🔄 **Persistent Storage**: All recordings and transcriptions are saved between app sessions

## Technical Details

### Architecture

The app follows a clean architecture with clear separation of concerns:

- **UI Layer**: SwiftUI views and components
- **Business Logic**: Manager classes coordinating app functionality
- **Data Layer**: SwiftData models for persistence
- **Utilities**: Helper classes for audio processing and file management

### Dependencies

- **SwiftUI**: UI framework
- **SwiftData**: Persistence framework
- **AVFoundation**: Audio recording and playback
- **AIProxy**: Integration with OpenAI's API

### Key Components

- `TranscriberView`: Main view with recording UI and list of transcriptions
- `TranscriberManager`: Central coordinator handling recording and transcription
- `AudioRecorder`: Handles audio recording functionality
- `TranscriberDataLoader`: Interfaces with OpenAI for transcription
- `AudioRecording` & `TranscribedAudioRecording`: SwiftData models

## Getting Started

### Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- An OpenAI API key or AIProxy account

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/transcriber.git
   cd transcriber
   ```

2. Open the project in Xcode
   ```bash
   open Transcriber.xcodeproj
   ```

3. Set up your OpenAI API key
   - Open `AppConstants.swift`
   - Update the `openAIService` with your API key details

4. Build and run the app

## Usage

1. **Record Audio**: Tap the red record button to start recording
2. **Stop Recording**: Tap the button again to stop recording
3. **Processing**: Wait for the AI to transcribe your audio
4. **View Transcription**: See your transcribed text in the list
5. **Playback**: Tap on a recording to play back the audio
6. **Delete**: Swipe left on a recording to delete it

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details

## Acknowledgments

- OpenAI for the Whisper speech-to-text model
- The SwiftUI and SwiftData teams for the powerful frameworks 