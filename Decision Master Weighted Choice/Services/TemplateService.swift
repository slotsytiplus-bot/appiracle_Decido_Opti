import Foundation
import SwiftData

struct DecisionTemplate {
    let name: String
    let description: String
    let icon: String
    let options: [String]
    let criteria: [(name: String, weight: Int)]
}

class TemplateService {
    static let templates: [DecisionTemplate] = [
        DecisionTemplate(
            name: "Job Selection",
            description: "Choose between job offers",
            icon: "briefcase.fill",
            options: ["Company A", "Company B", "Company C"],
            criteria: [
                ("Salary", 9),
                ("Work-Life Balance", 8),
                ("Career Growth", 7),
                ("Location", 6),
                ("Benefits", 7),
                ("Company Culture", 8)
            ]
        ),
        DecisionTemplate(
            name: "Apartment Rental",
            description: "Find the perfect apartment",
            icon: "house.fill",
            options: ["Apartment A", "Apartment B", "Apartment C"],
            criteria: [
                ("Price", 9),
                ("Location", 8),
                ("Size", 7),
                ("Amenities", 6),
                ("Transportation", 7),
                ("Safety", 9)
            ]
        ),
        DecisionTemplate(
            name: "Vacation Destination",
            description: "Plan your next trip",
            icon: "airplane",
            options: ["Destination A", "Destination B", "Destination C"],
            criteria: [
                ("Cost", 8),
                ("Weather", 7),
                ("Activities", 8),
                ("Culture", 6),
                ("Food", 7),
                ("Accessibility", 6)
            ]
        ),
        DecisionTemplate(
            name: "Car Purchase",
            description: "Select your next vehicle",
            icon: "car.fill",
            options: ["Car A", "Car B", "Car C"],
            criteria: [
                ("Price", 9),
                ("Fuel Efficiency", 8),
                ("Reliability", 9),
                ("Features", 7),
                ("Safety Rating", 9),
                ("Resale Value", 6)
            ]
        ),
        DecisionTemplate(
            name: "University Choice",
            description: "Choose your educational path",
            icon: "graduationcap.fill",
            options: ["University A", "University B", "University C"],
            criteria: [
                ("Academic Reputation", 9),
                ("Cost", 8),
                ("Location", 7),
                ("Program Quality", 9),
                ("Campus Life", 6),
                ("Career Services", 7)
            ]
        ),
        DecisionTemplate(
            name: "Restaurant Selection",
            description: "Pick where to dine",
            icon: "fork.knife",
            options: ["Restaurant A", "Restaurant B", "Restaurant C"],
            criteria: [
                ("Food Quality", 9),
                ("Price", 7),
                ("Ambiance", 6),
                ("Service", 7),
                ("Location", 6),
                ("Dietary Options", 5)
            ]
        )
    ]
    
    static func createDecision(from template: DecisionTemplate, modelContext: ModelContext) -> Decision {
        // Создаём decision с пустыми массивами
        let decision = Decision(
            title: template.name,
            goal: template.description,
            selectedMethod: "Matrix"
        )
        
        // Создаём опции
        var newOptions: [Option] = []
        for optionName in template.options {
            let option = Option(name: optionName)
            newOptions.append(option)
        }
        
        // Создаём критерии
        var newCriteria: [Criteria] = []
        for (name, weight) in template.criteria {
            let criterion = Criteria(name: name, weight: weight)
            newCriteria.append(criterion)
        }
        
        // Устанавливаем связи ДО вставки в контекст
        decision.options = newOptions
        decision.criteria = newCriteria
        
        // Вставляем всё в контекст
        modelContext.insert(decision)
        for option in newOptions {
            modelContext.insert(option)
        }
        for criterion in newCriteria {
            modelContext.insert(criterion)
        }
        
        // Сохраняем
        do {
            try modelContext.save()
        } catch {
            print("Failed to save template decision: \(error.localizedDescription)")
        }
        
        return decision
    }
}
