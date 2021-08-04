// Copyright 2020 Tokamak contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Carson Katri on 7/16/20.
//

protocol DynamicProperty {}
public protocol EnvironmentKey {
  associatedtype Value
  static var defaultValue: Value { get }
}


protocol EnvironmentReader {
  mutating func setContent(from values: EnvironmentValues)
}

@propertyWrapper public struct Environment<Value>: DynamicProperty {
  enum Content {
    case keyPath(KeyPath<EnvironmentValues, Value>)
    case value(Value)
  }

  private var content: Content
  private let keyPath: KeyPath<EnvironmentValues, Value>
  public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
    content = .keyPath(keyPath)
    self.keyPath = keyPath
  }

  mutating func setContent(from values: EnvironmentValues) {
    content = .value(values[keyPath: keyPath])
  }

  public var wrappedValue: Value {
    switch content {
    case let .value(value):
      return value
    case let .keyPath(keyPath):
      // not bound to a view, return the default value.
      return EnvironmentValues()[keyPath: keyPath]
    }
  }
}

extension Environment: EnvironmentReader {}


@propertyWrapper public struct AppStorage<Value>: DynamicProperty {
  let provider: _StorageProvider?
  @Environment(\._defaultAppStorage) var defaultProvider: _StorageProvider?
  var unwrappedProvider: _StorageProvider {
    provider ?? defaultProvider!
  }

  let key: String
  let defaultValue: Value
  let store: (_StorageProvider, String, Value) -> ()
  let read: (_StorageProvider, String) -> Value?

  public var wrappedValue: Value {
    get {
      read(unwrappedProvider, key) ?? defaultValue
    }
    nonmutating set {
      store(unwrappedProvider, key, newValue)
    }
  }

}

public extension AppStorage {
  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value == Bool
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2) }
    read = { $0.read(key: $1) }
  }

  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value == Int
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2) }
    read = { $0.read(key: $1) }
  }

  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value == Double
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2) }
    read = { $0.read(key: $1) }
  }

  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value == String
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2) }
    read = { $0.read(key: $1) }
  }

  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value: RawRepresentable, Value.RawValue == Int
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2.rawValue) }
    read = {
      guard let rawValue = $0.read(key: $1) as Int? else {
        return nil
      }
      return Value(rawValue: rawValue)
    }
  }

  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value: RawRepresentable, Value.RawValue == String
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2.rawValue) }
    read = {
      guard let rawValue = $0.read(key: $1) as String? else {
        return nil
      }
      return Value(rawValue: rawValue)
    }
  }
}

public extension AppStorage where Value: ExpressibleByNilLiteral {
  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value == Bool?
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2) }
    read = { $0.read(key: $1) }
  }

  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value == Int?
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2) }
    read = { $0.read(key: $1) }
  }

  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value == Double?
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2) }
    read = { $0.read(key: $1) }
  }

  init(wrappedValue: Value, _ key: String, store: _StorageProvider? = nil)
    where Value == String?
  {
    defaultValue = wrappedValue
    self.key = key
    provider = store
    self.store = { $0.store(key: $1, value: $2) }
    read = { $0.read(key: $1) }
  }
}

/// The renderer is responsible for making sure a default is set at the root of the App.
struct DefaultAppStorageEnvironmentKey: EnvironmentKey {
  static let defaultValue: _StorageProvider? = nil
}

public extension EnvironmentValues {
  @_spi(TokamakCore)
  var _defaultAppStorage: _StorageProvider? {
    get {
      self[DefaultAppStorageEnvironmentKey.self]
    }
    set {
      self[DefaultAppStorageEnvironmentKey.self] = newValue
    }
  }
}

public protocol View {
}
// MARKER(katei): Maybe affect the reproduced crash
extension View {
  func defaultAppStorage(_ store: _StorageProvider) -> some View {
    environment(\._defaultAppStorage, store)
  }
}

// Copyright 2020 Tokamak contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

public struct EnvironmentValues: CustomStringConvertible {
  public var description: String {
    "EnvironmentValues: \(values.count)"
  }

  private var values: [ObjectIdentifier: Any] = [:]

  public init() {}

  public subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
    get {
      if let val = values[ObjectIdentifier(key)] as? K.Value {
        return val
      }
      return K.defaultValue
    }
    set {
      values[ObjectIdentifier(key)] = newValue
    }
  }

  // subscript<B>(bindable: ObjectIdentifier) -> B? where B: ObservableObject {
  //   get {
  //     values[bindable] as? B
  //   }
  //   set {
  //     values[bindable] = newValue
  //   }
  // }
}

struct IsEnabledKey: EnvironmentKey {
  static let defaultValue = true
}

public extension EnvironmentValues {
  var isEnabled: Bool {
    get {
      self[IsEnabledKey.self]
    }
    set {
      self[IsEnabledKey.self] = newValue
    }
  }
}

// struct _EnvironmentValuesWritingModifier: ViewModifier, EnvironmentModifier {
//   let environmentValues: EnvironmentValues
// 
//   func body(content: Content) -> some View {
//     content
//   }
// 
//   func modifyEnvironment(_ values: inout EnvironmentValues) {
//     values = environmentValues
//   }
// }
// 
// public extension View {
//   func environmentValues(_ values: EnvironmentValues) -> some View {
//     modifier(_EnvironmentValuesWritingModifier(environmentValues: values))
//   }
// }
// Copyright 2020 Tokamak contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Carson Katri on 7/22/20.
//

public protocol _StorageProvider {
  func store(key: String, value: Bool?)
  func store(key: String, value: Int?)
  func store(key: String, value: Double?)
  func store(key: String, value: String?)

  func read(key: String) -> Bool?
  func read(key: String) -> Int?
  func read(key: String) -> Double?
  func read(key: String) -> String?

  static var standard: _StorageProvider { get }
}

protocol EnvironmentModifier {
  func modifyEnvironment(_ values: inout EnvironmentValues)
}

public struct _EnvironmentKeyWritingModifier<Value>: ViewModifier, EnvironmentModifier {
  public let keyPath: WritableKeyPath<EnvironmentValues, Value>
  public let value: Value

  public init(keyPath: WritableKeyPath<EnvironmentValues, Value>, value: Value) {
    self.keyPath = keyPath
    self.value = value
  }

  public typealias Body = Never

  func modifyEnvironment(_ values: inout EnvironmentValues) {
    values[keyPath: keyPath] = value
  }
}

extension View {
  func environment<V>(
    _ keyPath: WritableKeyPath<EnvironmentValues, V>,
    _ value: V
  ) -> some View {
    modifier(_EnvironmentKeyWritingModifier(keyPath: keyPath, value: value))
  }
}
// Copyright 2020 Tokamak contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

public protocol ViewModifier {
  typealias Content = _ViewModifier_Content<Self>
  associatedtype Body: View
  func body(content: Content) -> Self.Body
}

public struct _ViewModifier_Content<Modifier>: View where Modifier: ViewModifier {
  public let modifier: Modifier

  public init(modifier: Modifier) {
    self.modifier = modifier
  }
}

public extension View {
  func modifier<Modifier>(_ modifier: Modifier) -> ModifiedContent<Self, Modifier> {
    .init(content: self, modifier: modifier)
  }
}

public extension ViewModifier where Body == Never {
  func body(content: Content) -> Body {
    fatalError(
      "\(Self.self) is a primitive `ViewModifier`, you're not supposed to run `body(content:)`"
    )
  }
}

extension Never: View {}

public struct ModifiedContent<Content, Modifier>: View {
  @Environment(\.self) public var environment
  public typealias Body = Never
  public private(set) var content: Content
  public private(set) var modifier: Modifier

  public init(content: Content, modifier: Modifier) {
    self.content = content
    self.modifier = modifier
  }
}

