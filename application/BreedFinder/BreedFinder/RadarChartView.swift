//
//  RadarChartView.swift
//  JSON_Handeling
//
//  Created by Yuval Savaryego Landesman on 27/04/2025.
//

import SwiftUI

struct RadarChartView: View {
    var categories: [String]
    var scores: [Double] // Expected between 0 and 10
    var animate: Bool
    
    @State private var animationProgress: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let angles = (0..<categories.count).map { angle(for: $0) }
            let maxRadius = size / 2 * 0.8
            
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.15),
                        Color.blue.opacity(0.05),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: maxRadius
                )
                .frame(width: size, height: size)

                // Draw background grid
                ForEach(1..<6) { step in
                    let radius = maxRadius * CGFloat(step) / 5.0
                    Path { path in
                        for i in 0..<categories.count {
                            let pt = point(at: angles[i], radius: radius, center: center)
                            if i == 0 {
                                path.move(to: pt)
                            } else {
                                path.addLine(to: pt)
                            }
                        }
                        path.closeSubpath()
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
                
                // Draw lines from center to corners
                ForEach(0..<categories.count, id: \.self) { index in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(at: angles[index], radius: maxRadius, center: center))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
                
                // Draw filled radar area
                Path { path in
                    for i in 0..<categories.count {
                        let radius = maxRadius * CGFloat(scores[i] / 10.0) * animationProgress
                        let pt = point(at: angles[i], radius: radius, center: center)
                        if i == 0 {
                            path.move(to: pt)
                        } else {
                            path.addLine(to: pt)
                        }
                    }
                    path.closeSubpath()
                }
                .fill(Color.blue.opacity(0.4))
                
                // Draw radar outline
                Path { path in
                    for i in 0..<categories.count {
                        let radius = maxRadius * CGFloat(scores[i] / 10.0) * animationProgress
                        let pt = point(at: angles[i], radius: radius, center: center)
                        if i == 0 {
                            path.move(to: pt)
                        } else {
                            path.addLine(to: pt)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // Labels
                ForEach(0..<categories.count, id: \.self) { i in
                    let pt = point(at: angles[i], radius: maxRadius + 35, center: center)
                    Text(categories[i])
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.primary)
                        .position(pt)
                }
            }
            .frame(width: size, height: size)
            .onAppear {
                if animate {
                    withAnimation(.easeOut(duration: 1.0)) {
                        animationProgress = 1.0
                    }
                } else {
                    animationProgress = 0.0
                }
            }
            .onChange(of: animate) {
                if animate {
                    animationProgress = 0.0
                    withAnimation(.easeOut(duration: 1.0)) {
                        animationProgress = 1.0
                    }
                } else {
                    withAnimation(.easeOut(duration: 1.0)) {
                        animationProgress = 0.0
                    }
                }
            }
            // (Removed fixed frame constraints; sizing now depends only on available space)
        }
    }
    
    func angle(for index: Int) -> Angle {
        .degrees(Double(index) / Double(categories.count) * 360 - 90)
    }
    
    func point(at angle: Angle, radius: CGFloat, center: CGPoint) -> CGPoint {
        CGPoint(
            x: center.x + cos(CGFloat(angle.radians)) * radius,
            y: center.y + sin(CGFloat(angle.radians)) * radius
        )
    }
}
