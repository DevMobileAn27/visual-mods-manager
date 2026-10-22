import CryptoKit
import Foundation

// Run only to provision this app's macOS update key. Never rotate a published
// key implicitly: restoring a missing private key requires its original backup.
do {
    let fm = FileManager.default
    let directory = URL(fileURLWithPath: ".local-keys/macos-update", isDirectory: true)
    let privateFile = directory.appendingPathComponent("ed25519.key")
    let publicFile = URL(fileURLWithPath: "updates/macos_ed25519.pub")
    guard !fm.fileExists(atPath: publicFile.path) || fm.fileExists(atPath: privateFile.path) else {
        throw NSError(domain: "UpdateSigning", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Public key already exists; restore the original private key backup"])
    }
    try fm.createDirectory(at: directory, withIntermediateDirectories: true,
                           attributes: [.posixPermissions: 0o700])
    let key: Curve25519.Signing.PrivateKey
    if fm.fileExists(atPath: privateFile.path) {
        let encoded = try String(contentsOf: privateFile, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let seed = Data(base64Encoded: encoded), seed.count == 32 else {
            throw NSError(domain: "UpdateSigning", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid existing private key"])
        }
        key = try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
    } else {
        key = Curve25519.Signing.PrivateKey()
    }
    let publicKey = key.publicKey.rawRepresentation.base64EncodedString() + "\n"
    if fm.fileExists(atPath: publicFile.path) {
        let existing = try String(contentsOf: publicFile, encoding: .utf8)
        guard existing.trimmingCharacters(in: .whitespacesAndNewlines) == publicKey.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw NSError(domain: "UpdateSigning", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Existing public and private keys do not match"])
        }
    }
    if !fm.fileExists(atPath: privateFile.path) {
        try key.rawRepresentation.base64EncodedString().write(to: privateFile, atomically: true, encoding: .utf8)
    }
    try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: privateFile.path)
    try fm.createDirectory(at: publicFile.deletingLastPathComponent(), withIntermediateDirectories: true)
    try publicKey.write(to: publicFile, atomically: true, encoding: .utf8)
    print("macOS update key ready. Back up .local-keys/macos-update/ed25519.key privately.")
} catch {
    FileHandle.standardError.write(Data("Key provisioning failed: \(error.localizedDescription)\n".utf8))
    exit(1)
}
