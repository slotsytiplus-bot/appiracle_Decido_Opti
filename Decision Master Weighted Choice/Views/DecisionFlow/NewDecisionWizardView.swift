import SwiftUI
import SwiftData

struct NewDecisionWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var navigationPath: NavigationPath
    @State private var title: String = ""
    @State private var goal: String = ""
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private let maxTitleLength = 100
    private let maxGoalLength = 500
    
    var body: some View {
        Form {
            Section {
                TextField("Decision Title", text: $title)
                    .textInputAutocapitalization(.words)
                    .onChange(of: title) { oldValue, newValue in
                        if newValue.count > maxTitleLength {
                            title = String(newValue.prefix(maxTitleLength))
                        }
                    }
                
                TextField("Goal or Description (Optional)", text: $goal, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: goal) { oldValue, newValue in
                        if newValue.count > maxGoalLength {
                            goal = String(newValue.prefix(maxGoalLength))
                        }
                    }
            } header: {
                Text("Decision Details")
            } footer: {
                Text("Give your decision a clear title to help you identify it later. Title: \(title.count)/\(maxTitleLength), Description: \(goal.count)/\(maxGoalLength)")
            }
        }
        .navigationTitle("New Decision")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    createDecision()
                } label: {
                    Text("Create")
                        .fontWeight(.semibold)
                }
                .disabled(!isValid)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }
    
    private var isValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        return !trimmedTitle.isEmpty && trimmedTitle.count >= 2 && trimmedTitle.count <= maxTitleLength
    }
    
    private func createDecision() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedGoal = goal.trimmingCharacters(in: .whitespaces)
        
        // Validate
        guard ValidationService.validateDecisionTitle(trimmedTitle) else {
            errorMessage = "Title must be between 2 and \(maxTitleLength) characters"
            showingError = true
            return
        }
        
        let decision = Decision(
            title: trimmedTitle,
            goal: trimmedGoal,
            selectedMethod: "Matrix"
        )
        
        do {
            modelContext.insert(decision)
            try modelContext.save()
            
            // Navigate to options input
            navigationPath.append(NavigationDestination.optionsInput(decision.id))
        } catch {
            errorMessage = "Failed to save decision: \(error.localizedDescription)"
            showingError = true
            modelContext.delete(decision)
        }
    }
}

#Preview {
    NewDecisionWizardView(navigationPath: .constant(NavigationPath()))
        .modelContainer(for: [Decision.self, Option.self, Criteria.self, Score.self], inMemory: true)
}
