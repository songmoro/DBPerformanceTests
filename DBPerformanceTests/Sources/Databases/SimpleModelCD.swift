import Foundation
import CoreData

/// CoreData용 SimpleModel NSManagedObject 서브클래스
@objc(SimpleModelCD)
class SimpleModelCD: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var age: Int
    @NSManaged var score: Double
    @NSManaged var isActive: Bool
    @NSManaged var createdAt: Date

    @discardableResult
    static func create(from model: SimpleModel, in context: NSManagedObjectContext) -> SimpleModelCD {
        let entity = SimpleModelCD(context: context)
        entity.id = model.id
        entity.name = model.name
        entity.age = model.age
        entity.score = model.score
        entity.isActive = model.isActive
        entity.createdAt = model.createdAt
        return entity
    }

    func toSimpleModel() -> SimpleModel {
        SimpleModel(
            id: id,
            name: name,
            age: age,
            score: score,
            isActive: isActive,
            createdAt: createdAt
        )
    }
}
