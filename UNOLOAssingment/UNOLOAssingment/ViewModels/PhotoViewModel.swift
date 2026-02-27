import Foundation
import UIKit
import CoreData

protocol PhotoViewModelDelegate: AnyObject {
    func photosDidLoad()
    func photosDidFailToLoad(with error: Error)
    func photoDidUpdate(at index: Int)
    func photoDidDelete(at index: Int)
    func loadingStateDidChange(isLoading: Bool)
}

class PhotoViewModel {
    
    weak var delegate: PhotoViewModelDelegate?
    
    private let networkManager = NetworkManager.shared
    private let coreDataManager = CoreDataManager.shared
    private let imageCache = ImageCacheManager.shared
    
    private(set) var photos: [Photo] = []
    private(set) var isLoading = false
    private(set) var hasMoreData = true
    
    // Pagination properties
    private let pageSize = 30
    private var currentPage = 0
    private var totalPhotosCount = 0
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Public Methods
    
    /// Load photos (from Core Data first, then API if needed)
    func loadPhotos() {
        guard !isLoading else { return }
        
        setLoading(true)
        
        Task {
            do {
                // First check if we have photos in Core Data
                let hasLocalPhotos = try coreDataManager.hasPhotos()
                
                if hasLocalPhotos {
                    await loadPhotosFromCoreData()
                } else {
                    await fetchPhotosFromAPI()
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.delegate?.photosDidFailToLoad(with: error)
                }
            }
        }
    }
    
    /// Load more photos for pagination
    func loadMorePhotos() {
        guard !isLoading && hasMoreData else { return }
        
        setLoading(true)
        
        Task {
            await loadPhotosFromCoreData(loadMore: true)
        }
    }
    
    /// Refresh photos (fetch from API)
    func refreshPhotos() {
        currentPage = 0
        photos.removeAll()
        hasMoreData = true
        
        Task {
            await fetchPhotosFromAPI()
        }
    }
    
    /// Get photo at index
    func photo(at index: Int) -> Photo? {
        guard index >= 0 && index < photos.count else { return nil }
        return photos[index]
    }
    
    /// Get photos count
    var photosCount: Int {
        return photos.count
    }
    
    /// Update photo title
    func updatePhotoTitle(at index: Int, newTitle: String) {
        guard let photo = photo(at: index) else { return }
        
        Task {
            do {
                try coreDataManager.updatePhotoTitle(photoId: photo.id, newTitle: newTitle)
                
                await MainActor.run {
                    photo.title = newTitle
                    self.delegate?.photoDidUpdate(at: index)
                }
            } catch {
                await MainActor.run {
                    self.delegate?.photosDidFailToLoad(with: error)
                }
            }
        }
    }
    
    /// Delete photo
    func deletePhoto(at index: Int) {
        guard let photo = photo(at: index) else { return }
        
        Task {
            do {
                try coreDataManager.deletePhoto(photo)
                
                await MainActor.run {
                    self.photos.remove(at: index)
                    self.delegate?.photoDidDelete(at: index)
                }
            } catch {
                await MainActor.run {
                    self.delegate?.photosDidFailToLoad(with: error)
                }
            }
        }
    }
    
    func loadImage(for photo: Photo, completion: @escaping (UIImage?) -> Void) {
        imageCache.loadImage(from: photo.thumbnailUrl ?? "") { image in
            completion(image)
        }
    }
    
    func loadFullSizeImage(for photo: Photo, completion: @escaping (UIImage?) -> Void) {
        imageCache.loadImage(from: photo.url ?? "") { image in
            completion(image)
        }
    }
    
    // MARK: - Private Methods
    
    private func setLoading(_ loading: Bool) {
        isLoading = loading
        delegate?.loadingStateDidChange(isLoading: loading)
    }
    
    /// Load photos from Core Data
    private func loadPhotosFromCoreData(loadMore: Bool = false) async {
        do {
            let offset = loadMore ? photos.count : 0
            let fetchedPhotos = try coreDataManager.fetchPhotos(limit: pageSize, offset: offset)
            
            await MainActor.run {
                if loadMore {
                    self.photos.append(contentsOf: fetchedPhotos)
                } else {
                    self.photos = fetchedPhotos
                }
                
                self.hasMoreData = fetchedPhotos.count == self.pageSize
                
                self.setLoading(false)
                self.delegate?.photosDidLoad()
            }
        } catch {
            await MainActor.run {
                self.setLoading(false)
                self.delegate?.photosDidFailToLoad(with: error)
            }
        }
    }
    
    /// Fetch photos from API
    private func fetchPhotosFromAPI() async {
        do {
            let photoModels = try await networkManager.fetchPhotos()
            
            // Save to Core Data
            try coreDataManager.savePhotos(photoModels)
            
            // Load from Core Data
            await loadPhotosFromCoreData()
            
        } catch {
            await MainActor.run {
                self.setLoading(false)
                self.delegate?.photosDidFailToLoad(with: error)
            }
        }
    }
}

// MARK: - Photo View Model Extensions
extension PhotoViewModel {
    
    func shouldLoadMoreData(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= photos.count - 5 && hasMoreData && !isLoading
    }
    
    func getPlaceholderImage() -> UIImage? {
        return UIImage(systemName: "photo.fill")
    }
    
    func getErrorImage() -> UIImage? {
        return UIImage(systemName: "exclamationmark.triangle.fill")
    }
}
