import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.primary.opacity(0.1), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
            )
    }
    
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.horizontal, 4)
    }
}
