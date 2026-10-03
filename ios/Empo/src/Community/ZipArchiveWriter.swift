import Foundation
import zlib

/// Minimal ZIP writer (stored entries, no compression). Enough for layout packs.
enum ZipArchiveWriter {
    struct Entry: Sendable {
        let path: String
        let data: Data
    }

    enum Error: LocalizedError {
        case invalidPath

        var errorDescription: String? {
            switch self {
            case .invalidPath: "Archive entry path is invalid."
            }
        }
    }

    static func archive(entries: [Entry]) throws -> Data {
        var archive = Data()
        var centralDirectory = Data()
        var offset: UInt32 = 0

        for entry in entries {
            guard !entry.path.contains(".."), !entry.path.hasPrefix("/") else {
                throw Error.invalidPath
            }
            let pathData = Data(entry.path.utf8)
            let crc = crc32(entry.data)
            let size = UInt32(entry.data.count)

            var local = Data()
            local.appendUInt32(0x0403_4b50)
            local.appendUInt16(20) // version needed
            local.appendUInt16(0) // flags
            local.appendUInt16(0) // stored
            local.appendUInt16(0) // mod time
            local.appendUInt16(0) // mod date
            local.appendUInt32(crc)
            local.appendUInt32(size)
            local.appendUInt32(size)
            local.appendUInt16(UInt16(pathData.count))
            local.appendUInt16(0) // extra length
            local.append(pathData)
            local.append(entry.data)

            archive.append(local)

            var central = Data()
            central.appendUInt32(0x0201_4b50)
            central.appendUInt16(20) // version made by
            central.appendUInt16(20) // version needed
            central.appendUInt16(0)
            central.appendUInt16(0)
            central.appendUInt16(0)
            central.appendUInt16(0)
            central.appendUInt32(crc)
            central.appendUInt32(size)
            central.appendUInt32(size)
            central.appendUInt16(UInt16(pathData.count))
            central.appendUInt16(0)
            central.appendUInt16(0)
            central.appendUInt16(0)
            central.appendUInt16(0)
            central.appendUInt32(0)
            central.appendUInt32(offset)
            central.append(pathData)
            centralDirectory.append(central)

            offset += UInt32(local.count)
        }

        archive.append(centralDirectory)

        var end = Data()
        end.appendUInt32(0x0605_4b50)
        end.appendUInt16(0)
        end.appendUInt16(0)
        end.appendUInt16(UInt16(entries.count))
        end.appendUInt16(UInt16(entries.count))
        end.appendUInt32(UInt32(centralDirectory.count))
        end.appendUInt32(offset)
        end.appendUInt16(0)
        archive.append(end)
        return archive
    }

    private static func crc32(_ data: Data) -> UInt32 {
        guard !data.isEmpty else { return 0 }
        return data.withUnsafeBytes { buffer in
            guard let base = buffer.bindMemory(to: Bytef.self).baseAddress else { return UInt32(0) }
            return UInt32(zlib.crc32(0, base, uInt(data.count)))
        }
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { append(contentsOf: $0) }
    }

    mutating func appendUInt32(_ value: UInt32) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { append(contentsOf: $0) }
    }
}
