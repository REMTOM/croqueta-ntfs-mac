import SwiftUI

enum Marca {
    static let nombre = "Croqueta Digital NTFS Write on Mac"
    static let web = URL(string: "https://croquetadigital.es")!
    static let repo = URL(string: "https://github.com/REMTOM/croqueta-ntfs-mac")!

    /// Imagen del bundle (Contents/Resources); si falta, símbolo del sistema.
    static func imagen(_ nombre: String, puntos: CGFloat) -> Image {
        guard let url = Bundle.main.url(forResource: nombre, withExtension: "png"),
              let img = NSImage(contentsOf: url) else {
            return Image(systemName: "externaldrive.badge.checkmark")
        }
        img.size = NSSize(width: puntos, height: puntos)
        return Image(nsImage: img)
    }
}

@main
struct CroquetaNTFSApp: App {
    @StateObject private var discos = DiskManager()

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(discos)
        } label: {
            Marca.imagen("menubar", puntos: 20)
                .accessibilityLabel(Marca.nombre)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuView: View {
    @EnvironmentObject var discos: DiskManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Marca.imagen("croqueta", puntos: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Croqueta Digital").font(.headline)
                    Text("NTFS Write on Mac").font(.subheadline).foregroundStyle(.secondary)
                    Link("croquetadigital.es", destination: Marca.web).font(.caption)
                }
            }
            Divider()
            Text("Discos NTFS").font(.headline)

            if !discos.helperInstalado {
                Label("Helper no instalado. Ejecuta install.sh.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.callout)
            }

            if discos.volumenes.isEmpty {
                Text("No hay discos NTFS conectados.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(discos.volumenes) { v in
                    FilaVolumen(volumen: v)
                    Divider()
                }
            }

            if let error = discos.ultimoError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Toggle("Montar con escritura automáticamente", isOn: $discos.autoMontar)
            Toggle("Abrir al iniciar sesión", isOn: $discos.abrirAlIniciar)

            HStack {
                Button("Refrescar") { discos.refrescar() }
                Button("Web") { NSWorkspace.shared.open(Marca.web) }
                Button("GitHub") { NSWorkspace.shared.open(Marca.repo) }
                Spacer()
                Button("Salir") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(14)
        .frame(width: 340)
    }
}

struct FilaVolumen: View {
    @EnvironmentObject var discos: DiskManager
    let volumen: NTFSVolume

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "externaldrive.fill")
                VStack(alignment: .leading) {
                    Text(volumen.nombre).bold()
                    Text("\(volumen.id) · \(ByteCountFormatter.string(fromByteCount: volumen.tamano, countStyle: .file))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                estado
            }
            HStack {
                if discos.ocupados.contains(volumen.id) {
                    ProgressView().controlSize(.small)
                } else {
                    switch volumen.estado {
                    case .escritura:
                        Button("Abrir") { discos.abrirEnFinder(volumen) }
                        Button("Desmontar") { discos.desmontar(volumen) }
                    case .soloLectura:
                        Button("Activar escritura") { discos.montar(volumen) }
                        Button("Abrir") { discos.abrirEnFinder(volumen) }
                    case .desmontado:
                        Button("Montar con escritura") { discos.montar(volumen) }
                    }
                    Spacer()
                    Button("Expulsar") { discos.expulsar(volumen) }
                }
            }
            .controlSize(.small)
        }
    }

    @ViewBuilder private var estado: some View {
        switch volumen.estado {
        case .escritura:
            Text("Escritura").font(.caption).foregroundStyle(.green)
        case .soloLectura:
            Text("Solo lectura").font(.caption).foregroundStyle(.orange)
        case .desmontado:
            Text("Desmontado").font(.caption).foregroundStyle(.secondary)
        }
    }
}
