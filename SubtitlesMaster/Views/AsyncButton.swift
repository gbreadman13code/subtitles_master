import SwiftUI

@MainActor
struct AsyncButton<Label: View>: View {
    let action: @Sendable () async -> Void
    @ViewBuilder let label: () -> Label
    
    @State private var isPerforming = false
    @State private var task: Task<Void, Never>?
    
    init(action: @escaping @Sendable () async -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button {
            guard !isPerforming else { return }
            isPerforming = true
            
            task = Task {
                do {
                    try await Task.sleep(nanoseconds: 100_000_000) // Небольшая задержка для UI
                    await action()
                } catch {
                    print("AsyncButton error: \(error)")
                }
                isPerforming = false
            }
        } label: {
            label()
                .opacity(isPerforming ? 0.5 : 1.0)
        }
        .disabled(isPerforming)
        .onDisappear {
            task?.cancel()
        }
    }
} 