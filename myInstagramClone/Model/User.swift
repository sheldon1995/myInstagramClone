//
//
//
//  Created by Sheldon on 1/9/20.
//  Copyright © 2020 wentao. All rights reserved.
//


import UIKit
import Firebase

class User{
    // Attributes
    
    var name:String!
    var userName :String!
    var profileImageUrl: String!
    var uid:String!
    var isFollowed = false
    
    init(uid:String,dictionary:Dictionary<String,AnyObject>) {
        self.uid = uid
        
        if let name = dictionary["name"] as? String{
            self.name = name
        }
        
        if let profileImageUrl = dictionary["profileImageUrl"] as? String{
            self.profileImageUrl = profileImageUrl
        }
        
        if let userName = dictionary["username"] as? String{
            self.userName = userName
        }
    }
    
    func follow(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        guard let otherUserUid = uid else {return}
        
        isFollowed = true
        // The current user is following other users, add uid as the child node of currentUid node.
        USER_FOLLOWING_REF.child(currentUid).updateChildValues([otherUserUid:1])
        
        // Update the user with uid's followers, add current as the follower of other users
        USER_FOLLOWERS_REF.child(otherUserUid).updateChildValues([currentUid:1])
        
        // Upload the follow notification to Firebase
        uploadFollowNotificationToServer()
        
        // Upload the follo
        // Add followed user posts to current user's feed
        USER_POSTS_REF.child(otherUserUid).observe(.childAdded) { (snapshot) in
            let postId = snapshot.key
            USER_FEED_REF.child(currentUid).updateChildValues([postId:1])
        }
        
    }
    func unfollow(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        guard let otherUserUid = uid else {return}
        
        isFollowed = false
        // The current user is following other users, add uid as the child node of currentUid node.
        Database.database().reference().child("user-following").child(currentUid).child(otherUserUid).removeValue()
        
        // Update the user with uid's followers, add current as the follower of other users
        Database.database().reference().child("user-followers").child(otherUserUid).child(currentUid).removeValue()
        
        // Upload the follow notification to Firebase
        // uploadFollowInformation()
        
        // Remove the user's posts from current user' feed
        USER_POSTS_REF.child(otherUserUid).observe(.childAdded) { (snapshot) in
            let postId = snapshot.key
            USER_FEED_REF.child(currentUid).child(postId).removeValue()
        }
    }
    
    func uploadFollowNotificationToServer(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let otherUserId = self.uid else {return}
        
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        let values = ["checked":0,
                      "creationDate": creationDate,
                      "uid":currentUid,
                      "type":FOLLOW_INT_VALUE] as [String : Any]
        // Notification database reference
        NOTIFICAITON_REF.child(otherUserId).childByAutoId().updateChildValues(values)
    }
    
    /*
     Why using completion block here?
     We want to be able to control when one task is completed before we perform some other tasks or actions.
     In this case, we are contacting our API to see if a user is followed or not.
     And based on whether or not that the user is followed, we are configuring this butter here with certain tilte.
     If we don't have a completion block, only a bool value to recode the following of the user.
     The button's title won't change.
     */
    func checkIfUserIsFollowed(completion: @escaping(Bool) ->()){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}   
        Database.database().reference().child("user-following").child(currentUid).observeSingleEvent(of: .value){(snapshot) in
            if snapshot.hasChild(self.uid){
                self.isFollowed = true
                completion(true)
            }
            else
            {
                self.isFollowed = false
                completion(false)
            }
        }
    }

}

