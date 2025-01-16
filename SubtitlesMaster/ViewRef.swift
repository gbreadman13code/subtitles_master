import SwiftUI

@propertyWrapper
final class ViewRef<Value> {
    private var value: Value?
    
    var wrappedValue: Value? {
        get { value }
        set { value = newValue }
    }
    
    var projectedValue: Binding<Value?> {
        Binding(
            get: { self.value },
            set: { self.value = $0 }
        )
    }
    
    init() {
        self.value = nil
    }
} 