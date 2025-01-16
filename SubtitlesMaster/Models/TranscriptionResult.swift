import Foundation

struct TranscriptionResult: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double
    let confidence: Double
    
    init(text: String, startTime: Double, endTime: Double, confidence: Double = 1.0) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
    }
    
    static func == (lhs: TranscriptionResult, rhs: TranscriptionResult) -> Bool {
        return lhs.id == rhs.id
    }
}

// Мок для тестирования
extension TranscriptionResult {
    static let mockResults: [TranscriptionResult] = [
        TranscriptionResult(text: "Привет, это тестовое видео", startTime: 0.0, endTime: 2.0, confidence: 0.95),
        TranscriptionResult(text: "Мы используем его для проверки субтитров", startTime: 2.1, endTime: 4.5, confidence: 0.92),
        TranscriptionResult(text: "Надеюсь, всё работает правильно", startTime: 4.6, endTime: 6.8, confidence: 0.88)
    ]
} 