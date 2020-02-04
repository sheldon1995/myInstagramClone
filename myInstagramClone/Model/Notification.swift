//
//  Notification.swift
//  InstgramClone
//
//  Created by Sheldon on 1/17/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import Foundation
import Firebase


class Notification{
    // ,Printable
    enum NotificationType : Int{
        case like
        case comment
        case follow
        case commentMention
        case postMention
        var description: String{
            switch self {
            case .like: return " liked your post"
            case .comment: return " commented on your post"
            case .follow: return " started following you"
            case .commentMention: return " mentioned you in a comment"
            case .postMention: return " mentioned you in post"
            }
        }
        init(index: Int) {
            switch index {
            case 0: self = .like
            case 1: self = .comment
            case 2: self = .follow
            case 3: self = .commentMention
            case 4: self = .postMention
            default: self = .like
            }
        }
    }
    
    var creationDate:Date!
    var uid:String!
    var postId:String!
    var post:Post?
    var user: User!
    var type:Int!
    var notificationType: NotificationType!
    var didCheck = false
    // We can chose to initialize the notification call wih post or not.
    init(user: User, post:Post?=nil, dictionary:Dictionary<String,AnyObject>) {
        self.user = user
        if let post = post{
            self.post = post
        }
        if let creationDate = dictionary["creationDate"] as? Double{
            self.creationDate = Date(timeIntervalSince1970: creationDate)
        }
        
        if let type = dictionary["type"] as? Int{
            self.notificationType = NotificationType(index: type)
        }
        
        if let uid = dictionary["uid"] as? String{
            self.uid = uid
        }
        
        if let postId = dictionary["postId"] as? String{
            self.postId = postId
        }
        
        if let checked = dictionary["checked"] as? Int{
            if checked==1{
                self.didCheck = true
            }
            else{
                self.didCheck = false
            }
        }
    }
}
