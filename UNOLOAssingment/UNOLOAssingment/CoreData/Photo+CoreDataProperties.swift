import Foundation
import CoreData

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var albumId: Int64
    @NSManaged public var id: Int64
    @NSManaged public var title: String?
    @NSManaged public var thumbnailUrl: String?
    @NSManaged public var url: String?

}