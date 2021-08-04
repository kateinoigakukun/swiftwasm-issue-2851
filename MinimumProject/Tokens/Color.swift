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
  func accentColor(_ accentColor: Color?) {
    environment(\.accentColor, accentColor)
  }
}
