//
//  Message.swift
//  InstgramClone
//
//  Created by Sheldon on 1/20/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import Foundation
import Firebase

class Message{
    var messageText:String!
    var fromId:String!
    var toId:String!
    var creationDate:Date!
    init(dictionary:Dictionary<String,AnyObject>) {
        if let messageText = dictionary["messageText"] as? String
        {
            self.messageText = messageText
        }
        if let fromId = dictionary["fromId"] as? String{
            self.fromId = fromId
        }
        if let toId = dictionary["toId"] as? String{
            self.toId = toId
        }
        if let creationDate = dictionary["creationDate"] as? Double{
            self.creationDate = Date(timeIntervalSince1970: creationDate)
        }
    }
    
    func getChatPartnerId() ->String{
        /*
         If message is from current user, the chat partner id is the toId.
         */
        guard let currentUid = Auth.auth().currentUser?.uid else {return ""}
        if fromId == currentUid{
            return toId
        }
        else{
            return fromId
        }
       
    }
}
