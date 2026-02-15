import SwiftUI
import SwiftData

struct DecisionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var decision: Decision
    @State private var showingDeleteAlert = false
    @State private var navigationPath = NavigationPath()
    
    var options: [Option] {
        (decision.options ?? []).sorted { $0.totalScore > $1.totalScore }
    }
    
    var isComplete: Bool {
        guard let options = decision.options, !options.isEmpty,
              let criteria = decision.criteria, !criteria.isEmpty else {
            return false
        }
        
        let totalScores = options.reduce(0) { sum, option in
            sum + (option.scores?.count ?? 0)
        }
        let expectedScores = options.count * criteria.count
        return totalScores == expectedScores
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if isComplete {
                        if let winner = decision.winner {
                            quickResultSection(winner: winner)
                        }
                    }
                    
                    optionsSection
                    
                    criteriaSection
                    
                    if isComplete {
                        Button {
                            navigateToResults()
                        } label: {
                            Label("View Full Results", systemImage: "chart.bar.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        Button {
                            continueDecision()
                        } label: {
                            Label("Continue Decision", systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    dangerSection
                }
                .padding()
            }
            .navigationTitle(decision.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Decision", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Decision", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteDecision()
                }
            } message: {
                Text("Are you sure you want to delete this decision? This action cannot be undone.")
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .optionsInput:
            OptionsInputView(decision: decision, navigationPath: $navigationPath)
        case .criteriaSetup:
            CriteriaSetupView(decision: decision, navigationPath: $navigationPath)
        case .scoringMatrix:
            ScoringMatrixView(decision: decision, navigationPath: $navigationPath)
        case .finalResult:
            FinalResultView(decision: decision, navigationPath: $navigationPath)
        default:
            EmptyView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !decision.goal.isEmpty {
                Text(decision.goal)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(decision.selectedMethod, systemImage: "slider.horizontal.3")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(decision.creationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func quickResultSection(winner: Option) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Winner: \(winner.name)")
                    .font(.headline)
            }
            
            Text("Score: \(Int(winner.totalScore))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
            
            ForEach(options) { option in
                HStack {
                    Text(option.name)
                        .font(.body)
                    
                    Spacer()
                    
                    if option.totalScore > 0 {
                        Text("\(Int(option.totalScore))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }
    
    private var criteriaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Criteria")
                .font(.headline)
            
            ForEach(decision.criteria ?? []) { criterion in
                HStack {
                    Text(criterion.name)
                        .font(.body)
                    
                    Spacer()
                    
                    Text("Weight: \(criterion.weight)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }
    
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundColor(.red)
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Decision", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
        }
    }
    
    private func continueDecision() {
        if decision.options?.isEmpty ?? true {
            navigationPath.append(NavigationDestination.optionsInput(decision.id))
        } else if decision.criteria?.isEmpty ?? true {
            navigationPath.append(NavigationDestination.criteriaSetup(decision.id))
        } else {
            navigationPath.append(NavigationDestination.scoringMatrix(decision.id))
        }
    }
    
    private func navigateToResults() {
        navigationPath.append(NavigationDestination.finalResult(decision.id))
    }
    
    private func deleteDecision() {
        modelContext.delete(decision)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete decision: \(error.localizedDescription)")
            // Could show alert here
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Decision.self, Option.self, Criteria.self, Score.self, configurations: config)
    let decision = Decision(title: "Test Decision", goal: "Test Goal")
    
    return NavigationStack {
        DecisionDetailView(decision: decision)
    }
    .modelContainer(container)
}
