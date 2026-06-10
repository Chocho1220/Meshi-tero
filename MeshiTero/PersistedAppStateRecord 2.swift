import Foundation
import SwiftData

@Model
final class PersistedAppStateRecord {
    var key: String
    var snapshotData: Data

    init(key: String = "primary", snapshotData: Data = Data()) {
        self.key = key
        self.snapshotData = snapshotData
    }
}
