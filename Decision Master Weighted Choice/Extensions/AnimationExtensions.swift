import SwiftUI

extension View {
    func fadeInAnimation(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }
    
    func slideInAnimation(from: Edge = .trailing, delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(from: from, delay: delay))
    }
    
    func scaleInAnimation(delay: Double = 0) -> some View {
        self.modifier(ScaleInModifier(delay: delay))
    }
}

struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

struct SlideInModifier: ViewModifier {
    let from: Edge
    let delay: Double
    @State private var hasAppeared = false
    
    private var initialOffset: CGFloat {
        hasAppeared ? 0 : 100
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: from == .leading ? -initialOffset : (from == .trailing ? initialOffset : 0),
                   y: from == .top ? -initialOffset : (from == .bottom ? initialOffset : 0))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

struct ScaleInModifier: ViewModifier {
    let delay: Double
    @State private var scale: CGFloat = 0.8
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    scale = 1.0
                }
            }
    }
}
