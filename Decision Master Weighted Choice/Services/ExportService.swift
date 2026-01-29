import Foundation
import SwiftUI
import SwiftData

class ExportService {
    static func exportToText(_ decision: Decision) -> String {
        var text = "═══════════════════════════════════════\n"
        text += "DECISION REPORT\n"
        text += "═══════════════════════════════════════\n\n"
        
        text += "Title: \(decision.title)\n"
        if !decision.goal.isEmpty {
            text += "Goal: \(decision.goal)\n"
        }
        text += "Method: \(decision.selectedMethod)\n"
        text += "Created: \(decision.creationDate.formatted(date: .abbreviated, time: .shortened))\n"
        text += "Status: \(decision.isCompleted ? "Completed" : "In Progress")\n\n"
        
        if let options = decision.options, !options.isEmpty {
            text += "OPTIONS:\n"
            text += "───────────────────────────────────────\n"
            for (index, option) in options.enumerated() {
                text += "\(index + 1). \(option.name)\n"
            }
            text += "\n"
        }
        
        if let criteria = decision.criteria, !criteria.isEmpty {
            text += "CRITERIA:\n"
            text += "───────────────────────────────────────\n"
            for criterion in criteria {
                text += "• \(criterion.name) (Weight: \(criterion.weight)/10)\n"
            }
            text += "\n"
        }
        
        if let options = decision.options, !options.isEmpty,
           let criteria = decision.criteria, !criteria.isEmpty {
            text += "SCORING MATRIX:\n"
            text += "───────────────────────────────────────\n"
            
            // Header
            text += "Option/Criteria".padding(toLength: 20, withPad: " ", startingAt: 0)
            for criterion in criteria {
                let name = String(criterion.name.prefix(8))
                text += name.padding(toLength: 8, withPad: " ", startingAt: 0)
            }
            text += "Total".padding(toLength: 12, withPad: " ", startingAt: 0)
            text += "\n"
            text += String(repeating: "─", count: 20 + criteria.count * 8 + 12) + "\n"
            
            // Rows
            for option in options {
                let optionName = String(option.name.prefix(20))
                text += optionName.padding(toLength: 20, withPad: " ", startingAt: 0)
                var total = 0.0
                for criterion in criteria {
                    if let score = option.scores?.first(where: { $0.criteria?.id == criterion.id }) {
                        let weighted = score.value * Double(criterion.weight)
                        total += weighted
                        let valueStr = String(format: "%.1f", weighted)
                        text += valueStr.padding(toLength: 8, withPad: " ", startingAt: 0)
                    } else {
                        text += "-".padding(toLength: 8, withPad: " ", startingAt: 0)
                    }
                }
                let totalStr = String(format: "%.1f", total)
                text += totalStr.padding(toLength: 12, withPad: " ", startingAt: 0)
                text += "\n"
            }
            text += "\n"
        }
        
        if let winner = decision.winner {
            text += "═══════════════════════════════════════\n"
            text += "WINNER: \(winner.name)\n"
            text += "Total Score: \(Int(winner.totalScore))\n"
            text += "═══════════════════════════════════════\n"
        }
        
        return text
    }
    
    static func exportToCSV(_ decision: Decision) -> String {
        var csv = "Decision,\(decision.title)\n"
        csv += "Goal,\(decision.goal)\n"
        csv += "Method,\(decision.selectedMethod)\n"
        csv += "Created,\(decision.creationDate.formatted(date: .numeric, time: .shortened))\n"
        csv += "Status,\(decision.isCompleted ? "Completed" : "In Progress")\n\n"
        
        csv += "Options\n"
        if let options = decision.options {
            for option in options {
                csv += "\(option.name),\(option.totalScore)\n"
            }
        }
        csv += "\n"
        
        csv += "Criteria\n"
        if let criteria = decision.criteria {
            for criterion in criteria {
                csv += "\(criterion.name),\(criterion.weight)\n"
            }
        }
        csv += "\n"
        
        csv += "Scores\n"
        csv += "Option,Criteria,Score,Weight,Weighted Score\n"
        if let options = decision.options, let criteria = decision.criteria {
            for option in options {
                for criterion in criteria {
                    if let score = option.scores?.first(where: { $0.criteria?.id == criterion.id }) {
                        let weighted = score.value * Double(criterion.weight)
                        csv += "\(option.name),\(criterion.name),\(score.value),\(criterion.weight),\(weighted)\n"
                    }
                }
            }
        }
        
        return csv
    }
    
    static func shareDecision(_ decision: Decision) -> [Any] {
        let text = exportToText(decision)
        return [text]
    }
}
