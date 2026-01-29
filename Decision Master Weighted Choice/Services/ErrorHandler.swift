import Foundation
import SwiftUI
import Combine

class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false
    
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = .unknown(error.localizedDescription)
        }
        showingError = true
    }
    
    func handle(_ appError: AppError) {
        currentError = appError
        showingError = true
    }
    
    func clear() {
        currentError = nil
        showingError = false
    }
}

enum AppError: LocalizedError {
    case saveFailed(String)
    case deleteFailed(String)
    case validationFailed(String)
    case dataCorrupted
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete: \(message)"
        case .validationFailed(let message):
            return "Validation error: \(message)"
        case .dataCorrupted:
            return "Data appears to be corrupted. Please try again."
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }
}

extension View {
    func errorAlert(errorHandler: ErrorHandler) -> some View {
        self.alert("Error", isPresented: Binding(
            get: { errorHandler.showingError },
            set: { errorHandler.showingError = $0 }
        )) {
            Button("OK", role: .cancel) {
                errorHandler.clear()
            }
        } message: {
            Text(errorHandler.currentError?.errorDescription ?? "Unknown error")
        }
    }
}
