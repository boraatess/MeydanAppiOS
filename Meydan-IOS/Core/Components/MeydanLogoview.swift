//
//  MeydanLogoview.swift
//  Meydan-IOS
//
//  Created by bora ateş on 2.04.2026.
//

import Foundation
import SwiftUI

// Seçenek A: Figma'dan export edilen SVG'yi SwiftUI Path'e çevir
struct MeydanLogoView: View {
    var color: Color

    var body: some View {
        // Seçenek B: Eğer logo assets'te varsa:
        // Image("meydan_logo").renderingMode(.template).foregroundColor(color)

        Canvas { context, size in
            let w = size.width
            let h = size.height

            // M harfi path — Figma'daki değerlere göre güncelle
            var path = Path()
            path.move(to: CGPoint(x: w * 0.05, y: h * 0.95))
            path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.15))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.65))
            path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.15))
            path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.95))

            context.stroke(
                path,
                with: .color(color),
                style: StrokeStyle(lineWidth: w * 0.12,
                                    lineCap: .round,
                                    lineJoin: .round)
            )
        }
    }
}

// MARK: - Morphing M View
struct MorphingMView: View {
    var progress: CGFloat   // 0 → 1
    var color: Color

    // Sol shape parametreleri
    // progress=0: iki paralel pill
    // progress=1: M bacakları (eğimli üst)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let capW = w * 0.28
            let r = capW / 2

            // --- Sol Bacak ---
            let leftX   = lerp(w*0.22, w*0.05, progress)   // x pozisyon
            let leftTopY = lerp(h*0.12, h*0.12, progress)
            let leftBotH = lerp(h*0.76, h*0.76, progress)

            // --- Sağ Bacak ---
            let rightX  = lerp(w*0.50, w*0.67, progress)

            // --- Orta üçgen (M'nin V'si) sadece progress>0.5'te ---
            let vOpacity = max(0, (progress - 0.5) * 2)

            ZStack {
                // Sol capsule → sol M bacağı
                RoundedRectangle(cornerRadius: r)
                    .fill(color)
                    .frame(width: capW, height: leftBotH)
                    .offset(x: leftX - w/2 + capW/2,
                            y: leftTopY - h/2 + leftBotH/2)

                // Sağ capsule → sağ M bacağı
                RoundedRectangle(cornerRadius: r)
                    .fill(color)
                    .frame(width: capW, height: leftBotH)
                    .offset(x: rightX - w/2 + capW/2,
                            y: leftTopY - h/2 + leftBotH/2)

                // M'nin ortasındaki V çentik (beyaz/siyah üçgen overlay)
                // Arka plan rengiyle aynı renkte → negatif alan etkisi
                Triangle()
                    .fill(Color.black)   // bgColor ile eşleşmeli
                    .frame(width: capW * 1.2, height: h * 0.35)
                    .offset(y: -h * 0.10)
                    .opacity(vOpacity)
            }
        }
    }

    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

// MARK: - Üçgen Shape (M'nin V çentiği için)
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
// MARK: - Figma SVG'yi Swift Path'e çevirmek için:
// 1. Figma'da logoya sağ tıkla → "Copy as SVG"
// 2. SVG path d="..." değerini al
// 3. SwiftUI Path { path in path.addPath(...) } ile kullan
// Ya da direkt PNG/SVG olarak Assets.xcassets'e ekle (daha pratik)
