import Foundation
import SwiftUI

enum ToolType {
    case fonts
    case fontSize
}

struct FontOption: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
}

class SubtitleToolsManager: ObservableObject {
    @Published var selectedTool: ToolType?
    @Published var selectedFont: String = "SF Pro"
    @Published var fontSize: Double = 20 // Размер шрифта по умолчанию
    
    let minFontSize: Double = 12
    let maxFontSize: Double = 40
    
    let availableFonts: [FontOption] = [
        FontOption(name: "SF Pro", displayName: "San Francisco"),
        FontOption(name: "Helvetica Neue", displayName: "Helvetica"),
        FontOption(name: "Georgia", displayName: "Georgia"),
        FontOption(name: "Avenir Next", displayName: "Avenir"),
        FontOption(name: "Palatino", displayName: "Palatino")
    ]
    
    func toggleTool(_ tool: ToolType) {
        if selectedTool == tool {
            selectedTool = nil
        } else {
            selectedTool = tool
        }
    }
} 