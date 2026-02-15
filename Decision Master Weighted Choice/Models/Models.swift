import Foundation
import SwiftData

@Model
final class Decision: Identifiable {
    var id: UUID
    var title: String
    var goal: String
    var creationDate: Date
    var isCompleted: Bool
    var selectedMethod: String // Always "Matrix" (Simple method removed)
    
    @Relationship(deleteRule: .cascade) var options: [Option]?
    @Relationship(deleteRule: .cascade) var criteria: [Criteria]?
    
    init(title: String, goal: String, creationDate: Date = Date(), isCompleted: Bool = false, selectedMethod: String = "Matrix") {
        self.id = UUID()
        self.title = title
        self.goal = goal
        self.creationDate = creationDate
        self.isCompleted = isCompleted
        self.selectedMethod = selectedMethod
        self.options = []
        self.criteria = []
    }
    
    var winner: Option? {
        guard let options = options, !options.isEmpty else { return nil }
        // Only return winner if all options have been scored
        let allScored = options.allSatisfy { option in
            guard let scores = option.scores, let criteria = criteria else { return false }
            return scores.count == criteria.count
        }
        guard allScored else { return nil }
        return options.max(by: { $0.totalScore < $1.totalScore })
    }
}

@Model
final class Option {
    var id: UUID
    var name: String
    var totalScore: Double
    
    @Relationship(inverse: \Decision.options) var decision: Decision?
    @Relationship(deleteRule: .cascade) var scores: [Score]?
    
    init(name: String, totalScore: Double = 0.0) {
        self.id = UUID()
        self.name = name
        self.totalScore = totalScore
        self.scores = []
    }
    
    func calculateTotalScore(criteria: [Criteria]) {
        guard let scores = scores else {
            totalScore = 0.0
            return
        }
        
        totalScore = criteria.reduce(0.0) { sum, criterion in
            if let score = scores.first(where: { $0.criteria?.id == criterion.id }) {
                return sum + (score.value * Double(criterion.weight))
            }
            return sum
        }
    }
}

@Model
final class Criteria {
    var id: UUID
    var name: String
    var weight: Int // 1-10
    
    @Relationship(inverse: \Decision.criteria) var decision: Decision?
    @Relationship(deleteRule: .cascade) var scores: [Score]?
    
    init(name: String, weight: Int = 5) {
        self.id = UUID()
        self.name = name
        self.weight = max(1, min(10, weight))
        self.scores = []
    }
}

@Model
final class Score {
    var value: Double // 1-10
    
    @Relationship(inverse: \Option.scores) var option: Option?
    @Relationship(inverse: \Criteria.scores) var criteria: Criteria?
    
    init(value: Double = 5.0) {
        self.value = max(1.0, min(10.0, value))
    }
}
