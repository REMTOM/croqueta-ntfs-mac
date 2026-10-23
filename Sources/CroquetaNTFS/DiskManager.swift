import Foundation
import DiskArbitration
import ServiceManagement

struct NTFSVolume: Identifiable, Equatable {
    enum Estado: Equatable {
        case soloLectura(String)
        case escritura(String)
        case desmontado
    }

    let id: String          // p. ej. disk4s1
    let nombre: String
    let tamano: Int64
    var estado: Estado

    var discoEntero: String {
        id.replacingOccurrences(of: #"s\d+$"#, with: "", options: .regularExpression)
    }
}

@MainActor
final class DiskManager: ObservableObject {
    nonisolated static let helper = "/Library/PrivilegedHelperTools/croqueta-ntfs-helper"

    @Published private(set) var volumenes: [NTFSVolume] = []
    @Published private(set) var ocupados: Set<String> = []
    @Published var ultimoError: String?
    @Published var autoMontar: Bool {
        didSet { UserDefaults.standard.set(autoMontar, forKey: "autoMontar") }
    }
    @Published var abrirAlIniciar: Bool {
        didSet { cambiarInicioSesion(abrirAlIniciar) }
    }

    /// Particiones ya identificadas como NTFS. Al montarlas con ntfs-3g diskutil deja de
    /// informar "ntfs", así que se recuerdan mientras sigan conectadas.
    private var conocidosNTFS = Set<String>()
    /// Particiones que el usuario desmontó o que fallaron: no se automontan de nuevo
    /// hasta que se desconecten.
    private var sinAutoMontar = Set<String>()
    private var session: DASession?
    private var refrescoPendiente = false

    var helperInstalado: Bool { FileManager.default.isExecutableFile(atPath: Self.helper) }

    init() {
        autoMontar = UserDefaults.standard.object(forKey: "autoMontar") as? Bool ?? true
        abrirAlIniciar = SMAppService.mainApp.status == .enabled
        // Primera ejecución: abrir al iniciar sesión activado por defecto.
        if !UserDefaults.standard.bool(forKey: "configuradoInicio") {
            UserDefaults.standard.set(true, forKey: "configuradoInicio")
            if !abrirAlIniciar { abrirAlIniciar = true }
        }
        iniciarDiskArbitration()
        refrescar()
    }

    // MARK: - Eventos de discos

    private func iniciarDiskArbitration() {
        guard let s = DASessionCreate(kCFAllocatorDefault) else { return }
        session = s
        let ctx = Unmanaged.passUnretained(self).toOpaque()

        let cambio: DADiskAppearedCallback = { _, ctx in
            guard let ctx else { return }
            let m = Unmanaged<DiskManager>.fromOpaque(ctx).takeUnretainedValue()
            MainActor.assumeIsolated { m.programarRefresco() }
        }
        DARegisterDiskAppearedCallback(s, nil, cambio, ctx)
        DARegisterDiskDisappearedCallback(s, nil, cambio, ctx)
        DARegisterDiskDescriptionChangedCallback(s, nil, nil, { _, _, ctx in
            guard let ctx else { return }
            let m = Unmanaged<DiskManager>.fromOpaque(ctx).takeUnretainedValue()
            MainActor.assumeIsolated { m.programarRefresco() }
        }, ctx)
        DASessionScheduleWithRunLoop(s, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }

    /// Agrupa ráfagas de eventos (un disco genera varios) en un solo escaneo.
    func programarRefresco() {
        guard !refrescoPendiente else { return }
        refrescoPendiente = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refrescoPendiente = false
            self?.refrescar()
        }
    }

    func refrescar() {
        let conocidos = conocidosNTFS
        Task.detached {
            let (vols, ids) = DiskManager.escanear(conocidos: conocidos)
            await self.aplicar(vols, ids)
        }
    }

    private func aplicar(_ vols: [NTFSVolume], _ ids: Set<String>) {
        conocidosNTFS = ids
        sinAutoMontar.formIntersection(ids)
        volumenes = vols
        guard autoMontar, helperInstalado else { return }
        for v in vols where !esEscritura(v) && !sinAutoMontar.contains(v.id) && !ocupados.contains(v.id) {
            montar(v)
        }
    }

    private func esEscritura(_ v: NTFSVolume) -> Bool {
        if case .escritura = v.estado { return true }
        return false
    }

    // MARK: - Escaneo (fuera del hilo principal)

    nonisolated static func escanear(conocidos: Set<String>) -> ([NTFSVolume], Set<String>) {
        guard let lista = Shell.diskutilPlist(["list", "-plist", "external"]),
              let discos = lista["AllDisksAndPartitions"] as? [[String: Any]] else {
            return ([], [])
        }
        let montajes = tablaMontajes()
        var vols: [NTFSVolume] = []
        var ids = Set<String>()

        for disco in discos {
            for p in disco["Partitions"] as? [[String: Any]] ?? [] {
                guard let id = p["DeviceIdentifier"] as? String else { continue }
                let contenido = p["Content"] as? String ?? ""
                guard ["Microsoft Basic Data", "Windows_NTFS"].contains(contenido) else { continue }

                var esNTFS = conocidos.contains(id)
                if !esNTFS, let info = Shell.diskutilPlist(["info", "-plist", id]) {
                    esNTFS = (info["FilesystemType"] as? String) == "ntfs"
                }
                guard esNTFS else { continue }
                ids.insert(id)

                let estado: NTFSVolume.Estado
                if let m = montajes[id] {
                    estado = m.tipo.contains("fuse") ? .escritura(m.ruta) : .soloLectura(m.ruta)
                } else {
                    estado = .desmontado
                }
                let nombre = (p["VolumeName"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? id
                let tamano = (p["Size"] as? NSNumber)?.int64Value ?? 0
                vols.append(NTFSVolume(id: id, nombre: nombre, tamano: tamano, estado: estado))
            }
        }
        return (vols, ids)
    }

    /// Mapa "diskXsY" -> (tipo de sistema de archivos, punto de montaje).
    nonisolated static func tablaMontajes() -> [String: (tipo: String, ruta: String)] {
        var buf: UnsafeMutablePointer<statfs>?
        let n = getmntinfo(&buf, MNT_NOWAIT)
        guard n > 0, let buf else { return [:] }
        var res: [String: (tipo: String, ruta: String)] = [:]
        for i in 0..<Int(n) {
            var s = buf[i]
            let desde = cadena(&s.f_mntfromname)
            let tipo = cadena(&s.f_fstypename)
            let ruta = cadena(&s.f_mntonname)
            guard desde.hasPrefix("/dev/") else { continue }
            res[String(desde.dropFirst(5))] = (tipo, ruta)
        }
        return res
    }

    nonisolated private static func cadena<T>(_ tupla: inout T) -> String {
        withUnsafeBytes(of: &tupla) { raw in
            String(cString: raw.bindMemory(to: CChar.self).baseAddress!)
        }
    }

    // MARK: - Acciones

    func montar(_ v: NTFSVolume) {
        ejecutarHelper("mount", v)
    }

    func desmontar(_ v: NTFSVolume) {
        sinAutoMontar.insert(v.id)
        ejecutarHelper("unmount", v)
    }

    func expulsar(_ v: NTFSVolume) {
        sinAutoMontar.insert(v.id)
        ejecutarHelper("unmount", v) { [weak self] ok in
            guard ok else { return }
            let r = Shell.run("/usr/sbin/diskutil", ["eject", v.discoEntero])
            if r.estado != 0 {
                self?.ultimoError = "No se pudo expulsar \(v.nombre): \(r.error.isEmpty ? r.salida : r.error)"
            }
        }
    }

    func abrirEnFinder(_ v: NTFSVolume) {
        switch v.estado {
        case .escritura(let ruta), .soloLectura(let ruta):
            Shell.run("/usr/bin/open", [ruta])
        case .desmontado:
            break
        }
    }

    private func ejecutarHelper(_ orden: String, _ v: NTFSVolume, despues: ((Bool) -> Void)? = nil) {
        guard helperInstalado else {
            ultimoError = "Falta el helper. Ejecuta install.sh."
            return
        }
        ocupados.insert(v.id)
        ultimoError = nil
        Task.detached {
            let r = Shell.run("/usr/bin/sudo", ["-n", DiskManager.helper, orden, v.id])
            await MainActor.run {
                self.ocupados.remove(v.id)
                if r.estado != 0 {
                    if orden == "mount" { self.sinAutoMontar.insert(v.id) }
                    let msg = (r.error.isEmpty ? r.salida : r.error).trimmingCharacters(in: .whitespacesAndNewlines)
                    self.ultimoError = msg.contains("password")
                        ? "sudo pide contraseña: vuelve a ejecutar install.sh."
                        : "\(v.nombre): \(msg)"
                }
                despues?(r.estado == 0)
                self.refrescar()
            }
        }
    }

    private func cambiarInicioSesion(_ activar: Bool) {
        do {
            if activar { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            ultimoError = "Inicio de sesión: \(error.localizedDescription)"
        }
    }
}
