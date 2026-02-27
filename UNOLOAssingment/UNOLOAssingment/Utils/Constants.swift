import Foundation

// MARK: - App Constants
struct Constants {
    
    // MARK: - API
    struct API {
        static let baseURL = "https://jsonplaceholder.typicode.com"
        static let photosEndpoint = "/photos"
        static let requestTimeout: TimeInterval = 30
    }
    
    // MARK: - Cache
    struct Cache {
        static let imageCountLimit = 100
        static let imageCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - UI
    struct UI {
        static let cellHeight: CGFloat = 104
        static let cornerRadius: CGFloat = 8
        static let defaultSpacing: CGFloat = 16
        static let maxTitleLength = 200
    }
    
    // MARK: - Core Data
    struct CoreData {
        static let modelName = "UNOLOAssingment"
        static let photoEntityName = "Photo"
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let networkError = "Network connection failed. Please check your internet connection and try again."
        static let dataError = "Failed to load data. Please try again."
        static let saveError = "Failed to save changes. Please try again."
        static let deleteError = "Failed to delete item. Please try again."
        static let invalidTitle = "Please enter a valid title."
    }
    
    // MARK: - Accessibility
    struct Accessibility {
        static let photoCell = "PhotoCell"
        static let photoImage = "PhotoImage"
        static let photoTitle = "PhotoTitle"
        static let deleteButton = "DeleteButton"
        static let saveButton = "SaveButton"
        static let refreshButton = "RefreshButton"
    }
}
