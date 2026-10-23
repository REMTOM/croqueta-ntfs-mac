// Genera assets/social-preview.png (1280x640), la imagen que muestran GitHub,
// WhatsApp, Telegram, etc. al compartir el enlace del repositorio.
// Uso: swift assets/make-social-preview.swift
import AppKit

let ancho: CGFloat = 1280, alto: CGFloat = 640
let carpeta = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let marino = NSColor(srgbRed: 0.06, green: 0.13, blue: 0.33, alpha: 1)
let naranja = NSColor(srgbRed: 0.93, green: 0.45, blue: 0.10, alpha: 1)
let gris = NSColor(srgbRed: 0.33, green: 0.37, blue: 0.45, alpha: 1)

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(ancho), pixelsHigh: Int(alto),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Fondo crema con una banda naranja abajo.
NSColor(srgbRed: 1.0, green: 0.97, blue: 0.92, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: ancho, height: alto).fill()
naranja.setFill()
NSRect(x: 0, y: 0, width: ancho, height: 14).fill()

// Croqueta a la izquierda.
if let croqueta = NSImage(contentsOf: carpeta.appendingPathComponent("croqueta.png")) {
    croqueta.draw(in: NSRect(x: 70, y: 90, width: 460, height: 460))
}

func fuente(_ tam: CGFloat, _ peso: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: tam, weight: peso)
    return base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: tam) } ?? base
}

func texto(_ s: String, _ f: NSFont, _ color: NSColor, x: CGFloat, y: CGFloat, kern: CGFloat = 0) {
    NSAttributedString(string: s, attributes: [.font: f, .foregroundColor: color, .kern: kern])
        .draw(at: NSPoint(x: x, y: y))
}

let x: CGFloat = 590
texto("CROQUETA", fuente(96, .black), marino, x: x, y: 400, kern: 2)
texto("DIGITAL", fuente(52, .heavy), marino, x: x + 4, y: 345, kern: 10)
naranja.setFill()
NSBezierPath(roundedRect: NSRect(x: x + 4, y: 318, width: 120, height: 8), xRadius: 4, yRadius: 4).fill()
texto("NTFS Write on Mac", fuente(54, .bold), naranja, x: x, y: 232)
texto("Lee y escribe discos de Windows en tu Mac", fuente(30, .medium), gris, x: x + 2, y: 178)
texto("desde la barra de menús · gratis y open source", fuente(30, .medium), gris, x: x + 2, y: 140)
texto("croquetadigital.es", fuente(32, .bold), marino, x: x + 2, y: 62)

NSGraphicsContext.current = nil
let salida = carpeta.appendingPathComponent("social-preview.png")
try! rep.representation(using: .png, properties: [:])!.write(to: salida)
print("OK: \(salida.path)")
