import Foundation

struct Resultado {
    let estado: Int32
    let salida: String
    let error: String
}

enum Shell {
    @discardableResult
    static func run(_ ejecutable: String, _ args: [String]) -> Resultado {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: ejecutable)
        p.arguments = args
        let out = Pipe(), err = Pipe()
        p.standardOutput = out
        p.standardError = err
        do { try p.run() } catch {
            return Resultado(estado: -1, salida: "", error: error.localizedDescription)
        }
        let o = out.fileHandleForReading.readDataToEndOfFile()
        let e = err.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return Resultado(estado: p.terminationStatus,
                         salida: String(decoding: o, as: UTF8.self),
                         error: String(decoding: e, as: UTF8.self))
    }

    /// Ejecuta `diskutil <args>` y devuelve el plist parseado.
    static func diskutilPlist(_ args: [String]) -> [String: Any]? {
        let r = run("/usr/sbin/diskutil", args)
        guard r.estado == 0, let data = r.salida.data(using: .utf8) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    }
}
