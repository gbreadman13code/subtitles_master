import Foundation
import Dispatch

@MainActor
class TranscriptionService: ObservableObject {
    @Published var results: [TranscriptionResult] = []
    private let revAI = RevAIService()
    
    func submitTranscriptionJob(audioURL: URL) async throws -> String {
        return try await revAI.submitTranscriptionJob(audioURL: audioURL)
    }
    
    func checkJobStatus(jobId: String) async throws -> String {
        return try await revAI.checkJobStatus(jobId: jobId)
    }
    
    func getTranscription(jobId: String) async throws -> [TranscriptionResult] {
        return try await revAI.getTranscription(jobId: jobId)
    }
} 