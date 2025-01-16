import SwiftUI

struct TranscriptionProgressView: View {
    let status: String
    let onCancel: () -> Void
    @State private var dots = ""
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(status + dots)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button(action: onCancel) {
                Text("Отменить")
                    .foregroundColor(.red)
                    .font(.system(size: 15, weight: .medium))
            }
            .buttonStyle(.bordered)
        }
        .frame(width: 250)
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
        )
        .onReceive(timer) { _ in
            if dots.count >= 3 {
                dots = ""
            } else {
                dots += "."
            }
        }
    }
} 