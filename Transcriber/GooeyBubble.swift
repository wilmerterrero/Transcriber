import SwiftUI

struct GooeyBubble: View {
    // Configurable properties
    let size: CGFloat
    let baseColor: Color
    let isActive: Bool // Controls the gooey animation (e.g., recording state)
    
    // Animation states
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotOffset: CGFloat = 0.0
    
    // Default values
    private let blurRadius: CGFloat = 15
    private let pulseDuration: Double = 0.75
    
    init(size: CGFloat = 80, baseColor: Color = .primary, isActive: Bool = false) {
        self.size = size
        self.baseColor = baseColor
        self.isActive = isActive
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            // Resolve symbols for the two circles
            let baseCircle = context.resolveSymbol(id: 0)!
            let movingCircle = context.resolveSymbol(id: 1)!
            
            // Apply gooey effect with alpha threshold and blur
            context.addFilter(.alphaThreshold(min: 0.25, color: baseColor))
            context.addFilter(.blur(radius: blurRadius))
            
            // Draw the circles with blending
            context.drawLayer { context in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                context.draw(baseCircle, at: center)
                context.draw(movingCircle, at: center)
            }
        } symbols: {
            // Base circle
            Circle()
                .frame(width: size, height: size)
                .scaleEffect(pulseScale)
                .tag(0)
            
            // Moving circle for gooey effect
            Circle()
                .frame(width: size * 0.6, height: size * 0.6) // Smaller for gooey stretch
                .scaleEffect(isActive ? 1.0 : 0.5)
                .offset(y: dotOffset)
                .tag(1)
        }
        .frame(width: size + blurRadius * 2, height: size + blurRadius * 2) // Account for blur
        .onChange(of: isActive) { newValue in
            if newValue {
                // Start animations when active
                withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                    pulseScale = 1.15
                }
                withAnimation(.smooth(duration: 0.75)) {
                    dotOffset = -size * 1.5 // Move upward
                }
            } else {
                // Reset animations when inactive
                withAnimation(.smooth(duration: 0.75)) {
                    pulseScale = 1.0
                    dotOffset = 0
                }
            }
        }
        .allowsHitTesting(false) // Ensure it doesn’t block underlying views
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        GooeyBubble(size: 80, baseColor: .blue, isActive: false)
        GooeyBubble(size: 100, baseColor: .red, isActive: true)
    }
    .padding()
}