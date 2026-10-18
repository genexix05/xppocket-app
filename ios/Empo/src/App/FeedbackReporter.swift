import Foundation
import GameProbe

/// Builds diagnostic bundles and submits feedback to XP Pocket.
enum FeedbackReporter {
    struct Context: Sendable {
        var gameTitle: String?
        var errorSummary: String?
        var container: GameContainer?
    }

    enum Error: LocalizedError {
        case emptyReport

        var errorDescription: String? {
            switch self {
            case .emptyReport: String(localized: "Could not prepare a feedback report.")
            }
        }
    }

    /// Files and text to pass to the system share sheet (Mail, Files, etc.).
    static func shareItems(for context: Context = Context()) throws -> [Any] {
        let reportURL = try writeReportFile(for: context)
        var items: [Any] = [reportURL]
        if let logURL = latestSessionLogURL(in: context.container) {
            items.append(logURL)
        }
        return items
    }

    /// POST a feedback report to `api.xppocket.app`. Falls back to the
    /// share sheet when the network call fails.
    @MainActor
    static func submit(_ context: Context = Context()) async throws {
        let body = try reportPayload(for: context)
        var request = URLRequest(
            url: CommunityLayoutAPI.baseURL.appendingPathComponent("v1/feedback"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Private

    private struct Payload: Encodable {
        let appName: String
        let appVersion: String
        let build: String
        let commit: String
        let dirty: Bool
        let gameTitle: String?
        let errorSummary: String?
        let logExcerpt: String?

        enum CodingKeys: String, CodingKey {
            case appName = "app_name"
            case appVersion = "app_version"
            case build, commit, dirty
            case gameTitle = "game_title"
            case errorSummary = "error_summary"
            case logExcerpt = "log_excerpt"
        }
    }

    private static func reportPayload(for context: Context) throws -> Payload {
        Payload(
            appName: AppInfo.name,
            appVersion: AppInfo.version,
            build: AppInfo.build,
            commit: GitInfo.commit,
            dirty: GitInfo.dirty,
            gameTitle: context.gameTitle,
            errorSummary: context.errorSummary,
            logExcerpt: logExcerpt(in: context.container)
        )
    }

    private static func writeReportFile(for context: Context) throws -> URL {
        let payload = try reportPayload(for: context)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        guard !data.isEmpty else { throw Error.emptyReport }

        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppInfo.name)-feedback-\(stamp).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func latestSessionLogURL(in container: GameContainer?) -> URL? {
        guard let container else { return nil }
        let logsDir = container.logsURL
        guard
            let files = try? FileManager.default.contentsOfDirectory(
                at: logsDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
        else { return nil }

        let sessionLogs = files.filter {
            $0.lastPathComponent != "session-history.log" && $0.pathExtension == "log"
        }
        guard !sessionLogs.isEmpty else { return nil }

        return sessionLogs.max {
            let d0 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let d1 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return d0 < d1
        }
    }

    private static func logExcerpt(in container: GameContainer?, maxBytes: Int = 48_000) -> String? {
        guard let logURL = latestSessionLogURL(in: container),
            let data = try? Data(contentsOf: logURL),
            !data.isEmpty
        else { return nil }
        if data.count <= maxBytes {
            return String(data: data, encoding: .utf8)
        }
        let tail = data.suffix(maxBytes)
        return String(data: tail, encoding: .utf8)
    }
}
