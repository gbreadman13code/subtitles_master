import Foundation

class RevAIService {
    private let apiKey = "02nR5rljsPP3kEockX-Jr-Ai46pgyq73HVtqK4-FU6hB23nSC-IzUSuwAnW2aHciRoS_QhIBsgBXCYk7ufozYAlHfC9FE"
    private let baseURL = "https://api.rev.ai/speechtotext/v1"
    
    private func logRequest(_ request: URLRequest, body: Data? = nil) {
        print("\n=== ЗАПРОС ===")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")
        print("Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        if let body = body {
            print("\nBody size: \(body.count) bytes")
            if let preview = String(data: body.prefix(1000), encoding: .utf8) {
                print("Body preview (first 1000 bytes):")
                print(preview)
            }
        }
        print("=============")
    }
    
    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        print("\n=== ОТВЕТ ===")
        print("Status: \(response.statusCode)")
        print("Headers:")
        response.allHeaderFields.forEach { key, value in
            print("  \(key): \(value)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("\nBody:")
            print(responseString)
        }
        print("============")
    }
    
    /// Отправляет аудиофайл на транскрибацию
    /// POST /speechtotext/v1/jobs
    func submitTranscriptionJob(audioURL: URL) async throws -> String {
        print("\nRevAI: Отправляем аудиофайл на транскрибацию")
        print("Аудиофайл: \(audioURL)")
        
        let submitURL = URL(string: "\(baseURL)/jobs")!
        var request = URLRequest(url: submitURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Параметры запроса в JSON
        let options: [String: Any] = [
            "language": "ru",
            "skip_diarization": true,  // должен быть boolean, не string
        ]
        
        print("Параметры запроса:")
        options.forEach { key, value in
            print("  \(key): \(value)")
        }
        
        var body = Data()
        
        // Добавляем JSON с параметрами
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"options\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        let jsonData = try JSONSerialization.data(withJSONObject: options)
        body.append(jsonData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Добавляем файл
        let audioData = try Data(contentsOf: audioURL)
        print("Размер аудиофайла: \(audioData.count) bytes")
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"media\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Логируем запрос
        logRequest(request, body: body)
        
        // Отправляем
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный тип ответа"])
        }
        
        // Логируем ответ
        logResponse(httpResponse, data: data)
        
        guard httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let jobId = json["id"] as? String else {
            throw NSError(domain: "", code: httpResponse.statusCode, 
                         userInfo: [NSLocalizedDescriptionKey: "Ошибка создания задания"])
        }
        
        // Проверяем язык
        if let language = json["language"] as? String, language != "ru" {
            print("⚠️ Внимание: API определил язык как '\(language)', хотя запрошен 'ru'")
        }
        
        print("Получен jobId: \(jobId)")
        return jobId
    }
    
    /// Проверяет статус задания
    /// GET /speechtotext/v1/jobs/{id}
    func checkJobStatus(jobId: String) async throws -> String {
        print("\nRevAI: Проверяем статус задания \(jobId)")
        
        let statusURL = URL(string: "\(baseURL)/jobs/\(jobId)")!
        var request = URLRequest(url: statusURL)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Логируем запрос
        logRequest(request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный тип ответа"])
        }
        
        // Логируем ответ
        logResponse(httpResponse, data: data)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить статус"])
        }
        
        print("Текущий статус: \(status)")
        return status
    }
    
    /// Получает результат транскрибации
    /// GET /speechtotext/v1/jobs/{id}/transcript
    func getTranscription(jobId: String) async throws -> [TranscriptionResult] {
        print("\nRevAI: Получаем результаты транскрибации для задания \(jobId)")
        
        let transcriptURL = URL(string: "\(baseURL)/jobs/\(jobId)/transcript")!
        var request = URLRequest(url: transcriptURL)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.rev.transcript.v1.0+json", forHTTPHeaderField: "Accept")
        
        // Логируем запрос
        logRequest(request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный тип ответа"])
        }
        
        // Логируем ответ
        logResponse(httpResponse, data: data)
        
        guard httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let monologues = json["monologues"] as? [[String: Any]] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга результата"])
        }
        
        var results: [TranscriptionResult] = []
        
        for monologue in monologues {
            if let elements = monologue["elements"] as? [[String: Any]] {
                for element in elements {
                    if let type = element["type"] as? String,
                       type == "text",
                       let value = element["value"] as? String,
                       let startTime = element["ts"] as? Double,
                       let endTime = element["end_ts"] as? Double {
                        results.append(TranscriptionResult(
                            text: value,
                            startTime: startTime,
                            endTime: endTime,
                            confidence: 1.0
                        ))
                    }
                }
            }
        }
        
        print("Получено \(results.count) результатов")
        return results
    }
}
