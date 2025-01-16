import AVFoundation

class AudioExtractor {
    func extractAudio(from videoURL: URL) async throws -> URL {
        print("AudioExtractor: Начинаем извлечение аудио из \(videoURL)")
        
        let asset = AVURLAsset(url: videoURL)
        
        // Загружаем аудиодорожки
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let audioTrack = audioTracks.first else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Аудиодорожка не найдена"])
        }
        
        // Создаем композицию
        let composition = AVMutableComposition()
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка создания композиции"])
        }
        
        // Вставляем аудиодорожку в композицию
        let duration = try await asset.load(.duration)
        try compositionTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: audioTrack,
            at: .zero
        )
        
        // Создаем временный URL для аудио файла
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("extracted_audio_\(Date().timeIntervalSince1970).m4a")
        
        // Проверяем и удаляем существующий файл
        try? FileManager.default.removeItem(at: outputURL)
        
        // Создаем и настраиваем сессию экспорта
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A  // Высокое качество
        ) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать сессию экспорта"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        // Экспортируем
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw exportSession.error ?? NSError(domain: "", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Ошибка экспорта"])
        }
        
        print("AudioExtractor: Аудио извлечено и сохранено как MP3: \(outputURL)")
        return outputURL
    }
} 