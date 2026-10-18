import Foundation

/// Remote layout catalog served by `api.xppocket.app`.
enum CommunityLayoutAPI {
    static let baseURL = URL(string: "https://api.xppocket.app")!

    struct LayoutSummary: Codable, Identifiable, Sendable {
        let id: String
        let name: String
        let description: String
        let author: String
        let tags: [String]
        let previewURL: URL?
        let downloads: Int
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case id, name, description, author, tags, downloads
            case previewURL = "preview_url"
            case updatedAt = "updated_at"
        }
    }

    struct ListResponse: Codable, Sendable {
        let layouts: [LayoutSummary]
        let total: Int
    }

    enum Error: LocalizedError {
        case badStatus(Int)
        case decodeFailed
        case uploadRejected(String)

        var errorDescription: String? {
            switch self {
            case .badStatus(let code): String(localized: "Server responded with HTTP \(code).")
            case .decodeFailed: String(localized: "Could not read the layout catalog.")
            case .uploadRejected(let detail): detail
            }
        }
    }

    static func fetchCatalog(session: URLSession = .shared) async throws -> [LayoutSummary] {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/layouts"))
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw Error.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        guard let decoded = try? JSONDecoder().decode(ListResponse.self, from: data) else {
            throw Error.decodeFailed
        }
        return decoded.layouts
    }

    static func downloadPack(
        layoutID: String, session: URLSession = .shared
    ) async throws -> Data {
        let url = baseURL.appendingPathComponent("v1/layouts/\(layoutID)/pack")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw Error.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        guard !data.isEmpty else { throw Error.decodeFailed }
        return data
    }

    /// Uploads a new layout pack (POST). Fails with 409 if the id already exists.
    static func uploadLayout(
        metadata: LayoutPackExporter.Metadata,
        packData: Data,
        adminKey: String,
        session: URLSession = .shared
    ) async throws -> LayoutSummary {
        try await publishLayout(
            metadata: metadata,
            packData: packData,
            adminKey: adminKey,
            replaceExisting: false,
            session: session)
    }

    /// Replaces an existing catalog entry (PUT). Fails with 404 if the id is unknown.
    static func updateLayout(
        layoutID: String,
        metadata: LayoutPackExporter.Metadata,
        packData: Data,
        adminKey: String,
        session: URLSession = .shared
    ) async throws -> LayoutSummary {
        var meta = metadata
        meta.id = layoutID
        return try await publishLayout(
            metadata: meta,
            packData: packData,
            adminKey: adminKey,
            replaceExisting: true,
            session: session)
    }

    /// Creates or updates depending on `replaceExisting`.
    static func publishLayout(
        metadata: LayoutPackExporter.Metadata,
        packData: Data,
        adminKey: String,
        replaceExisting: Bool,
        session: URLSession = .shared
    ) async throws -> LayoutSummary {
        let trimmedKey = adminKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw Error.uploadRejected(String(localized: "Admin key is required."))
        }
        guard !packData.isEmpty else {
            throw Error.uploadRejected(String(localized: "Pack file is empty."))
        }

        let body = multipartBody(metadata: metadata, packData: packData, includeID: !replaceExisting)
        let path = replaceExisting
            ? "v1/layouts/\(metadata.id)"
            : "v1/layouts"
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = replaceExisting ? "PUT" : "POST"
        request.setValue("multipart/form-data; boundary=\(body.boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(trimmedKey, forHTTPHeaderField: "X-Admin-Key")
        request.httpBody = body.data

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw Error.badStatus(-1)
        }
        if !(200 ... 299).contains(http.statusCode) {
            let detail = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
                ?? String(data: data, encoding: .utf8)
                ?? "HTTP \(http.statusCode)"
            throw Error.uploadRejected(detail)
        }
        return try decodeSummary(from: data)
    }

    private struct MultipartBody {
        let boundary: String
        let data: Data
    }

    private static func multipartBody(
        metadata: LayoutPackExporter.Metadata,
        packData: Data,
        includeID: Bool
    ) -> MultipartBody {
        let boundary = "XPPocket-\(UUID().uuidString)"
        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        if includeID {
            appendField("id", metadata.id)
        }
        appendField("name", metadata.name)
        appendField("description", metadata.description)
        appendField("author", metadata.author)
        appendField("tags", metadata.tags.joined(separator: ","))

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"pack\"; filename=\"\(metadata.id).zip\"\r\n"
                .data(using: .utf8)!)
        body.append("Content-Type: application/zip\r\n\r\n".data(using: .utf8)!)
        body.append(packData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return MultipartBody(boundary: boundary, data: body)
    }

    private static func decodeSummary(from data: Data) throws -> LayoutSummary {
        struct DetailResponse: Codable {
            let id: String
            let name: String
            let description: String
            let author: String
            let tags: [String]
            let previewURL: URL?
            let downloads: Int
            let updatedAt: String

            enum CodingKeys: String, CodingKey {
                case id, name, description, author, tags, downloads
                case previewURL = "preview_url"
                case updatedAt = "updated_at"
            }
        }
        guard let decoded = try? JSONDecoder().decode(DetailResponse.self, from: data) else {
            throw Error.decodeFailed
        }
        return LayoutSummary(
            id: decoded.id,
            name: decoded.name,
            description: decoded.description,
            author: decoded.author,
            tags: decoded.tags,
            previewURL: decoded.previewURL,
            downloads: decoded.downloads,
            updatedAt: decoded.updatedAt)
    }
}
