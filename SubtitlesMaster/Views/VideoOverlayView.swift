import SwiftUI
import AVKit

struct VideoOverlayView: View {
    let player: AVPlayer
    @Binding var subtitles: [SubtitleItem]
    @State private var currentTime: Double = 0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Видеоплеер
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                
                // Субтитры
                VStack {
                    Spacer()
                    SubtitlesView(currentSubtitles: getCurrentSubtitles())
                        .padding(.bottom, 30)
                }
            }
        }
        .background(Color.black)
        .onReceive(timer) { _ in
            currentTime = player.currentTime().seconds
        }
    }
    
    private func getCurrentSubtitles() -> [SubtitleItem] {
        return subtitles.filter { $0.shouldDisplay(at: currentTime) }
    }
}

struct SubtitlesView: View {
    let currentSubtitles: [SubtitleItem]
    
    var body: some View {
        VStack {
            ForEach(currentSubtitles) { subtitle in
                Text(subtitle.text)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut, value: currentSubtitles)
    }
} 