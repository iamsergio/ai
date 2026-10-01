import Foundation

// Register each test file's entry function here.
runSanityTests()

print("\(testChecks) checks, \(testFailures) failures")
exit(testFailures == 0 ? 0 : 1)
