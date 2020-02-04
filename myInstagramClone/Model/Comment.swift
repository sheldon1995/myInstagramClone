//
//  Comment.swift
//  InstgramClone
//
//  Created by Sheldon on 1/16/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import Foundation
import Firebase
class Comment{
    
    // MARK: Properties
     var uid:String!
    var comment:String!
    var creationDate:Date!
    var user:User?
    
    // The name inside the dictionary[name] need to match the name of structure in Firebase.
    init(user: User,dictionary: Dictionary<String,AnyObject>) {
        self.user = user
        
        if let comment = dictionary["commentText"] as? String{
            self.comment = comment
        }
        
        if let creationDate = dictionary["creationData"] as? Double{
            self.creationDate = Date(timeIntervalSince1970: creationDate)
            
        }
        
        if let uid = dictionary["uid"] as? String{
            self.uid = uid
        }

    }
   
}

