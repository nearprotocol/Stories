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
    var url: String
    var contentHash: String
    init(element: [String: Any]) {
        type = element["type"] as? String ?? ""
        url = element["url"] as? String ?? ""
        contentHash = element["hash"] as? String ?? ""
    }
}
