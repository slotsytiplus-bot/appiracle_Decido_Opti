import SwiftUI
import SwiftData
import Charts

struct ComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    let decisions: [Decision]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if decisions.count >= 2 {
                        comparisonChart
                        comparisonTable
                        insightsSection
                    } else {
                        Text("Select at least 2 decisions to compare")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Compare Decisions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options Comparison")
                .font(.headline)
                .padding(.horizontal, 4)
            
            chartView
        }
        .cardStyle()
    }
    
    private var chartView: some View {
        Chart {
            ForEach(chartData, id: \.id) { data in
                BarMark(
                    x: .value("Decision", data.decisionTitle),
                    y: .value("Score", data.score)
                )
                .foregroundStyle(by: .value("Option", data.optionName))
                .cornerRadius(4)
            }
        }
        .frame(height: 250)
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
        .chartLegend(position: .bottom, alignment: .center)
    }
    
    private struct ChartData {
        let id: UUID
        let decisionTitle: String
        let optionName: String
        let score: Double
    }
    
    private var chartData: [ChartData] {
        var data: [ChartData] = []
        for decision in decisions {
            guard let options = decision.options, !options.isEmpty else { continue }
            let decisionTitle = String(decision.title.prefix(10))
            for option in options {
                data.append(ChartData(
                    id: UUID(),
                    decisionTitle: decisionTitle,
                    optionName: option.name,
                    score: option.totalScore
                ))
            }
        }
        return data
    }
    
    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Comparison")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(decisions) { decision in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(decision.title)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let winner = decision.winner {
                                HStack {
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(.yellow)
                                    Text(winner.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            Text("Score: \(Int(decision.winner?.totalScore ?? 0))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            Text("Options: \(decision.options?.count ?? 0)")
                                .font(.caption)
                            Text("Criteria: \(decision.criteria?.count ?? 0)")
                                .font(.caption)
                            
                            if decision.isCompleted {
                                Label("Completed", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(width: 150)
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                InsightRow(
                    icon: "chart.bar.fill",
                    text: "Average score: \(String(format: "%.1f", averageScore))"
                )
                InsightRow(
                    icon: "trophy.fill",
                    text: "Highest score: \(highestScore)"
                )
                InsightRow(
                    icon: "list.bullet",
                    text: "Total options compared: \(totalOptions)"
                )
            }
        }
        .cardStyle()
    }
    
    private var averageScore: Double {
        let scores = decisions.compactMap { $0.winner?.totalScore }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private var highestScore: String {
        let maxDecision = decisions.max { ($0.winner?.totalScore ?? 0) < ($1.winner?.totalScore ?? 0) }
        if let decision = maxDecision, let winner = decision.winner {
            return "\(winner.name) (\(Int(winner.totalScore)))"
        }
        return "N/A"
    }
    
    private var totalOptions: Int {
        decisions.reduce(0) { $0 + ($1.options?.count ?? 0) }
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    ComparisonView(decisions: [])
        .modelContainer(for: [Decision.self, Option.self, Criteria.self, Score.self], inMemory: true)
}
