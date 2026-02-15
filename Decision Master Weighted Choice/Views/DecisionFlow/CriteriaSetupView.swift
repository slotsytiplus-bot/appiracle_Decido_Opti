import SwiftUI
import SwiftData

struct CriteriaSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var decision: Decision
    @Binding var navigationPath: NavigationPath
    @State private var newCriteriaName: String = ""
    @State private var newCriteriaWeight: Int = 5
    @State private var errorMessage: String?
    @State private var showingError = false
    @FocusState private var isTextFieldFocused: Bool
    
    private let maxCriteria = 15
    private let minCriteria = 1
    
    var criteria: [Criteria] {
        decision.criteria ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !criteria.isEmpty {
                List {
                    ForEach(criteria) { criterion in
                        CriteriaRowView(criterion: criterion)
                    }
                    .onDelete(perform: deleteCriteria)
                }
                .listStyle(.insetGrouped)
            } else {
                emptyStateView
            }
            
            Divider()
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Enter criteria name", text: $newCriteriaName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            addCriteria()
                        }
                        .onChange(of: newCriteriaName) { oldValue, newValue in
                            if newValue.count > 100 {
                                newCriteriaName = String(newValue.prefix(100))
                            }
                        }
                    
                    Button {
                        addCriteria()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(canAddCriteria ? .blue : .gray)
                    }
                    .disabled(!canAddCriteria)
                }
                
                if !newCriteriaName.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight: \(newCriteriaWeight)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { Double(newCriteriaWeight) },
                            set: { newCriteriaWeight = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                    .padding(.horizontal, 4)
                }
                
                if !criteria.isEmpty {
                    Text("\(criteria.count)/\(maxCriteria) criteria")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Criteria")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    navigateToScoring()
                }
                .disabled(!canProceed)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Define Your Criteria")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Add the factors that matter to your decision and assign weights (1-10). Minimum \(minCriteria), maximum \(maxCriteria) criteria.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var canAddCriteria: Bool {
        let trimmed = newCriteriaName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && criteria.count < maxCriteria
    }
    
    private var canProceed: Bool {
        return criteria.count >= minCriteria && criteria.count <= maxCriteria
    }
    
    private func addCriteria() {
        let trimmedName = newCriteriaName.trimmingCharacters(in: .whitespaces)
        
        // Validate
        let existingNames = criteria.map { $0.name.trimmingCharacters(in: .whitespaces) }
        let validation = ValidationService.validateCriteriaName(trimmedName, existingCriteria: existingNames)
        
        guard validation.isValid else {
            errorMessage = validation.errorMessage
            showingError = true
            return
        }
        
        guard ValidationService.validateWeight(newCriteriaWeight) else {
            errorMessage = "Weight must be between 1 and 10"
            showingError = true
            return
        }
        
        guard criteria.count < maxCriteria else {
            errorMessage = "Maximum \(maxCriteria) criteria allowed"
            showingError = true
            return
        }
        
        let criterion = Criteria(name: trimmedName, weight: newCriteriaWeight)
        decision.criteria?.append(criterion)
        modelContext.insert(criterion)
        
        do {
            try modelContext.save()
            newCriteriaName = ""
            newCriteriaWeight = 5
            isTextFieldFocused = true
        } catch {
            errorMessage = "Failed to save criteria: \(error.localizedDescription)"
            showingError = true
            decision.criteria?.removeAll { $0.id == criterion.id }
            modelContext.delete(criterion)
        }
    }
    
    private func deleteCriteria(at offsets: IndexSet) {
        guard let criteria = decision.criteria else { return }
        for index in offsets {
            let criterion = criteria[index]
            modelContext.delete(criterion)
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete criteria: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func navigateToScoring() {
        guard canProceed else {
            errorMessage = "Please add at least \(minCriteria) criterion"
            showingError = true
            return
        }
        navigationPath.append(NavigationDestination.scoringMatrix(decision.id))
    }
}

struct CriteriaRowView: View {
    @Bindable var criterion: Criteria
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(criterion.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Weight: \(criterion.weight)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    ForEach(1...10, id: \.self) { index in
                        Circle()
                            .fill(index <= criterion.weight ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            Spacer()
            
            Stepper("", value: $criterion.weight, in: 1...10)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Decision.self, Option.self, Criteria.self, Score.self, configurations: config)
    let decision = Decision(title: "Test Decision", goal: "Test Goal")
    
    return CriteriaSetupView(decision: decision, navigationPath: .constant(NavigationPath()))
        .modelContainer(container)
}
