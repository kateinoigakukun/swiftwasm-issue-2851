public protocol View {
}

public extension View {
  func modifier<Modifier>(_ modifier: Modifier) {
  }
}





public struct Color {
}

struct AccentColorKey: EnvironmentKey {
  static let defaultValue: Color? = nil
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

public struct _EnvironmentKeyWritingModifier<Value> {
    public let keyPath: WritableKeyPath<EnvironmentValues, Value>
    public let value: Value
}

public extension View {
  func environment<V>(
    _ keyPath: WritableKeyPath<EnvironmentValues, V>,
    _ value: V
  ) {
    modifier(_EnvironmentKeyWritingModifier(keyPath: keyPath, value: value))
  }
}


public extension View {
  func accentColor(_ accentColor: Color?) {
    environment(\.accentColor, accentColor)
  }
}
