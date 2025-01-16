import AVFoundation
import SwiftUI

@MainActor
class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    @Published var subtitles: [SubtitleItem] = []
    
    func setVideo(url: URL) {
        player = AVPlayer(url: url)
    }
    
    func updateSubtitles(_ transcriptionResults: [TranscriptionResult]) {
        subtitles = transcriptionResults.map { result in
            SubtitleItem(
                text: result.text,
                startTime: result.startTime,
                endTime: result.endTime
            )
        }
    }
} 