// Copyright 2020-2021 Tokamak contributors
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
//  Created by Carson Katri on 7/17/20.
//

public protocol DynamicProperty {
  mutating func update()
}

public extension DynamicProperty {
  mutating func update() {}
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

/// A protocol that allows the conforming type to access values from the `EnvironmentValues`.
/// (e.g. `Environment` and `EnvironmentObject`)
///
/// `EnvironmentValues` are injected in 2 places:
/// 1. `View.makeMountedView`
/// 2. `MountedHostView.update` when reconciling
///
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

public protocol EnvironmentKey {
  associatedtype Value
  static var defaultValue: Value { get }
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

public extension View {
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

import CombineShim

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

  subscript<B>(bindable: ObjectIdentifier) -> B? where B: ObservableObject {
    get {
      values[bindable] as? B
    }
    set {
      values[bindable] = newValue
    }
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

protocol ModifierContainer {
  var environmentModifier: EnvironmentModifier? { get }
}

/// A value with a modifier applied to it.
public struct ModifiedContent<Content, Modifier> {
  @Environment(\.self) public var environment
  public typealias Body = Never
  public private(set) var content: Content
  public private(set) var modifier: Modifier

  public init(content: Content, modifier: Modifier) {
    self.content = content
    self.modifier = modifier
  }
}

extension ModifiedContent: ModifierContainer {
  var environmentModifier: EnvironmentModifier? { modifier as? EnvironmentModifier }
}

extension ModifiedContent: EnvironmentReader where Modifier: EnvironmentReader {
  mutating func setContent(from values: EnvironmentValues) {
    modifier.setContent(from: values)
  }
}

extension ModifiedContent: View, ParentView where Content: View, Modifier: ViewModifier {
  public var body: Body {
    neverBody("ModifiedContent<View, ViewModifier>")
  }

  public var children: [AnyView] {
    [AnyView(content)]
  }
}

extension ModifiedContent: ViewModifier where Content: ViewModifier, Modifier: ViewModifier {
  public func body(content: _ViewModifier_Content<Self>) -> Never {
    neverBody("ModifiedContent<ViewModifier, ViewModifier>")
  }
}

public extension ViewModifier {
  func concat<T>(_ modifier: T) -> ModifiedContent<Self, T> where T: ViewModifier {
    .init(content: self, modifier: modifier)
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
  public let view: AnyView

  public init(modifier: Modifier, view: AnyView) {
    self.modifier = modifier
    self.view = view
  }

  public var body: AnyView {
    view
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
// Copyright 2018-2020 Tokamak contributors
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
//  Created by Max Desiatov on 16/10/2018.
//

/// Override `TokamakCore`'s default `Color` resolvers with a Renderer-specific one.
/// You can override a specific color box
/// (such as `_SystemColorBox`, or all boxes with `AnyColorBox`).
///
/// This extension makes all system colors red:
///
///     extension _SystemColorBox: AnyColorBoxDeferredToRenderer {
///       public func deferredResolve(
///         in environment: EnvironmentValues
///       ) -> AnyColorBox.ResolvedValue {
///         return .init(
///           red: 1,
///           green: 0,
///           blue: 0,
///           opacity: 1,
///           space: .sRGB
///         )
///       }
///     }
///


public struct Color: Hashable, Equatable {
}

struct AccentColorKey: EnvironmentKey {
  static let defaultValue: Color? = nil
}

public extension EnvironmentValues {
  var accentColor: Color? {
    get {
      self[AccentColorKey.self]
    }
    set {
      self[AccentColorKey.self] = newValue
    }
  }
}

public extension View {
  func accentColor(_ accentColor: Color?) -> some View {
    environment(\.accentColor, accentColor)
  }
}
// Copyright 2020-2021 Tokamak contributors
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
//  Created by Max Desiatov on 08/04/2020.
//

/// A type-erased view.
public struct AnyView: PrimitiveView {
  /// The type of the underlying `view`.
  let type: Any.Type

  /** The name of the unapplied generic type of the underlying `view`. `Button<Text>` and
   `Button<Image>` types are different, but when reconciling the tree of mounted views
   they are treated the same, thus the `Button` part of the type (the type constructor)
   is stored in this property.
   */
  let typeConstructorName: String

  /// The actual `View` value wrapped within this `AnyView`.
  var view: Any

  /** Type-erased `body` of the underlying `view`. Needs to take a fresh version of `view` as an
   argument, otherwise it captures an old value of the `body` property.
   */
  let bodyClosure: (Any) -> AnyView

  /** The type of the `body` of the underlying `view`. Used to cast the result of the applied
   `bodyClosure` property.
   */
  let bodyType: Any.Type

  public init<V>(_ view: V) where V: View {
    if let anyView = view as? AnyView {
      self = anyView
    } else {
      type = V.self

      typeConstructorName = "" // TokamakCore.typeConstructorName(type)

      bodyType = V.Body.self
      self.view = view
      if view is ViewDeferredToRenderer {
        bodyClosure = {
          let deferredView: Any
          deferredView = $0
          // swiftlint:disable:next force_cast
          return (deferredView as! ViewDeferredToRenderer).deferredBody
        }
      } else {
        // swiftlint:disable:next force_cast
        bodyClosure = { AnyView(($0 as! V).body) }
      }
    }
  }
}

public func mapAnyView<T, V>(_ anyView: AnyView, transform: (V) -> T) -> T? {
  guard let view = anyView.view as? V else { return nil }

  return transform(view)
}

extension AnyView: ParentView {
  @_spi(TokamakCore)
  public var children: [AnyView] {
    (view as? ParentView)?.children ?? []
  }
}

public struct _AnyViewProxy {
  public var subject: AnyView

  public init(_ subject: AnyView) { self.subject = subject }

  public var type: Any.Type { subject.type }
  public var view: Any { subject.view }
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
//
//  Created by Max Desiatov on 07/04/2020.
//

public protocol View {
  associatedtype Body: View

  var body: Self.Body { get }
}

public extension Never {
  @_spi(TokamakCore)
  var body: Never {
    fatalError()
  }
}

extension Never: PrimitiveView {}

/// A `View` that offers primitive functionality, which renders its `body` inaccessible.
public protocol PrimitiveView: View where Body == Never {}

public extension PrimitiveView {
  @_spi(TokamakCore)
  var body: Never {
    neverBody(String(reflecting: Self.self))
  }
}

/// A `View` type that renders with subviews, usually specified in the `Content` type argument
public protocol ParentView {
  var children: [AnyView] { get }
}

/// A `View` type that is not rendered but "flattened", rendering all its children instead.
protocol GroupView: ParentView {}

/** The distinction between "host" (truly primitive) and "composite" (that have meaningful `body`)
 views is made in the reconciler in `TokamakCore` based on their `body` type, host views have body
 type `Never`. `ViewDeferredToRenderer` allows renderers to override that per-platform and render
 host views as composite by providing their own `deferredBody` implementation.
 */
public protocol ViewDeferredToRenderer {
  var deferredBody: AnyView { get }
}

/// Calls `fatalError` with an explanation that a given `type` is a primitive `View`
public func neverBody(_ type: String) -> Never {
  fatalError("\(type) is a primitive `View`, you're not supposed to access its `body`.")
}
