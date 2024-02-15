// RUN: %empty-directory(%t)

// RUN: %target-swift-emit-module-interface(%t/FeatureTest.swiftinterface) %s -module-name FeatureTest -disable-availability-checking
// RUN: %target-swift-typecheck-module-from-interface(%t/FeatureTest.swiftinterface) -module-name FeatureTest -disable-availability-checking
// RUN: %FileCheck %s < %t/FeatureTest.swiftinterface

// REQUIRES: concurrency

// Ensure that when we emit a Swift interface that makes use of new features,
// the uses of those features are guarded by appropriate #if's that allow older
// compilers to skip over the uses of newer features.

// CHECK: #if compiler(>=5.3) && $SpecializeAttributeWithAvailability
// CHECK: @_specialize(exported: true, kind: full, availability: macOS, introduced: 12; where T == Swift.Int)
// CHECK: public func specializeWithAvailability<T>(_ t: T)
// CHECK: #else
// CHECK: public func specializeWithAvailability<T>(_ t: T)
// CHECK: #endif
@_specialize(exported: true, availability: macOS 12, *; where T == Int)
public func specializeWithAvailability<T>(_ t: T) {
}

// CHECK-NOT: #if compiler(>=5.3) && $Actors
// CHECK:      public actor MyActor
// CHECK:        @_semantics("defaultActor") nonisolated final public var unownedExecutor: _Concurrency.UnownedSerialExecutor {
// CHECK-NEXT:     get
// CHECK-NEXT:   }
// CHECK-NEXT: }
public actor MyActor {
}

// CHECK-NOT: #if compiler(>=5.3) && $Actors
// CHECK:     extension FeatureTest.MyActor
public extension MyActor {
  // CHECK-NOT: $Actors
  // CHECK:     testFunc
  func testFunc() async { }
  // CHECK: }
}

// CHECK-NOT: #if compiler(>=5.3) && $AsyncAwait
// CHECK:     globalAsync
public func globalAsync() async { }

// CHECK:      @_marker public protocol MP {
// CHECK-NEXT: }
@_marker public protocol MP { }

// CHECK:      @_marker public protocol MP2 : FeatureTest.MP {
// CHECK-NEXT: }
@_marker public protocol MP2: MP { }

// CHECK-NOT: #if compiler(>=5.3) && $MarkerProtocol
// CHECK:      public protocol MP3 : AnyObject, FeatureTest.MP {
// CHECK-NEXT: }
public protocol MP3: AnyObject, MP { }

// CHECK:      extension FeatureTest.MP2 {
// CHECK-NEXT: func inMP2
extension MP2 {
  public func inMP2() { }
}

// CHECK: class OldSchool : FeatureTest.MP {
public class OldSchool: MP {
  // CHECK-NOT: #if compiler(>=5.3) && $AsyncAwait
  // CHECK:     takeClass()
  public func takeClass() async { }
}

// CHECK: class OldSchool2 : FeatureTest.MP {
public class OldSchool2: MP {
  // CHECK-NOT: #if compiler(>=5.3) && $AsyncAwait
  // CHECK:     takeClass()
  public func takeClass() async { }
}

// CHECK:      #if compiler(>=5.3) && $RethrowsProtocol
// CHECK-NEXT: @rethrows public protocol RP
@rethrows public protocol RP {
  func f() throws -> Bool
}

// CHECK: public struct UsesRP {
public struct UsesRP {
  // CHECK:     #if compiler(>=5.3) && $RethrowsProtocol
  // CHECK-NEXT:  public var value: (any FeatureTest.RP)? {
  // CHECK-NOT: #if compiler(>=5.3) && $RethrowsProtocol
  // CHECK:         get
  public var value: RP? {
    nil
  }
}

// CHECK:      #if compiler(>=5.3) && $RethrowsProtocol
// CHECK-NEXT: public struct IsRP
public struct IsRP: RP {
  // CHECK-NEXT: public func f()
  public func f() -> Bool { }

  // CHECK-NOT: $RethrowsProtocol
  // CHECK-NEXT: public var isF:
  // CHECK-NEXT:   get
  public var isF: Bool {
    f()
  }
}

// CHECK: #if compiler(>=5.3) && $RethrowsProtocol
// CHECK-NEXT: public func acceptsRP
public func acceptsRP<T: RP>(_: T) { }

// CHECK-NOT: #if compiler(>=5.3) && $MarkerProtocol
// CHECK:     extension Swift.Array : FeatureTest.MP where Element : FeatureTest.MP {
extension Array: FeatureTest.MP where Element : FeatureTest.MP { }
// CHECK: }

// CHECK-NOT: #if compiler(>=5.3) && $MarkerProtocol
// CHECK:     extension FeatureTest.OldSchool : Swift.UnsafeSendable {
extension OldSchool: UnsafeSendable { }
// CHECK-NEXT: }


// CHECK-NOT: #if compiler(>=5.3) && $AsyncAwait
// CHECK:     func runSomethingSomewhere
public func runSomethingSomewhere(body: () async -> Void) { }

// CHECK-NOT: #if compiler(>=5.3) && $Sendable
// CHECK:     func runSomethingConcurrently(body: @Sendable () -> 
public func runSomethingConcurrently(body: @Sendable () -> Void) { }

// CHECK-NOT: #if compiler(>=5.3) && $Actors
// CHECK:     func stage
public func stage(with actor: MyActor) { }

// CHECK-NOT: #if compiler(>=5.3) && $AsyncAwait && $Sendable && $InheritActorContext
// CHECK:     func asyncIsh
public func asyncIsh(@_inheritActorContext operation: @Sendable @escaping () async -> Void) { }

// CHECK-NOT: #if compiler(>=5.3) && $AsyncAwait
// CHECK:     #if compiler(>=5.3) && $UnsafeInheritExecutor
// CHECK:     @_unsafeInheritExecutor public func unsafeInheritExecutor() async
@_unsafeInheritExecutor
public func unsafeInheritExecutor() async {}

// CHECK-NOT: #if compiler(>=5.3) && $AsyncAwait
// CHECK-NOT: #if $UnsafeInheritExecutor
// CHECK:     #elseif compiler(>=5.3) && $SpecializeAttributeWithAvailability
// CHECK:     @_specialize{{.*}}
// CHECK:     public func multipleSuppressible<T>(value: T) async
@_unsafeInheritExecutor
@_specialize(exported: true, availability: SwiftStdlib 5.1, *; where T == Int)
public func multipleSuppressible<T>(value: T) async {}

// CHECK:      #if compiler(>=5.3) && $UnavailableFromAsync
// CHECK-NEXT: @_unavailableFromAsync(message: "Test") public func unavailableFromAsyncFunc()
// CHECK-NEXT: #else
// CHECK-NEXT: public func unavailableFromAsyncFunc()
// CHECK-NEXT: #endif
@_unavailableFromAsync(message: "Test")
public func unavailableFromAsyncFunc() { }

// CHECK:      #if compiler(>=5.3) && $NoAsyncAvailability
// CHECK-NEXT: @available(*, noasync, message: "Test")
// CHECK-NEXT: public func noAsyncFunc()
// CHECK-NEXT: #else
// CHECK-NEXT: public func noAsyncFunc()
// CHECK-NEXT: #endif
@available(*, noasync, message: "Test")
public func noAsyncFunc() { }

// CHECK-NOT: extension FeatureTest.MyActor : Swift.Sendable
