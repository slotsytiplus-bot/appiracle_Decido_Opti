import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Query(sort: \Decision.creationDate, order: .reverse) private var allDecisions: [Decision]
    @State private var showingNewDecision = false
    @State private var showingQuickToss = false
    @State private var showingTemplates = false
    @State private var showingComparison = false
    @State private var selectedDecisions: Set<UUID> = []
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var sortOption: SortOption = .date
    @State private var navigationPath = NavigationPath()
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case recent = "Recent"
    }
    
    enum SortOption: String, CaseIterable {
        case date = "Date"
        case title = "Title"
        case progress = "Progress"
    }
    
    var filteredDecisions: [Decision] {
        var decisions = allDecisions
        
        // Filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            decisions = decisions.filter { !$0.isCompleted }
        case .completed:
            decisions = decisions.filter { $0.isCompleted }
        case .recent:
            decisions = decisions.filter {
                Calendar.current.isDateInLastWeek($0.creationDate) ||
                Calendar.current.isDateInToday($0.creationDate)
            }
        }
        
        // Search
        if !searchText.isEmpty {
            decisions = decisions.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.goal.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort
        switch sortOption {
        case .date:
            decisions = decisions.sorted { $0.creationDate > $1.creationDate }
        case .title:
            decisions = decisions.sorted { $0.title < $1.title }
        case .progress:
            decisions = decisions.sorted { progress(for: $0) > progress(for: $1) }
        }
        
        return decisions
    }
    
    var activeDecisions: [Decision] {
        filteredDecisions.filter { !$0.isCompleted }
    }
    
    var archivedDecisions: [Decision] {
        filteredDecisions.filter { $0.isCompleted }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if allDecisions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            statisticsOverview
                            
                            quickActionsSection
                            
                            searchAndFiltersSection
                            
                            if !activeDecisions.isEmpty {
                                activeDecisionsSection
                            }
                            
                            if !archivedDecisions.isEmpty {
                                archivedDecisionsSection
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Decisions")
            .searchable(text: $searchText, prompt: "Search decisions...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            QuickTossView()
                        } label: {
                            Image(systemName: "flip.horizontal.fill")
                                .font(.title3)
                        }
                        
                        NavigationLink {
                            TemplatesView()
                        } label: {
                            Image(systemName: "doc.text.fill")
                                .font(.title3)
                        }
                        
                        Button {
                            showingNewDecision = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showingNewDecision) {
                NewDecisionWizardView(navigationPath: $navigationPath)
            }
            .navigationDestination(isPresented: $showingQuickToss) {
                QuickTossView()
            }
            .navigationDestination(isPresented: $showingTemplates) {
                TemplatesView()
            }
            .navigationDestination(isPresented: $showingComparison) {
                ComparisonView(decisions: allDecisions.filter { selectedDecisions.contains($0.id) })
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        .preferredColorScheme(themeManager.effectiveColorScheme)
    }
    
    private var statisticsOverview: some View {
        let stats = StatisticsService.getStatistics(for: allDecisions)
        
        return HStack(spacing: 12) {
            StatMiniCard(title: "Total", value: "\(stats.totalDecisions)", color: .blue)
                .fadeInAnimation(delay: 0.1)
            StatMiniCard(title: "Active", value: "\(stats.activeDecisions)", color: .orange)
                .fadeInAnimation(delay: 0.2)
            StatMiniCard(title: "Done", value: "\(stats.completedDecisions)", color: .green)
                .fadeInAnimation(delay: 0.3)
        }
    }
    
    private var searchAndFiltersSection: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Sort", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Decisions Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by creating a new decision or try Quick Toss for simple choices")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    showingNewDecision = true
                } label: {
                    Label("New Decision", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                HStack(spacing: 12) {
                    Button {
                        showingTemplates = true
                    } label: {
                        Label("Templates", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        showingQuickToss = true
                    } label: {
                        Label("Quick Toss", systemImage: "flip.horizontal.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // Main action - New Decision
                Button {
                    showingNewDecision = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create New Decision")
                                .font(.headline)
                            Text("Start a structured decision-making process")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                
                // Secondary actions
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "Quick Toss",
                        icon: "flip.horizontal.fill",
                        color: .orange,
                        description: "Flip a coin"
                    ) {
                        showingQuickToss = true
                    }
                    
                    QuickActionButton(
                        title: "Templates",
                        icon: "doc.text.fill",
                        color: .green,
                        description: "Use template"
                    ) {
                        showingTemplates = true
                    }
                }
            }
            
            if !selectedDecisions.isEmpty {
                Button {
                    showingComparison = true
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Compare Selected (\(selectedDecisions.count))")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var activeDecisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Decisions")
                .sectionHeader("Active Decisions")
            
            ForEach(Array(activeDecisions.enumerated()), id: \.element.id) { index, decision in
                DecisionCardView(decision: decision)
                    .slideInAnimation(from: .trailing, delay: Double(index) * 0.1)
            }
        }
    }
    
    private var archivedDecisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Archived")
                .sectionHeader("Archived")
            
            ForEach(archivedDecisions) { decision in
                NavigationLink {
                    DecisionDetailView(decision: decision)
                } label: {
                    DecisionCardView(decision: decision)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        let decisionId = getDecisionId(from: destination)
        if let decision = allDecisions.first(where: { $0.id == decisionId }) {
            switch destination {
            case .optionsInput:
                OptionsInputView(decision: decision, navigationPath: $navigationPath)
            case .criteriaSetup:
                CriteriaSetupView(decision: decision, navigationPath: $navigationPath)
            case .scoringMatrix:
                ScoringMatrixView(decision: decision, navigationPath: $navigationPath)
            case .finalResult:
                FinalResultView(decision: decision, navigationPath: $navigationPath)
            case .decisionDetail:
                DecisionDetailView(decision: decision)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                Text("Decision not found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("The decision you're looking for no longer exists.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    private func getDecisionId(from destination: NavigationDestination) -> UUID {
        switch destination {
        case .optionsInput(let id), .criteriaSetup(let id), .scoringMatrix(let id), .finalResult(let id), .decisionDetail(let id):
            return id
        }
    }
    
    private func progress(for decision: Decision) -> Double {
        guard let options = decision.options, !options.isEmpty,
              let criteria = decision.criteria, !criteria.isEmpty else {
            return 0.0
        }
        
        let totalScores = options.reduce(0) { sum, option in
            sum + (option.scores?.count ?? 0)
        }
        let expectedScores = options.count * criteria.count
        return Double(totalScores) / Double(expectedScores)
    }
}

struct StatMiniCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var description: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let description = description {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(color)
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct DecisionCardView: View {
    let decision: Decision
    var isSelected: Bool = false
    var onToggleSelection: (() -> Void)? = nil
    
    var progress: Double {
        guard let options = decision.options, !options.isEmpty,
              let criteria = decision.criteria, !criteria.isEmpty else {
            return 0.0
        }
        
        let totalScores = options.reduce(0) { sum, option in
            sum + (option.scores?.count ?? 0)
        }
        let expectedScores = options.count * criteria.count
        return Double(totalScores) / Double(expectedScores)
    }
    
    var nextStep: String {
        if decision.options?.isEmpty ?? true {
            return "Add Options"
        } else if decision.criteria?.isEmpty ?? true {
            return "Add Criteria"
        } else if progress < 1.0 {
            return "Complete Scoring"
        } else {
            return "View Results"
        }
    }
    
    var body: some View {
        NavigationLink {
            DecisionDetailView(decision: decision)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(decision.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !decision.goal.isEmpty {
                            Text(decision.goal)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    } else if decision.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                
                if !decision.isCompleted {
                    HStack {
                        ProgressView(value: progress)
                            .tint(progress == 1.0 ? .green : .blue)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("\(decision.options?.count ?? 0) Options", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label("\(decision.criteria?.count ?? 0) Criteria", systemImage: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(nextStep)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                } else {
                    if let winner = decision.winner {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                            Text("Winner: \(winner.name)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Decision.self, Option.self, Criteria.self, Score.self], inMemory: true)
}
