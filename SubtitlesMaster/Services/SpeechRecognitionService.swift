import Foundation
import Speech

class SpeechRecognitionService {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))!
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func transcribeAudio(url: URL) async throws -> [TranscriptionResult] {
        guard await requestAuthorization() else {
            throw NSError(domain: "", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Нет разрешения на распознавание речи"])
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                // Преобразуем результаты в наш формат
                var transcriptionResults: [TranscriptionResult] = []
                
                for segment in result.bestTranscription.segments {
                    let transcription = TranscriptionResult(
                        text: segment.substring,
                        startTime: Double(segment.timestamp),
                        endTime: Double(segment.timestamp + segment.duration),
                        confidence: Double(segment.confidence)
                    )
                    transcriptionResults.append(transcription)
                }
                
                continuation.resume(returning: transcriptionResults)
            }
        }
    }
} 