import UIKit
import Foundation

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let networkManager = NetworkManager.shared
    
    // Track ongoing downloads to avoid duplicate requests
    private var ongoingDownloads = Set<String>()
    private let downloadQueue = DispatchQueue(label: "imageDownloadQueue", qos: .utility, attributes: .concurrent)
    
    private init() {
        // Configure cache
        cache.countLimit = Constants.Cache.imageCountLimit
        cache.totalCostLimit = Constants.Cache.imageCostLimit
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
    /// Load image from cache or download if not available
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: urlString)
        
        // Check cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // Check if download is already in progress
        if ongoingDownloads.contains(urlString) {
            // Wait a bit and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.loadImage(from: urlString, completion: completion)
            }
            return
        }
        
        // Start download
        ongoingDownloads.insert(urlString)
        
        downloadQueue.async {
            Task {
                do {
                    let imageData = try await self.networkManager.downloadImage(from: urlString)
                    
                    if let image = UIImage(data: imageData) {
                        // Cache the image
                        let cost = imageData.count
                        self.cache.setObject(image, forKey: cacheKey, cost: cost)
                        
                        DispatchQueue.main.async {
                            completion(image)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } catch {
                    print("Failed to download image from \(urlString): \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
                
                self.ongoingDownloads.remove(urlString)
            }
        }
    }
    
    /// Load image async/await version
    func loadImage(from urlString: String) async -> UIImage? {
        let cacheKey = NSString(string: urlString)
        
        // Check cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Download image
        do {
            let imageData = try await networkManager.downloadImage(from: urlString)
            
            if let image = UIImage(data: imageData) {
                // Cache the image
                let cost = imageData.count
                cache.setObject(image, forKey: cacheKey, cost: cost)
                return image
            }
        } catch {
            print("Failed to download image from \(urlString): \(error)")
        }
        
        return nil
    }
    
    /// Get cached image without downloading
    func getCachedImage(for urlString: String) -> UIImage? {
        let cacheKey = NSString(string: urlString)
        return cache.object(forKey: cacheKey)
    }
    
    /// Clear all cached images
    @objc private func clearCache() {
        cache.removeAllObjects()
        print("Image cache cleared due to memory warning")
    }
    
    /// Clear cache manually
    func clearCacheManually() {
        cache.removeAllObjects()
    }
    
    /// Remove specific image from cache
    func removeImage(for urlString: String) {
        let cacheKey = NSString(string: urlString)
        cache.removeObject(forKey: cacheKey)
    }
}
