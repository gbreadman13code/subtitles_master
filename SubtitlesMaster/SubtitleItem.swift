import Foundation

struct SubtitleItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double
    
    var isVisible: Bool = false
    
    // Проверяет, должен ли субтитр отображаться в данный момент времени
    func shouldDisplay(at currentTime: Double) -> Bool {
        return currentTime >= startTime && currentTime <= endTime
    }
    
    // Реализация Equatable
    static func == (lhs: SubtitleItem, rhs: SubtitleItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.isVisible == rhs.isVisible
    }
} 