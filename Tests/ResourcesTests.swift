import Foundation

func runResourcesTests() {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent("res-test-\(UUID().uuidString).bundle")
    let img = root.appendingPathComponent("Contents/Resources/img")
    try? fm.createDirectory(at: img, withIntermediateDirectories: true)
    fm.createFile(atPath: img.appendingPathComponent("a.png").path, contents: Data())
    defer { try? fm.removeItem(at: root) }

    guard let bundle = Bundle(url: root) else {
        check(false, "could not create test bundle")
        return
    }
    check(imageURL("a.png", in: bundle)?.lastPathComponent == "a.png", "existing resource resolves")
    check(imageURL("missing.png", in: bundle) == nil, "missing resource is nil")
    check(nsImage("missing.png", in: bundle) == nil, "missing image is nil")
}
