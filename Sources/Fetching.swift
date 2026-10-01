import Foundation

/// Loads the bytes behind a URL. Injected so services can be tested without the network.
typealias DataFetcher = @Sendable (URL) async throws -> Data

struct HTTPStatusError: Error, Equatable {
    let status: Int
}

enum Fetching {
    static let live: DataFetcher = { url in
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw HTTPStatusError(status: http.statusCode)
        }
        return data
    }
}
