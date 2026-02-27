import Foundation
import CoreData

// MARK: - Photo API Response Model
struct PhotoModel: Codable {
    let albumId: Int64
    let id: Int64
    let title: String
    let url: String
    let thumbnailUrl: String
}

extension PhotoModel {
    func toCoreDataPhoto(context: NSManagedObjectContext) -> Photo {
        let photo = Photo(context: context)
        photo.id = self.id
        photo.albumId = self.albumId
        photo.title = self.title
        photo.url = self.url
        photo.thumbnailUrl = self.thumbnailUrl
        return photo
    }
}

extension Photo {
    func toPhotoModel() -> PhotoModel {
        return PhotoModel(
            albumId: self.albumId,
            id: self.id,
            title: self.title ?? "",
            url: self.url ?? "",
            thumbnailUrl: self.thumbnailUrl ?? ""
        )
    }
}
