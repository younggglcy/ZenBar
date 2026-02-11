import AppKit

enum ZenBarIconRenderer {
    static func makeImage(size: CGFloat, highlighted: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: image.size)
        let inset: CGFloat = 1.5
        let circleRect = rect.insetBy(dx: inset, dy: inset)

        let strokeWidth: CGFloat = highlighted ? 1.9 : 1.4
        let strokeColor = NSColor.labelColor
        strokeColor.setStroke()

        let circle = NSBezierPath(ovalIn: circleRect)
        circle.lineWidth = strokeWidth
        circle.stroke()

        let lineCount = 3
        let lineSpacing = rect.height * 0.18
        let lineInset = rect.width * 0.30

        for index in 0..<lineCount {
            let y = rect.midY + CGFloat(index - 1) * lineSpacing
            let path = NSBezierPath()
            path.lineCapStyle = .round
            path.lineWidth = strokeWidth
            path.move(to: CGPoint(x: rect.minX + lineInset, y: y))
            path.line(to: CGPoint(x: rect.maxX - lineInset, y: y))
            path.stroke()
        }

        if highlighted {
            let dotRadius: CGFloat = 1.6
            let dotCenter = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.22)
            let dotRect = CGRect(
                x: dotCenter.x - dotRadius,
                y: dotCenter.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            let dot = NSBezierPath(ovalIn: dotRect)
            strokeColor.setFill()
            dot.fill()
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
