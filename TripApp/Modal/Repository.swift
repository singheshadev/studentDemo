
import Foundation

struct Repository {
    
    let repoName: String
    let repoURL: String
}

class Trips: NSObject {
    var tripId : String = ""
    var name : String = ""
    var startDate = Timestamp()
    var endDate = Timestamp()
    var tripStatus : String = ""
}
