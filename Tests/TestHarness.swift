import Foundation

nonisolated(unsafe) var testFailures = 0
nonisolated(unsafe) var testChecks = 0

func check(_ condition: @autoclosure () -> Bool, _ message: String = "",
           file: StaticString = #fileID, line: UInt = #line) {
    testChecks += 1
    if !condition() {
        testFailures += 1
        print("FAIL \(file):\(line) \(message)")
    }
}
