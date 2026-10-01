import Foundation

struct GeoLocation: Equatable {
    let latitude: Double
    let longitude: Double
    let city: String
}

/// IP geolocation: a primary provider, then a fallback.
enum LocationService {
    struct Provider {
        let url: URL
        let decode: (Data) throws -> GeoLocation
    }

    enum Failure: Error { case invalidResponse }

    static let providers = [
        Provider(url: URL(string: "https://ipapi.co/json/")!, decode: decodeIPAPI),
        Provider(url: URL(string: "https://ipwho.is/")!, decode: decodeIPWhoIs),
    ]

    private struct Payload: Decodable {
        var success: Bool?
        var city: String?
        var region: String?
        var latitude: Double?
        var longitude: Double?
    }

    static func decodeIPAPI(_ data: Data) throws -> GeoLocation { try decode(data) }
    static func decodeIPWhoIs(_ data: Data) throws -> GeoLocation { try decode(data) }

    private static func decode(_ data: Data) throws -> GeoLocation {
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        guard payload.success != false,
              let lat = payload.latitude, let lon = payload.longitude,
              (-90...90).contains(lat), (-180...180).contains(lon) else { throw Failure.invalidResponse }
        let name = [payload.city, payload.region].compactMap { $0 }.first { !$0.isEmpty }
        return GeoLocation(latitude: lat, longitude: lon, city: name ?? "--")
    }

    /// Tries each provider in order and returns the first success; throws the last error.
    static func locate(using fetch: DataFetcher, providers: [Provider] = providers) async throws -> GeoLocation {
        var lastError: Error = Failure.invalidResponse
        for provider in providers {
            do {
                return try provider.decode(try await fetch(provider.url))
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}
