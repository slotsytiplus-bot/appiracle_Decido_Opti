import SwiftUI
import SwiftData

struct OptionsInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var decision: Decision
    @Binding var navigationPath: NavigationPath
    @State private var newOptionName: String = ""
    @State private var errorMessage: String?
    @State private var showingError = false
    @FocusState private var isTextFieldFocused: Bool
    
    private let maxOptions = 20
    private let minOptions = 2
    
    var options: [Option] {
        decision.options ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !options.isEmpty {
                List {
                    ForEach(options) { option in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text(option.name)
                                .font(.body)
                        }
                    }
                    .onDelete(perform: deleteOptions)
                }
                .listStyle(.insetGrouped)
            } else {
                emptyStateView
            }
            
            Divider()
            
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    TextField("Enter option name", text: $newOptionName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            addOption()
                        }
                        .onChange(of: newOptionName) { oldValue, newValue in
                            if newValue.count > 100 {
                                newOptionName = String(newValue.prefix(100))
                            }
                        }
                    
                    Button {
                        addOption()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(canAddOption ? .blue : .gray)
                    }
                    .disabled(!canAddOption)
                }
                
                if !options.isEmpty {
                    Text("\(options.count)/\(maxOptions) options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Options")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    navigateToCriteria()
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
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Add Your Options")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Enter the choices you're deciding between (minimum \(minOptions), maximum \(maxOptions))")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var canAddOption: Bool {
        let trimmed = newOptionName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && options.count < maxOptions
    }
    
    private var canProceed: Bool {
        return options.count >= minOptions && options.count <= maxOptions
    }
    
    private func addOption() {
        let trimmedName = newOptionName.trimmingCharacters(in: .whitespaces)
        
        // Validate
        let existingNames = options.map { $0.name.trimmingCharacters(in: .whitespaces) }
        let validation = ValidationService.validateOptionName(trimmedName, existingOptions: existingNames)
        
        guard validation.isValid else {
            errorMessage = validation.errorMessage
            showingError = true
            return
        }
        
        guard options.count < maxOptions else {
            errorMessage = "Maximum \(maxOptions) options allowed"
            showingError = true
            return
        }
        
        let option = Option(name: trimmedName)
        decision.options?.append(option)
        modelContext.insert(option)
        
        do {
            try modelContext.save()
            newOptionName = ""
            isTextFieldFocused = true
        } catch {
            errorMessage = "Failed to save option: \(error.localizedDescription)"
            showingError = true
            decision.options?.removeAll { $0.id == option.id }
            modelContext.delete(option)
        }
    }
    
    private func deleteOptions(at offsets: IndexSet) {
        guard let options = decision.options else { return }
        for index in offsets {
            let option = options[index]
            modelContext.delete(option)
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete option: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func navigateToCriteria() {
        guard canProceed else {
            errorMessage = "Please add at least \(minOptions) options"
            showingError = true
            return
        }
        navigationPath.append(NavigationDestination.criteriaSetup(decision.id))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Decision.self, Option.self, Criteria.self, Score.self, configurations: config)
    let decision = Decision(title: "Test Decision", goal: "Test Goal")
    
    return OptionsInputView(decision: decision, navigationPath: .constant(NavigationPath()))
        .modelContainer(container)
}
