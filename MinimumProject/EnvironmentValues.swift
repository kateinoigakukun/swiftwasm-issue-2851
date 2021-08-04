public struct EnvironmentValues {

  public subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
    get {
      return K.defaultValue
    }
    set {}
  }

}

