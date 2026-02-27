import Foundation
import CoreData

// MARK: - Core Data Error Types
enum CoreDataError: Error, LocalizedError {
    case saveError(Error)
    case fetchError(Error)
    case deleteError(Error)
    case contextNotFound
    
    var errorDescription: String? {
        switch self {
        case .saveError(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchError(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        case .deleteError(let error):
            return "Failed to delete: \(error.localizedDescription)"
        case .contextNotFound:
            return "Core Data context not found"
        }
    }
}

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Constants.CoreData.modelName)
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() throws {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw CoreDataError.saveError(error)
            }
        }
    }
    
    
    /// Fetch all photos with optional limit and offset for pagination
    func fetchPhotos(limit: Int? = nil, offset: Int = 0) throws -> [Photo] {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        if let limit = limit {
            request.fetchLimit = limit
            request.fetchOffset = offset
        }
        
        do {
            return try context.fetch(request)
        } catch {
            throw CoreDataError.fetchError(error)
        }
    }
    
    /// Fetch photo by ID
    func fetchPhoto(by id: Int64) throws -> Photo? {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %lld", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchError(error)
        }
    }
    
    /// Check if photos exist in Core Data
    func hasPhotos() throws -> Bool {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            throw CoreDataError.fetchError(error)
        }
    }
    
    /// Get total count of photos
    func getPhotosCount() throws -> Int {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        do {
            return try context.count(for: request)
        } catch {
            throw CoreDataError.fetchError(error)
        }
    }
    
    /// Save photos from API response (batch insert)
    func savePhotos(_ photoModels: [PhotoModel]) throws {
        let context = persistentContainer.viewContext
        
        do {
            // First, check for existing photos to avoid duplicates
            let existingIds = try getExistingPhotoIds()
            let newPhotos = photoModels.filter { !existingIds.contains($0.id) }
            
            // Insert only new photos
            for photoModel in newPhotos {
                let photo = Photo(context: context)
                photo.id = photoModel.id
                photo.albumId = photoModel.albumId
                photo.title = photoModel.title
                photo.url = photoModel.url
                photo.thumbnailUrl = photoModel.thumbnailUrl
            }
            
            try saveContext()
        } catch {
            throw CoreDataError.saveError(error)
        }
    }
    
    /// Get existing photo IDs to avoid duplicates
    private func getExistingPhotoIds() throws -> Set<Int64> {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.propertiesToFetch = ["id"]
        
        do {
            let photos = try context.fetch(request)
            return Set(photos.map { $0.id })
        } catch {
            throw CoreDataError.fetchError(error)
        }
    }
    
    /// Update photo title
    func updatePhotoTitle(photoId: Int64, newTitle: String) throws {
        guard let photo = try fetchPhoto(by: photoId) else {
            throw CoreDataError.fetchError(NSError(domain: "PhotoNotFound", code: 404, userInfo: nil))
        }
        
        photo.title = newTitle
        try saveContext()
    }
    
    /// Delete photo
    func deletePhoto(_ photo: Photo) throws {
        context.delete(photo)
        
        do {
            try saveContext()
        } catch {
            throw CoreDataError.deleteError(error)
        }
    }
    
    /// Delete photo by ID
    func deletePhoto(by id: Int64) throws {
        guard let photo = try fetchPhoto(by: id) else {
            throw CoreDataError.fetchError(NSError(domain: "PhotoNotFound", code: 404, userInfo: nil))
        }
        
        try deletePhoto(photo)
    }
    
    /// Delete all photos
    func deleteAllPhotos() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try saveContext()
        } catch {
            throw CoreDataError.deleteError(error)
        }
    }
}
