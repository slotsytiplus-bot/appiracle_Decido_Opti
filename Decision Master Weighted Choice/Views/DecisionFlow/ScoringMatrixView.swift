import SwiftUI
import SwiftData

struct ScoringMatrixView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var decision: Decision
    @Binding var navigationPath: NavigationPath
    @State private var currentOptionIndex: Int = 0
    
    var options: [Option] {
        decision.options ?? []
    }
    
    var criteria: [Criteria] {
        decision.criteria ?? []
    }
    
    var currentOption: Option? {
        guard currentOptionIndex < options.count else { return nil }
        return options[currentOptionIndex]
    }
    
    var progress: Double {
        guard !options.isEmpty else { return 0.0 }
        return Double(currentOptionIndex + 1) / Double(options.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let option = currentOption {
                VStack(spacing: 20) {
                    progressHeader(option: option)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(criteria) { criterion in
                                ScoringRowView(
                                    option: option,
                                    criterion: criterion,
                                    decision: decision,
                                    modelContext: modelContext
                                )
                                .id("\(option.id)-\(criterion.id)")
                            }
                        }
                        .padding()
                    }
                    .id(option.id)
                }
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Scoring Matrix")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(currentOptionIndex == options.count - 1 ? "Finish" : "Next") {
                    if currentOptionIndex < options.count - 1 {
                        currentOptionIndex += 1
                    } else {
                        calculateScores()
                        navigateToResults()
                    }
                }
                .fontWeight(.semibold)
                .disabled(!isCurrentOptionComplete)
            }
        }
    }
    
    private func progressHeader(option: Option) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Scoring: \(option.name)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(currentOptionIndex + 1) of \(options.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ProgressView(value: progress)
                .tint(.blue)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tablecells")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Options or Criteria")
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var isCurrentOptionComplete: Bool {
        guard let option = currentOption else { return false }
        let optionScores = option.scores ?? []
        return optionScores.count == criteria.count
    }
    
    private func calculateScores() {
        guard !options.isEmpty && !criteria.isEmpty else {
            return
        }
        
        for option in options {
            option.calculateTotalScore(criteria: criteria)
        }
        
        do {
            try modelContext.save()
        } catch {
            // Error handling - could show alert here if needed
            print("Failed to save scores: \(error.localizedDescription)")
        }
    }
    
    private func navigateToResults() {
        navigationPath.append(NavigationDestination.finalResult(decision.id))
    }
}

struct ScoringRowView: View {
    let option: Option
    let criterion: Criteria
    let decision: Decision
    let modelContext: ModelContext
    
    @State private var scoreValue: Double = 5.0
    
    var existingScore: Score? {
        option.scores?.first(where: { $0.criteria?.id == criterion.id })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(criterion.name)
                    .font(.headline)
                
                Spacer()
                
                Text("Weight: \(criterion.weight)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                Text("1")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $scoreValue, in: 1...10, step: 1)
                    .onChange(of: scoreValue) { oldValue, newValue in
                        saveScore()
                    }
                
                Text("10")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                Text("Score: \(Int(scoreValue))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onAppear {
            if let existing = existingScore {
                scoreValue = existing.value
            } else {
                saveScore()
            }
        }
    }
    
    private func saveScore() {
        guard ValidationService.validateScore(scoreValue) else {
            return
        }
        
        if let existing = existingScore {
            existing.value = scoreValue
        } else {
            let score = Score(value: scoreValue)
            score.option = option
            score.criteria = criterion
            option.scores?.append(score)
            criterion.scores?.append(score)
            modelContext.insert(score)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save score: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Decision.self, Option.self, Criteria.self, Score.self, configurations: config)
    let decision = Decision(title: "Test Decision", goal: "Test Goal")
    
    return ScoringMatrixView(decision: decision, navigationPath: .constant(NavigationPath()))
        .modelContainer(container)
}
