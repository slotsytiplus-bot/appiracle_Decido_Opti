import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            DashboardView()
                .environmentObject(themeManager)
        } else {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .scaleEffect(size)
                        .opacity(opacity)
                    
                    Text("Decision Master")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .opacity(opacity)
                    
                    Text("Weighted Choice")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.size = 0.9
                    self.opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
