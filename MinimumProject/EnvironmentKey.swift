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
