import AppKit

let S: CGFloat = 1024
let inset: CGFloat = 90
let rect = CGRect(x: inset, y: inset, width: S - inset * 2, height: S - inset * 2)
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor { CGColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: 1) }
func grad(_ a: CGColor, _ b: CGColor) -> CGGradient {
    CGGradient(colorsSpace: cs, colors: [a, b] as CFArray, locations: [0, 1])!
}

let squircle = CGPath(roundedRect: rect, cornerWidth: 200, cornerHeight: 200, transform: nil)
ctx.saveGState()
ctx.addPath(squircle); ctx.clip()

// Giorno: metà in alto a sinistra
ctx.drawLinearGradient(grad(rgb(126, 200, 240), rgb(32, 118, 180)),
                       start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])
// Sole
ctx.setFillColor(rgb(255, 214, 92))
ctx.fillEllipse(in: CGRect(x: 250, y: 620, width: 165, height: 165))

// Notte: metà in basso a destra, separata da una diagonale
ctx.saveGState()
let night = CGMutablePath()
night.move(to: CGPoint(x: S, y: S)); night.addLine(to: CGPoint(x: S, y: 0))
night.addLine(to: CGPoint(x: 0, y: 0)); night.closeSubpath()
ctx.addPath(night); ctx.clip()
ctx.drawLinearGradient(grad(rgb(38, 52, 92), rgb(9, 13, 28)),
                       start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])
// Luna a falce: cerchio pieno meno un cerchio sfalsato
ctx.saveGState()
let moon = CGRect(x: 600, y: 245, width: 170, height: 170)
ctx.addEllipse(in: moon)
ctx.clip()                                   // resta dentro il disco lunare
ctx.addEllipse(in: moon)
ctx.addEllipse(in: moon.offsetBy(dx: 52, dy: 36))
ctx.clip(using: .evenOdd)                    // ...meno il disco sfalsato = falce
ctx.setFillColor(rgb(238, 242, 255))
ctx.fill(moon)
ctx.restoreGState()
// Stelline
ctx.setFillColor(rgb(226, 234, 255))
for (x, y, r) in [(430.0, 250.0, 9.0), (520.0, 170.0, 6.0), (830.0, 460.0, 7.0), (350.0, 160.0, 5.0)] {
    ctx.fillEllipse(in: CGRect(x: x, y: y, width: r * 2, height: r * 2))
}
ctx.restoreGState()

// Linea di separazione appena accennata
ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.18))
ctx.setLineWidth(6)
ctx.move(to: CGPoint(x: 0, y: 0)); ctx.addLine(to: CGPoint(x: S, y: S)); ctx.strokePath()
ctx.restoreGState()

// Bordo
ctx.addPath(squircle)
ctx.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.22))
ctx.setLineWidth(4); ctx.strokePath()

let img = ctx.makeImage()!
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
_ = CGImageDestinationFinalize(dest)
print("icona 1024 scritta:", out.path)
