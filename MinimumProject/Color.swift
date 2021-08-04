public protocol View {
}

public struct Color {
}

struct AccentColorKey: EnvironmentKey {
  static let defaultValue: Color? = nil
}

struct EnvironmentValues {

}


extension EnvironmentValues {
  var accentColor: Color? {
    get { return nil }
    set {}
  }
}

public protocol EnvironmentKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

struct _EnvironmentKeyWritingModifier<Value> {
    let keyPath: WritableKeyPath<EnvironmentValues, Value>
}

extension View {
  func environment<V>(
    _ keyPath: WritableKeyPath<EnvironmentValues, V>,
    _ value: V
  ) {
    _EnvironmentKeyWritingModifier(keyPath: keyPath)
  }
}


public extension View {
  func accentColor(_ accentColor: Color?) {
    environment(\.accentColor, accentColor)
  }
}
