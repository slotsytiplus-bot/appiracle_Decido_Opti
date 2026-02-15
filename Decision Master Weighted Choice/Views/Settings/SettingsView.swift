import SwiftUI
import SwiftData
import Charts

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Query(sort: \Decision.creationDate, order: .reverse) private var allDecisions: [Decision]
    @State private var selectedDecision: Decision?
    
    var archivedDecisions: [Decision] {
        allDecisions.filter { $0.isCompleted }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                
                statisticsSection
                
                templatesSection
                
                exportSection
                
                archiveSection
                
                theorySection
                
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationDestination(item: $selectedDecision) { decision in
                ExportOptionsView(decision: decision)
            }
        }
    }
    
    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: Binding(
                get: { themeManager.selectedTheme },
                set: { newValue in
                    themeManager.selectedTheme = newValue
                }
            )) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName)
                        .tag(theme.rawValue)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        } footer: {
            Text("Choose between light, dark, or system theme that follows your device settings.")
        }
    }
    
    private var statisticsSection: some View {
        Section {
            NavigationLink {
                StatisticsView(decisions: allDecisions)
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("View Statistics")
                }
            }
        } header: {
            Text("Analytics")
        } footer: {
            Text("See detailed statistics about your decision-making activity.")
        }
    }
    
    private var templatesSection: some View {
        Section {
            NavigationLink {
                TemplatesView()
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.green)
                    Text("Decision Templates")
                }
            }
        } header: {
            Text("Templates")
        } footer: {
            Text("Start with pre-configured templates for common decision scenarios.")
        }
    }
    
    private var exportSection: some View {
        Section {
            if archivedDecisions.isEmpty {
                HStack {
                    Text("No decisions to export")
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(archivedDecisions.prefix(5)) { decision in
                    NavigationLink {
                        ExportOptionsView(decision: decision)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(decision.title)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(decision.creationDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Export Decisions")
        } footer: {
            Text("Export your completed decisions as text or CSV files.")
        }
    }
    
    private var archiveSection: some View {
        Section {
            if archivedDecisions.isEmpty {
                HStack {
                    Text("No archived decisions")
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(archivedDecisions) { decision in
                    NavigationLink {
                        DecisionDetailView(decision: decision)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(decision.title)
                                .font(.body)
                            
                            Text(decision.creationDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteArchivedDecisions)
            }
        } header: {
            Text("Archive")
        } footer: {
            Text("Completed decisions are automatically archived. Swipe to delete.")
        }
    }
    
    private var theorySection: some View {
        Section {
            NavigationLink {
                TheoryView()
            } label: {
                HStack {
                    Image(systemName: "book.fill")
                    Text("Theory of Decision Making")
                }
            }
        } header: {
            Text("Learn More")
        }
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("App Name")
                Spacer()
                Text("Decision Master: Weighted Choice")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Total Decisions")
                Spacer()
                Text("\(allDecisions.count)")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("About")
        }
    }
    
    private func deleteArchivedDecisions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(archivedDecisions[index])
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete archived decisions: \(error.localizedDescription)")
        }
    }
}

struct StatisticsView: View {
    let decisions: [Decision]
    
    private var statistics: DecisionStatistics {
        StatisticsService.getStatistics(for: decisions)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    overviewCards
                    detailedStats
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(title: "Total", value: "\(statistics.totalDecisions)", icon: "doc.text.fill", color: .blue)
            StatCard(title: "Completed", value: "\(statistics.completedDecisions)", icon: "checkmark.circle.fill", color: .green)
            StatCard(title: "Active", value: "\(statistics.activeDecisions)", icon: "clock.fill", color: .orange)
            StatCard(title: "This Week", value: "\(statistics.recentDecisions)", icon: "calendar", color: .purple)
        }
    }
    
    private var detailedStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Statistics")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                StatRow(label: "Total Options", value: "\(statistics.totalOptions)")
                StatRow(label: "Total Criteria", value: "\(statistics.totalCriteria)")
                StatRow(label: "Avg Options/Decision", value: String(format: "%.1f", statistics.averageOptions))
                StatRow(label: "Avg Criteria/Decision", value: String(format: "%.1f", statistics.averageCriteria))
                StatRow(label: "Most Used Method", value: statistics.mostUsedMethod)
            }
            .cardStyle()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDecision: Decision?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose a template to quickly start a new decision with pre-configured options and criteria.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(TemplateService.templates, id: \.name) { template in
                        TemplateCard(template: template) {
                            let decision = TemplateService.createDecision(from: template, modelContext: modelContext)
                            selectedDecision = decision
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedDecision) { decision in
            TemplateScoringFlowView(decision: decision, onComplete: {
                selectedDecision = nil
                dismiss()
            }, onCancel: {
                selectedDecision = nil
            })
        }
    }
}

// Полный flow для шаблона в одном fullScreenCover
struct TemplateScoringFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var decision: Decision
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var currentOptionIndex: Int = 0
    @State private var showResults = false
    
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
        NavigationStack {
            if showResults {
                resultsView
            } else {
                scoringView
            }
        }
    }
    
    private var scoringView: some View {
        VStack(spacing: 0) {
            if let option = currentOption {
                VStack(spacing: 20) {
                    progressHeader(option: option)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(criteria) { criterion in
                                TemplateScoringRowView(
                                    option: option,
                                    criterion: criterion,
                                    modelContext: modelContext
                                )
                                .id("\(option.id)-\(criterion.id)")  // Уникальный id для пересоздания при смене опции
                            }
                        }
                        .padding()
                    }
                    .id(option.id)  // Пересоздаём ScrollView при смене опции
                }
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Scoring Matrix")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(currentOptionIndex == options.count - 1 ? "Finish" : "Next") {
                    if currentOptionIndex < options.count - 1 {
                        currentOptionIndex += 1
                    } else {
                        calculateScores()
                        showResults = true
                    }
                }
                .fontWeight(.semibold)
                .disabled(!isCurrentOptionComplete)
            }
        }
    }
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let winner = decision.winner {
                    winnerSection(winner: winner)
                    chartSection
                    allResultsSection
                } else {
                    Text("No results")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    onComplete()
                }
                .fontWeight(.semibold)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: ExportService.exportToText(decision)) {
                    Image(systemName: "square.and.arrow.up")
                }
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
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Template Error")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Options: \(options.count), Criteria: \(criteria.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Go Back") {
                onCancel()
            }
            .buttonStyle(.borderedProminent)
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
        decision.isCompleted = true
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save scores: \(error.localizedDescription)")
            decision.isCompleted = false
        }
    }
    
    private func winnerSection(winner: Option) -> some View {
        let sortedOptions = (decision.options ?? []).sorted { $0.totalScore > $1.totalScore }
        let totalScoreSum = sortedOptions.reduce(0) { $0 + $1.totalScore }
        
        return VStack(spacing: 16) {
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
        let sortedOptions = (decision.options ?? []).sorted { $0.totalScore > $1.totalScore }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Score Distribution")
                .font(.headline)
                .padding(.horizontal, 4)
            
            Chart {
                ForEach(sortedOptions) { option in
                    BarMark(
                        x: .value("Option", option.name),
                        y: .value("Score", option.totalScore)
                    )
                    .foregroundStyle(option.id == decision.winner?.id ? Color.blue : Color.gray.opacity(0.6))
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
    
    private var allResultsSection: some View {
        let sortedOptions = (decision.options ?? []).sorted { $0.totalScore > $1.totalScore }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("All Results")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ForEach(Array(sortedOptions.enumerated()), id: \.element.id) { index, option in
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
}

struct TemplateScoringRowView: View {
    let option: Option
    let criterion: Criteria
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
            if option.scores == nil {
                option.scores = []
            }
            option.scores?.append(score)
            if criterion.scores == nil {
                criterion.scores = []
            }
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

struct TemplateCard: View {
    let template: DecisionTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: template.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Label("\(template.options.count) Options", systemImage: "list.bullet")
                        .font(.caption2)
                    Spacer()
                    Label("\(template.criteria.count) Criteria", systemImage: "slider.horizontal.3")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct ExportOptionsView: View {
    let decision: Decision
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        shareItems = ExportService.shareDecision(decision)
                        showingShareSheet = true
                    } label: {
                        Label("Export as Text", systemImage: "doc.text")
                    }
                    
                    Button {
                        shareItems = [ExportService.exportToCSV(decision)]
                        showingShareSheet = true
                    } label: {
                        Label("Export as CSV", systemImage: "tablecells")
                    }
                } header: {
                    Text("Export Format")
                } footer: {
                    Text("Choose how you want to export this decision.")
                }
                
                Section {
                    Text(decision.title)
                        .font(.headline)
                    if !decision.goal.isEmpty {
                        Text(decision.goal)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Decision")
                }
            }
            .navigationTitle("Export Decision")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
        }
    }
}

struct TheoryView: View {
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    theoryContent
                }
                .padding()
            }
            .navigationTitle("Theory of Decision Making")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var theoryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weighted Scoring Method")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("The Weighted Scoring Method is a decision-making technique that helps you make objective choices by evaluating multiple options against several criteria.")
                .font(.body)
            
            Text("How It Works")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 12) {
                theoryStep(number: "1", title: "Define Options", description: "List all the choices you're considering.")
                theoryStep(number: "2", title: "Identify Criteria", description: "Determine the factors that matter to your decision (e.g., price, quality, location).")
                theoryStep(number: "3", title: "Assign Weights", description: "Rate the importance of each criterion on a scale of 1-10, where 10 is most important.")
                theoryStep(number: "4", title: "Score Options", description: "Rate how well each option performs on each criterion (1-10 scale).")
                theoryStep(number: "5", title: "Calculate", description: "For each option: multiply each score by its criterion weight, then sum all products.")
            }
            
            Text("The Formula")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)
            
            Text("Final Score = Σ (Score × Weight)")
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(8)
            
            Text("The option with the highest total score is your best choice based on the criteria and weights you've defined.")
                .font(.body)
                .padding(.top, 8)
            
            Text("Benefits")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                benefitItem("Reduces bias and emotional decision-making")
                benefitItem("Makes your decision process transparent and reviewable")
                benefitItem("Helps you consider all relevant factors systematically")
                benefitItem("Provides a quantitative basis for comparison")
            }
        }
    }
    
    private func theoryStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func benefitItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.body)
        }
    }
}


