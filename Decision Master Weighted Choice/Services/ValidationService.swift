import Foundation

class ValidationService {
    // MARK: - Decision Validation
    static func validateDecisionTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= 100
    }
    
    static func validateGoal(_ goal: String) -> Bool {
        return goal.count <= 500
    }
    
    // MARK: - Option Validation
    static func validateOptionName(_ name: String, existingOptions: [String]) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        if trimmed.isEmpty {
            return .failure("Option name cannot be empty")
        }
        
        if trimmed.count < 2 {
            return .failure("Option name must be at least 2 characters")
        }
        
        if trimmed.count > 100 {
            return .failure("Option name cannot exceed 100 characters")
        }
        
        if existingOptions.contains(trimmed) {
            return .failure("This option already exists")
        }
        
        return .success
    }
    
    // MARK: - Criteria Validation
    static func validateCriteriaName(_ name: String, existingCriteria: [String]) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        if trimmed.isEmpty {
            return .failure("Criteria name cannot be empty")
        }
        
        if trimmed.count < 2 {
            return .failure("Criteria name must be at least 2 characters")
        }
        
        if trimmed.count > 100 {
            return .failure("Criteria name cannot exceed 100 characters")
        }
        
        if existingCriteria.contains(trimmed) {
            return .failure("This criteria already exists")
        }
        
        return .success
    }
    
    static func validateWeight(_ weight: Int) -> Bool {
        return weight >= 1 && weight <= 10
    }
    
    // MARK: - Score Validation
    static func validateScore(_ score: Double) -> Bool {
        return score >= 1.0 && score <= 10.0
    }
    
    // MARK: - Decision Flow Validation
    static func validateDecisionFlow(decision: Decision) -> ValidationResult {
        guard let options = decision.options, !options.isEmpty else {
            return .failure("At least 2 options are required")
        }
        
        if options.count < 2 {
            return .failure("At least 2 options are required")
        }
        
        if options.count > 20 {
            return .failure("Maximum 20 options allowed")
        }
        
        guard let criteria = decision.criteria, !criteria.isEmpty else {
            return .failure("At least 1 criterion is required")
        }
        
        if criteria.count > 15 {
            return .failure("Maximum 15 criteria allowed")
        }
        
        // Check for duplicate option names
        let optionNames = options.map { $0.name.trimmingCharacters(in: .whitespaces) }
        let uniqueOptionNames = Set(optionNames)
        if optionNames.count != uniqueOptionNames.count {
            return .failure("Duplicate option names are not allowed")
        }
        
        // Check for duplicate criteria names
        let criteriaNames = criteria.map { $0.name.trimmingCharacters(in: .whitespaces) }
        let uniqueCriteriaNames = Set(criteriaNames)
        if criteriaNames.count != uniqueCriteriaNames.count {
            return .failure("Duplicate criteria names are not allowed")
        }
        
        return .success
    }
}

enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
}
