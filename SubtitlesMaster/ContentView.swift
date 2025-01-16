//
//  ContentView.swift
//  SubtitlesMaster
//
//  Created by Илья Филонов on 15.01.2025.
//

import SwiftUI
import AVKit

@MainActor
struct ContentView: View {
    @StateObject private var videoManager = VideoPlayerManager()
    @StateObject private var transcriptionService = TranscriptionService()
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingProgress = false
    @State private var transcriptionStatus = "Подготовка..."
    @State private var transcriptionTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Верхняя панель с кнопками
                toolbar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Color(UIColor.systemGray6)
                            .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                    )
                
                // Блок видео
                if let player = videoManager.player {
                    VideoOverlayView(
                        player: player,
                        subtitles: $videoManager.subtitles
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                } else {
                    VideoPicker(videoManager: videoManager)
                        .frame(maxHeight: .infinity)
                }
                
                // Блок инструментов для субтитров
                if !videoManager.subtitles.isEmpty {
                    subtitleTools
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Color(UIColor.systemGray6)
                                .shadow(color: .black.opacity(0.1), radius: 1, y: -1)
                        )
                }
            }
            .preferredColorScheme(.dark)
        }
        .overlay {
            if showingProgress {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        TranscriptionProgressView(
                            status: transcriptionStatus,
                            onCancel: cancelTranscription
                        )
                    }
            }
        }
    }
    
    // Верхняя панель инструментов
    private var toolbar: some View {
        HStack(spacing: 16) {
            if !videoManager.subtitles.isEmpty {
                // Если есть субтитры
                Button(action: exportSubtitles) {
                    Label("Экспортировать", systemImage: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: clearVideo) {
                    Label("Удалить", systemImage: "trash")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
            } else if videoManager.player != nil {
                // Если есть видео, но нет субтитров
                AsyncButton {
                    await startTranscription()
                } label: {
                    Label("Распознать", systemImage: "waveform")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: clearVideo) {
                    Label("Удалить", systemImage: "trash")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    @MainActor
    private func startTranscription() async {
        guard let player = videoManager.player else { return }
        
        showingProgress = true
        transcriptionStatus = "Извлекаем аудио"
        
        do {
            // Извлекаем аудио
            let audioExtractor = AudioExtractor()
            let audioURL = try await audioExtractor.extractAudio(from: (player.currentItem?.asset as? AVURLAsset)?.url ?? URL(fileURLWithPath: ""))
            
            try Task.checkCancellation()
            transcriptionStatus = "Отправляем на распознавание"
            let jobId = try await transcriptionService.submitTranscriptionJob(audioURL: audioURL)
            
            try Task.checkCancellation()
            transcriptionStatus = "Распознаем текст"
            var status = "in_progress"
            while status == "in_progress" {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                try Task.checkCancellation()
                status = try await transcriptionService.checkJobStatus(jobId: jobId)
            }
            
            try Task.checkCancellation()
            transcriptionStatus = "Получаем результаты"
            let results = try await transcriptionService.getTranscription(jobId: jobId)
            
            try Task.checkCancellation()
            transcriptionStatus = "Обрабатываем субтитры"
            transcriptionService.results = results
            videoManager.updateSubtitles(results)
        } catch is CancellationError {
            transcriptionStatus = "Операция отменена"
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        } catch {
            transcriptionStatus = "Ошибка: \(error.localizedDescription)"
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        showingProgress = false
    }
    
    private func cancelTranscription() {
        transcriptionTask?.cancel()
    }
    
    private func clearVideo() {
        videoManager.player = nil
        videoManager.subtitles = []
        transcriptionService.results = []
    }
    
    private func exportSubtitles() {
        // TODO: Добавить экспорт субтитров
    }
    
    // Инструменты для работы с субтитрами
    private var subtitleTools: some View {
        HStack(spacing: 16) {
            Button(action: { /* Редактировать */ }) {
                Label("Редактировать", systemImage: "pencil")
                    .font(.system(size: 15, weight: .medium))
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button(action: { /* Настройки отображения */ }) {
                Label("Настройки", systemImage: "gear")
                    .font(.system(size: 15, weight: .medium))
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ContentView()
}

