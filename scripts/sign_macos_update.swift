import CryptoKit
import Foundation

// The private seed arrives on stdin, never in arguments or logs.
do {
    guard CommandLine.arguments.count == 3 else {
        throw NSError(domain: "UpdateSigning", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Expected archive and public key paths"])
    }
    let encoded = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let encoded = encoded, let seed = Data(base64Encoded: encoded), seed.count == 32 else {
        throw NSError(domain: "UpdateSigning", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Invalid Ed25519 seed; expected a Base64 encoded 32-byte seed"])
    }
    let key = try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
    let expected = try String(contentsOfFile: CommandLine.arguments[2], encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard key.publicKey.rawRepresentation.base64EncodedString() == expected else {
        throw NSError(domain: "UpdateSigning", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "macOS signing key does not match the embedded public key"])
    }
    let archive = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]), options: .mappedIfSafe)
    print(try key.signature(for: archive).base64EncodedString())
} catch {
    FileHandle.standardError.write(Data("macOS update signing failed: \(error.localizedDescription)\n".utf8))
    exit(1)
}
