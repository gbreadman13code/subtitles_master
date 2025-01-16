import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let player: AVPlayer
    
    var body: some View {
        VideoPlayer(player: player)
            .background(Color.black)
    }
} 