//
//  ConfettiView.swift
//  VioletVibes
//
//  Confetti animation similar to Messages app

import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    @Binding var isActive: Bool
    var emitterPosition: CGPoint = .zero
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isActive {
            addConfetti(to: uiView, position: emitterPosition)
            // Reset after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                isActive = false
                uiView.layer.sublayers?.removeAll { $0 is CAEmitterLayer }
            }
        } else {
            uiView.layer.sublayers?.removeAll { $0 is CAEmitterLayer }
        }
    }
    
    private func addConfetti(to view: UIView, position: CGPoint) {
        // Remove existing confetti layers
        view.layer.sublayers?.removeAll { $0 is CAEmitterLayer }
        
        // Use provided position or center of view
        let emitterPos = position != .zero ? position : CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        // Create confetti colors (similar to Messages app)
        let colors: [UIColor] = [
            .systemRed,
            .systemBlue,
            .systemGreen,
            .systemYellow,
            .systemPurple,
            .systemOrange,
            .systemPink,
            .systemTeal
        ]
        
        // Create multiple emitters for different effects
        for i in 0..<3 {
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = emitterPos
            emitter.emitterShape = .point
            emitter.emitterSize = CGSize(width: 20, height: 20)
            
            var cells: [CAEmitterCell] = []
            
            // Create confetti particles
            for (index, color) in colors.enumerated() {
                let cell = CAEmitterCell()
                
                // Use different shapes for variety
                let shape: ConfettiShape
                if index % 3 == 0 {
                    shape = .circle
                } else if index % 3 == 1 {
                    shape = .square
                } else {
                    shape = .triangle
                }
                
                cell.contents = shape.image(with: color).cgImage
                cell.birthRate = 15
                cell.lifetime = 3.0
                cell.velocity = CGFloat.random(in: 100...300)
                cell.velocityRange = 50
                cell.emissionRange = .pi * 2
                cell.spin = CGFloat.random(in: -3...3)
                cell.spinRange = 2
                cell.scale = 0.3
                cell.scaleRange = 0.2
                cell.color = color.cgColor
                cell.alphaSpeed = -0.3
                
                // Add slight delay for staggered effect
                cell.beginTime = Double(i) * 0.1
                
                cells.append(cell)
            }
            
            emitter.emitterCells = cells
            view.layer.addSublayer(emitter)
        }
    }
}

enum ConfettiShape {
    case circle
    case square
    case triangle
    
    func image(with color: UIColor) -> UIImage {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            color.setFill()
            
            switch self {
            case .circle:
                context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            case .square:
                context.cgContext.fill(CGRect(origin: .zero, size: size))
            case .triangle:
                let path = UIBezierPath()
                path.move(to: CGPoint(x: size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.close()
                path.fill()
            }
        }
    }
}
