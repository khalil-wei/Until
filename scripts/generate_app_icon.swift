import AppKit
import CoreGraphics
import Foundation
import ImageIO

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1])

struct IconImage {
    let filename: String
    let size: Int
}

let images = [
    IconImage(filename: "Icon-20.png", size: 20),
    IconImage(filename: "Icon-20@2x.png", size: 40),
    IconImage(filename: "Icon-20@3x.png", size: 60),
    IconImage(filename: "Icon-29.png", size: 29),
    IconImage(filename: "Icon-29@2x.png", size: 58),
    IconImage(filename: "Icon-29@3x.png", size: 87),
    IconImage(filename: "Icon-40.png", size: 40),
    IconImage(filename: "Icon-40@2x.png", size: 80),
    IconImage(filename: "Icon-40@3x.png", size: 120),
    IconImage(filename: "Icon-60@2x.png", size: 120),
    IconImage(filename: "Icon-60@3x.png", size: 180),
    IconImage(filename: "Icon-76@2x.png", size: 152),
    IconImage(filename: "Icon-83.5@2x.png", size: 167),
    IconImage(filename: "Icon-1024.png", size: 1024)
]

func color(_ hex: UInt32) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xff) / 255
    let g = CGFloat((hex >> 8) & 0xff) / 255
    let b = CGFloat(hex & 0xff) / 255
    return CGColor(red: r, green: g, blue: b, alpha: 1)
}

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: y, width: w, height: h)
}

func drawRoundedRect(_ ctx: CGContext, _ rect: CGRect, radius: CGFloat) {
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
}

func drawIcon(size: Int) -> CGImage {
    let scale = CGFloat(size) / 1024
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    guard let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        fatalError("Unable to create graphics context")
    }

    ctx.scaleBy(x: scale, y: scale)
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    // Full-bleed background. iOS applies the final rounded mask.
    ctx.setFillColor(color(0x4FB9B4))
    ctx.fill(rect(0, 0, 1024, 1024))

    let bg = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [color(0x4FB9B4), color(0x087C87)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        bg,
        start: CGPoint(x: 160, y: 1024),
        end: CGPoint(x: 900, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    // A quiet lower wave keeps the icon tied to the previous direction without soft blur.
    ctx.saveGState()
    ctx.move(to: CGPoint(x: -80, y: 250))
    ctx.addCurve(to: CGPoint(x: 300, y: 325), control1: CGPoint(x: 80, y: 180), control2: CGPoint(x: 180, y: 360))
    ctx.addCurve(to: CGPoint(x: 1100, y: 245), control1: CGPoint(x: 560, y: 260), control2: CGPoint(x: 780, y: 420))
    ctx.addLine(to: CGPoint(x: 1100, y: -40))
    ctx.addLine(to: CGPoint(x: -80, y: -40))
    ctx.closePath()
    ctx.setFillColor(color(0xA8E0D2))
    ctx.fillPath()
    ctx.restoreGState()

    // Main date card.
    let shadowColor = CGColor(red: 0.02, green: 0.19, blue: 0.22, alpha: 0.18)
    let card = rect(218, 258, 588, 540)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 28, color: shadowColor)
    drawRoundedRect(ctx, card, radius: 88)
    ctx.setFillColor(color(0xFFF7EA))
    ctx.fillPath()
    ctx.restoreGState()

    // Header band.
    drawRoundedRect(ctx, rect(218, 646, 588, 152), radius: 88)
    ctx.setFillColor(color(0xFFE5C7))
    ctx.fillPath()
    ctx.saveGState()
    ctx.addRect(rect(218, 646, 588, 76))
    ctx.setFillColor(color(0xFFE5C7))
    ctx.fillPath()
    ctx.restoreGState()

    // Binder holes.
    for x in [365.0, 659.0] {
        ctx.setFillColor(color(0x087C87))
        ctx.fillEllipse(in: rect(CGFloat(x), 708, 54, 54))
    }

    // Date marks: three quiet days, one special day.
    let muted = color(0xD5CBBE)
    for x in [338.0, 456.0, 574.0] {
        ctx.setFillColor(muted)
        ctx.fillEllipse(in: rect(CGFloat(x), 503, 70, 70))
    }

    let targetCenter = CGPoint(x: 706, y: 538)

    // Approaching path.
    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setLineWidth(30)
    ctx.setStrokeColor(color(0xFF9B5E))
    ctx.move(to: CGPoint(x: 346, y: 318))
    ctx.addCurve(to: targetCenter, control1: CGPoint(x: 456, y: 365), control2: CGPoint(x: 623, y: 402))
    ctx.strokePath()
    ctx.restoreGState()

    // Highlighted day.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 0), blur: 24, color: CGColor(red: 1, green: 0.72, blue: 0.38, alpha: 0.5))
    ctx.setFillColor(color(0xFF684D))
    ctx.fillEllipse(in: rect(666, 498, 80, 80))
    ctx.restoreGState()

    // Tiny arrival notch: crisp cue that the path meets the target.
    ctx.setLineCap(.round)
    ctx.setLineWidth(16)
    ctx.setStrokeColor(color(0xFFFFFF))
    ctx.move(to: CGPoint(x: 689, y: 515))
    ctx.addLine(to: CGPoint(x: 710, y: 536))
    ctx.strokePath()

    guard let image = ctx.makeImage() else {
        fatalError("Unable to create image")
    }
    return image
}

func savePNG(_ image: CGImage, to url: URL) {
    guard
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else {
        fatalError("Unable to create PNG destination at \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Unable to encode PNG at \(url.path)")
    }
}

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

for icon in images {
    let image = drawIcon(size: icon.size)
    savePNG(image, to: outputDir.appendingPathComponent(icon.filename))
}
