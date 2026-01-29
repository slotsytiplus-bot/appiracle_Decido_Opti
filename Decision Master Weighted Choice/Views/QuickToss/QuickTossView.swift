import SwiftUI

struct QuickTossView: View {
    @State private var option1: String = ""
    @State private var option2: String = ""
    @State private var isFlipping = false
    @State private var result: String = ""
    @State private var rotationAngle: Double = 0
    @State private var showResult = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if !showResult {
                        inputSection
                    } else {
                        resultSection
                    }
                }
                .padding()
            }
            .navigationTitle("Quick Toss")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 24) {
            Text("Advanced Coin Flip")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter two options and let fate decide")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                TextField("Option 1", text: $option1)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                
                TextField("Option 2", text: $option2)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
            }
            
            Button {
                flipCoin()
            } label: {
                HStack {
                    Image(systemName: "flip.horizontal.fill")
                    Text("Flip Coin")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canFlip ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canFlip || isFlipping)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
    
    private var resultSection: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .rotation3DEffect(
                        .degrees(rotationAngle),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .shadow(radius: 10)
                
                Text(result)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Text("The winner is:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(result)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Button {
                resetFlip()
            } label: {
                Label("Flip Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
    
    private var canFlip: Bool {
        !option1.trimmingCharacters(in: .whitespaces).isEmpty &&
        !option2.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func flipCoin() {
        isFlipping = true
        showResult = false
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.1).repeatCount(20, autoreverses: true)) {
            rotationAngle += 360
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let winner = Bool.random() ? option1 : option2
            result = winner
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showResult = true
                isFlipping = false
            }
        }
    }
    
    private func resetFlip() {
        withAnimation {
            rotationAngle = 0
            showResult = false
            result = ""
        }
    }
}

#Preview {
    QuickTossView()
}
