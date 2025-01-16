import SwiftUI
import PhotosUI
import AVKit

struct VideoPicker: View {
    @ObservedObject var videoManager: VideoPlayerManager
    @State private var isShowingPicker = false
    
    var body: some View {
        Button(action: { isShowingPicker = true }) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                Text("Выбрать видео")
                    .font(.headline)
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            PHPickerView(videoManager: videoManager, isPresented: $isShowingPicker)
        }
    }
}

struct PHPickerView: UIViewControllerRepresentable {
    @ObservedObject var videoManager: VideoPlayerManager
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let result = results.first else { return }
            
            Task {
                do {
                    let url = try await loadVideo(from: result)
                    await MainActor.run {
                        parent.videoManager.setVideo(url: url)
                    }
                } catch {
                    print("Ошибка загрузки видео: \(error.localizedDescription)")
                }
            }
        }
        
        private func loadVideo(from result: PHPickerResult) async throws -> URL {
            try await withCheckedThrowingContinuation { continuation in
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let url = url else {
                        continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL не найден"]))
                        return
                    }
                    
                    // Копируем файл во временную директорию
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(url.pathExtension)
                    
                    do {
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        continuation.resume(returning: tempURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

#Preview {
    VideoPicker(videoManager: VideoPlayerManager())
} 