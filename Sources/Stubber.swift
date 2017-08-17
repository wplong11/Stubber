private typealias FunctionAddress = Int
private typealias Function = Any

private final class Store {
  var stubs: [FunctionAddress: Function] = [:]
  var executions: [FunctionAddress: [AnyExecution]] = [:]
}

private let store = Store()


// MARK: Stub

public func register<A, R>(_ f: (A) -> R, with closure: @escaping (A) -> R) {
  let address = functionAddress(of: f)
  store.stubs[address] = closure
  store.executions[address]?.removeAll()
}


// MARK: Stubbed

public func invoke<A, R>(_ f: (A) -> R, args: A, default: @autoclosure () -> R? = nil, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) -> R {
  let address = functionAddress(of: f)
  let closure = store.stubs[address] as? (A) -> R
  guard let result = closure?(args) ?? `default`() else {
    preconditionFailure("⚠️ '\(function)' is not stubbed.", file: file, line: line)
  }
  store.executions[address] = (store.executions[address] ?? []) + [Execution<A, R>(arguments: args, result: result)]
  return result
}


// MARK: Executions

public func executions<A, R>(_ f: (A) -> R) -> [Execution<A, R>] {
  return _executions(f)
}

private func _executions<A, R>(_ f: (A) -> R) -> [Execution<A, R>] {
  let address = functionAddress(of: f)
  return (store.executions[address] as? [Execution<A, R>]) ?? []
}


// MARK: Clear

public func clear() {
  store.stubs.removeAll()
  store.executions.removeAll()
}


// MARK: Utils

private func functionAddress<A, R>(of f: (A) -> R) -> Int {
  let (_, lo) = unsafeBitCast(f, to: (Int, Int).self)
  let offset = MemoryLayout<Int>.size == 8 ? 16 : 12
  let pointer = UnsafePointer<Int>(bitPattern: lo + offset)!
  return pointer.pointee
}
