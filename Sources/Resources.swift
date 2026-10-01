import AppKit

/// Resolves assets copied by `build.sh` into `Contents/Resources/img`.
/// `name` is relative to `img/`, e.g. `"wind_rose.png"` or `"weather-icons/weather-clear-symbolic.svg"`.
func imageURL(_ name: String, in bundle: Bundle = .main) -> URL? {
    guard let base = bundle.resourceURL else { return nil }
    let url = base.appendingPathComponent("img").appendingPathComponent(name)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

func nsImage(_ name: String, in bundle: Bundle = .main) -> NSImage? {
    guard let url = imageURL(name, in: bundle) else { return nil }
    return NSImage(contentsOf: url)
}
