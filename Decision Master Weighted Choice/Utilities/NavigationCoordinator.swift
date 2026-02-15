import SwiftUI
import SwiftData

enum NavigationDestination: Hashable {
    case optionsInput(UUID)
    case criteriaSetup(UUID)
    case scoringMatrix(UUID)
    case finalResult(UUID)
    case decisionDetail(UUID)
}
