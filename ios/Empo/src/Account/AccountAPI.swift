import Foundation

enum AccountAPI {
    static let baseURL = CommunityLayoutAPI.baseURL

    struct Entitlements: Codable, Sendable, Equatable {
        let pro: Bool
        let cloudSave: Bool
        let cheats: Bool
        let fastForward: Bool
        let communityPremium: Bool

        enum CodingKeys: String, CodingKey {
            case pro
            case cloudSave = "cloud_save"
            case cheats
            case fastForward = "fast_forward"
            case communityPremium = "community_premium"
        }

        static let free = Entitlements(
            pro: false, cloudSave: false, cheats: false,
            fastForward: false, communityPremium: false)
    }

    struct AccountProfile: Codable, Sendable, Equatable {
        let id: String
        let email: String?
        let entitlements: Entitlements
    }

    struct SignInResponse: Codable, Sendable {
        let accessToken: String
        let expiresAt: String
        let account: AccountProfile

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresAt = "expires_at"
            case account
        }
    }

    struct SaveListItem: Codable, Identifiable, Sendable {
        let gameKey: String
        let gameTitle: String
        let revision: Int
        let sizeBytes: Int
        let checksumSha256: String
        let updatedAt: String

        var id: String { gameKey }

        enum CodingKeys: String, CodingKey {
            case gameKey = "game_key"
            case gameTitle = "game_title"
            case revision
            case sizeBytes = "size_bytes"
            case checksumSha256 = "checksum_sha256"
            case updatedAt = "updated_at"
        }
    }

    struct SaveUploadResult: Codable, Sendable {
        let gameKey: String
        let revision: Int
        let sizeBytes: Int
        let checksumSha256: String
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case gameKey = "game_key"
            case revision
            case sizeBytes = "size_bytes"
            case checksumSha256 = "checksum_sha256"
            case updatedAt = "updated_at"
        }
    }

    enum Error: LocalizedError {
        case badStatus(Int, String)
        case decodeFailed

        var errorDescription: String? {
            switch self {
            case .badStatus(let code, let detail): "Server error (\(code)): \(detail)"
            case .decodeFailed: "Could not read the server response."
            }
        }
    }

    static func signInWithApple(identityToken: String) async throws -> SignInResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/auth/apple"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["identity_token": identityToken])
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(data, response)
    }

    static func signInDev(deviceLabel: String) async throws -> SignInResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/auth/dev"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["device_label": deviceLabel])
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(data, response)
    }

    static func fetchAccount(accessToken: String) async throws -> AccountProfile {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/account/me"))
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(data, response)
    }

    /// Permanently deletes the server account and associated cloud saves.
    static func deleteAccount(accessToken: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/account/me"))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        let _: [String: Bool] = try decode(data, response)
    }

    struct SubscriptionVerifyRequest: Encodable {
        let productID: String
        let originalTransactionID: String
        let expiresAt: String
        let signedTransaction: String?

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
            case originalTransactionID = "original_transaction_id"
            case expiresAt = "expires_at"
            case signedTransaction = "signed_transaction"
        }
    }

    struct SubscriptionVerifyResponse: Codable, Sendable {
        let accountId: String
        let proUntil: String
        let entitlements: Entitlements

        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case proUntil = "pro_until"
            case entitlements
        }
    }

    static func verifySubscription(
        accessToken: String,
        productID: String,
        originalTransactionID: String,
        expiresAt: Date,
        signedTransaction: String?
    ) async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var expiresString = formatter.string(from: expiresAt)
        if expiresString.isEmpty {
            formatter.formatOptions = [.withInternetDateTime]
            expiresString = formatter.string(from: expiresAt)
        }
        let body = SubscriptionVerifyRequest(
            productID: productID,
            originalTransactionID: originalTransactionID,
            expiresAt: expiresString,
            signedTransaction: signedTransaction
        )
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/subscription/verify"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let _: SubscriptionVerifyResponse = try decode(data, response)
    }

    static func listCloudSaves(accessToken: String) async throws -> [SaveListItem] {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/saves"))
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        struct ListResponse: Codable { let saves: [SaveListItem] }
        let decoded: ListResponse = try decode(data, response)
        return decoded.saves
    }

    static func uploadCloudSave(
        accessToken: String,
        gameKey: String,
        gameTitle: String,
        packData: Data
    ) async throws -> SaveUploadResult {
        let boundary = "XPPocket-\(UUID().uuidString)"
        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        field("game_title", gameTitle)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"pack\"; filename=\"\(gameKey).zip\"\r\n"
                .data(using: .utf8)!)
        body.append("Content-Type: application/zip\r\n\r\n".data(using: .utf8)!)
        body.append(packData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(
            url: baseURL.appendingPathComponent("v1/saves/\(gameKey)"))
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(data, response)
    }

    static func downloadCloudSave(
        accessToken: String,
        gameKey: String
    ) async throws -> Data {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("v1/saves/\(gameKey)"))
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw Error.badStatus(-1, "No response")
        }
        if !(200 ... 299).contains(http.statusCode) {
            let detail = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
                ?? String(data: data, encoding: .utf8)
                ?? "HTTP \(http.statusCode)"
            throw Error.badStatus(http.statusCode, detail)
        }
        guard !data.isEmpty else { throw Error.decodeFailed }
        return data
    }

    private static func decode<T: Decodable>(_ data: Data, _ response: URLResponse) throws -> T {
        guard let http = response as? HTTPURLResponse else {
            throw Error.badStatus(-1, "No response")
        }
        if !(200 ... 299).contains(http.statusCode) {
            let detail = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
                ?? String(data: data, encoding: .utf8)
                ?? "HTTP \(http.statusCode)"
            throw Error.badStatus(http.statusCode, detail)
        }
        guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            throw Error.decodeFailed
        }
        return decoded
    }
}
