// KettlebellGlyph.swift
// KB_Tracker
//
// Vector kettlebell mark (from theme.jsx Kettlebell). Single or double.
// Drawn in a 60×60 (single) / 100×60 (double) viewBox, scaled to `size`.

import SwiftUI

struct KettlebellGlyph: View {
    var size: CGFloat = 64
    var double: Bool = false
    var color: Color = AppColors.ink

    private var viewBoxWidth: CGFloat { double ? 100 : 60 }
    private let viewBoxHeight: CGFloat = 60
    private var renderHeight: CGFloat { size * (double ? 0.7 : 0.95) }

    var body: some View {
        Canvas { ctx, canvasSize in
            let sx = canvasSize.width / viewBoxWidth
            let sy = canvasSize.height / viewBoxHeight
            let transform = CGAffineTransform(scaleX: sx, y: sy)

            let offsets: [CGFloat] = double ? [0, 40] : [0]
            for dx in offsets {
                // Bell (filled)
                var bell = Path()
                bell.move(to: CGPoint(x: 14 + dx, y: 22))
                bell.addQuadCurve(to: CGPoint(x: 8 + dx, y: 38), control: CGPoint(x: 8 + dx, y: 26))
                bell.addQuadCurve(to: CGPoint(x: 30 + dx, y: 56), control: CGPoint(x: 8 + dx, y: 56))
                bell.addQuadCurve(to: CGPoint(x: 52 + dx, y: 38), control: CGPoint(x: 52 + dx, y: 56))
                bell.addQuadCurve(to: CGPoint(x: 46 + dx, y: 22), control: CGPoint(x: 52 + dx, y: 26))
                bell.closeSubpath()
                ctx.fill(bell.applying(transform), with: .color(color))

                // Handle (stroked)
                var handle = Path()
                handle.move(to: CGPoint(x: 18 + dx, y: 8))
                handle.addQuadCurve(to: CGPoint(x: 24 + dx, y: 22), control: CGPoint(x: 18 + dx, y: 18))
                handle.addLine(to: CGPoint(x: 36 + dx, y: 22))
                handle.addQuadCurve(to: CGPoint(x: 42 + dx, y: 8), control: CGPoint(x: 42 + dx, y: 18))
                ctx.stroke(handle.applying(transform), with: .color(color),
                           style: StrokeStyle(lineWidth: 3.5 * sx, lineCap: .round))
            }
        }
        .frame(width: size, height: renderHeight)
    }
}
