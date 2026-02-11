#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET_DIR="$ROOT_DIR/assets/AppIcon.iconset"
ICNS_PATH="$ROOT_DIR/assets/ZenBar.icns"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

swift - <<'SWIFT'
import AppKit
import Foundation

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(origin: .zero, size: image.size)
NSColor.clear.setFill()
rect.fill()

let inset: CGFloat = size * 0.12
let circleRect = rect.insetBy(dx: inset, dy: inset)
let strokeWidth: CGFloat = size * 0.06
NSColor.black.setStroke()

let circle = NSBezierPath(ovalIn: circleRect)
circle.lineWidth = strokeWidth
circle.stroke()

let lineCount = 3
let lineSpacing = rect.height * 0.14
let lineInset = rect.width * 0.28

for index in 0..<lineCount {
    let y = rect.midY + CGFloat(index - 1) * lineSpacing
    let path = NSBezierPath()
    path.lineCapStyle = .round
    path.lineWidth = strokeWidth
    path.move(to: CGPoint(x: rect.minX + lineInset, y: y))
    path.line(to: CGPoint(x: rect.maxX - lineInset, y: y))
    path.stroke()
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to create PNG")
}

let url = URL(fileURLWithPath: "./assets/AppIcon.iconset/icon_1024x1024.png")
try png.write(to: url)
SWIFT

function gen() {
  local size=$1
  local name=$2
  /usr/bin/sips -z "$size" "$size" "$ICONSET_DIR/icon_1024x1024.png" --out "$ICONSET_DIR/$name" >/dev/null
}

gen 16 icon_16x16.png
gen 32 icon_16x16@2x.png
gen 32 icon_32x32.png
gen 64 icon_32x32@2x.png
gen 128 icon_128x128.png
gen 256 icon_128x128@2x.png
gen 256 icon_256x256.png
gen 512 icon_256x256@2x.png
gen 512 icon_512x512.png
gen 1024 icon_512x512@2x.png

/usr/bin/iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

echo "Generated: $ICNS_PATH"
