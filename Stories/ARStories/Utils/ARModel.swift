//
//  ARModel.swift
//  ARStories
//
//  Created by ANTONY RAPHEL on 06/09/18.
//

import Foundation

@objc class UserDetails: NSObject {
    var name: String = ""
    var imageUrl: String = ""
    var content: [Content] = []
    
    init(userDetails: [String: Any]) {
        name = userDetails["name"] as? String ?? ""
        imageUrl = userDetails["imageUrl"] as? String ?? ""
        let aContent = userDetails["content"] as? [[String : Any]] ?? []
        for element in aContent {
            content += [Content(element: element)]
        }
    }
}

@objc class Content: NSObject {
    var type: String
    var contentHash: String

    var url: String?

    init(element: [String: Any]) {
        type = element["type"] as? String ?? ""
        contentHash = element["hash"] as? String ?? ""
    }

    override var hash: Int {
        return contentHash.hashValue
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let otherObject = object as? Content {
            return self.contentHash == otherObject.contentHash
        }
        return false
    }
}
