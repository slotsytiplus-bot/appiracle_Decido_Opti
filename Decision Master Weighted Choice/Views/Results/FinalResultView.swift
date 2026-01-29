import SwiftUI
import SwiftData
import Charts

struct FinalResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var decision: Decision
    @Binding var navigationPath: NavigationPath
    @State private var showingShareSheet = false
    
    var options: [Option] {
        let opts = decision.options ?? []
        guard !opts.isEmpty else { return [] }
        return opts.sorted { $0.totalScore > $1.totalScore }
    }
    
    var winner: Option? {
        guard !options.isEmpty else { return nil }
        return options.first
    }
    
    var totalScoreSum: Double {
        guard !options.isEmpty else { return 0.0 }
        return options.reduce(0) { $0 + $1.totalScore }
    }
    
    var hasValidData: Bool {
        !options.isEmpty && options.allSatisfy { $0.totalScore > 0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if hasValidData, let winner = winner {
                    winnerSection(winner: winner)
                    
                    chartSection
                    
                    breakdownSection
                    
                    allResultsSection
                } else {
                    emptyStateView
                }
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    markAsCompleted()
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [generateShareText()])
        }
    }
    
    private func winnerSection(winner: Option) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Best Choice")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(winner.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Score: \(Int(winner.totalScore))")
                .font(.title2)
                .foregroundColor(.blue)
            
            if totalScoreSum > 0 {
                let percentage = (winner.totalScore / totalScoreSum) * 100
                Text("\(Int(percentage))% of total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score Distribution")
                .font(.headline)
                .padding(.horizontal, 4)
            
            Chart {
                ForEach(options) { option in
                    BarMark(
                        x: .value("Option", option.name),
                        y: .value("Score", option.totalScore)
                    )
                    .foregroundStyle(option.id == winner?.id ? Color.blue : Color.gray.opacity(0.6))
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.caption)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mathematical Breakdown")
                .font(.headline)
            
            if let winner = winner, let criteria = decision.criteria {
                ForEach(criteria) { criterion in
                    if let score = winner.scores?.first(where: { $0.criteria?.id == criterion.id }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(criterion.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Score: \(Int(score.value)) × Weight: \(criterion.weight)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(score.value * Double(criterion.weight)))")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total Score")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(Int(winner.totalScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var allResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Results")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                HStack {
                    Text("#\(index + 1)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                    
                    Text(option.name)
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(Int(option.totalScore))")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(index == 0 ? Color.blue.opacity(0.1) : Color(.systemGroupedBackground))
                .cornerRadius(8)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Results Available")
                .font(.title3)
                .fontWeight(.semibold)
            
            if options.isEmpty {
                Text("Please add options and complete scoring to see results.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Please complete scoring for all options to see results.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func markAsCompleted() {
        decision.isCompleted = true
        do {
            try modelContext.save()
        } catch {
            print("Failed to mark decision as completed: \(error.localizedDescription)")
            // Revert on error
            decision.isCompleted = false
        }
    }
    
    private func generateShareText() -> String {
        return ExportService.exportToText(decision)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Decision.self, Option.self, Criteria.self, Score.self, configurations: config)
    let decision = Decision(title: "Test Decision", goal: "Test Goal")
    
    return FinalResultView(decision: decision, navigationPath: .constant(NavigationPath()))
        .modelContainer(container)
}
