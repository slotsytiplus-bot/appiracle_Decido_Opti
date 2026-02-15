import Foundation
import SwiftData

class StatisticsService {
    static func getStatistics(for decisions: [Decision]) -> DecisionStatistics {
        let totalDecisions = decisions.count
        let completedDecisions = decisions.filter { $0.isCompleted }.count
        let activeDecisions = totalDecisions - completedDecisions
        
        let totalOptions = decisions.reduce(0) { $0 + ($1.options?.count ?? 0) }
        let totalCriteria = decisions.reduce(0) { $0 + ($1.criteria?.count ?? 0) }
        
        let averageOptions = totalDecisions > 0 ? Double(totalOptions) / Double(totalDecisions) : 0
        let averageCriteria = totalDecisions > 0 ? Double(totalCriteria) / Double(totalDecisions) : 0
        
        let decisionsByMethod = Dictionary(grouping: decisions) { $0.selectedMethod }
        let mostUsedMethod = decisionsByMethod.max(by: { $0.value.count < $1.value.count })?.key ?? "Matrix"
        
        let recentDecisions = decisions.filter { 
            Calendar.current.isDateInLastWeek($0.creationDate) || 
            Calendar.current.isDateInToday($0.creationDate)
        }.count
        
        return DecisionStatistics(
            totalDecisions: totalDecisions,
            completedDecisions: completedDecisions,
            activeDecisions: activeDecisions,
            totalOptions: totalOptions,
            totalCriteria: totalCriteria,
            averageOptions: averageOptions,
            averageCriteria: averageCriteria,
            mostUsedMethod: mostUsedMethod,
            recentDecisions: recentDecisions
        )
    }
}

struct DecisionStatistics {
    let totalDecisions: Int
    let completedDecisions: Int
    let activeDecisions: Int
    let totalOptions: Int
    let totalCriteria: Int
    let averageOptions: Double
    let averageCriteria: Double
    let mostUsedMethod: String
    let recentDecisions: Int
}

extension Calendar {
    func isDateInLastWeek(_ date: Date) -> Bool {
        let weekAgo = self.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return date >= weekAgo
    }
}
