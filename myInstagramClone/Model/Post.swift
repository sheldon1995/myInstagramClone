//
//  Post.swift
//  InstgramClone
//
//  Created by Sheldon on 1/12/20.
//  Copyright © 2020 wentao. All rights reserved.
//
import Foundation
import Firebase
class Post
{
 
    // MARK: Properties
    var caption:String!
    var likes:Int!
    var postImageUrl:String!
    var ownerId:String!
    var creationDate:Date!
    var postId:String!
    var user:User!
    var didLike = false
    
    // The name inside the dictionary[name] need to match the name of structure in Firebase.
    // Assoicate each post with its user.
    init(postId:String!,user:User, dictionary: Dictionary<String,AnyObject>) {
        self.postId = postId
        self.user = user
        
        if let caption = dictionary["caption"] as? String{
            self.caption = caption
            
        }
        if let creationDate = dictionary["creationDate"] as? Double{
            self.creationDate = Date(timeIntervalSince1970: creationDate)
            
        }
        if let likes = dictionary["likes"] as? Int{
            self.likes = likes
            
        }
        if let profileImageUrl = dictionary["profileImageUrl"] as? String{
            self.postImageUrl = profileImageUrl
            
        }
        if let ownerId = dictionary["ownerId"] as? String{
            self.ownerId = ownerId
            
        }
        
    }
    // We set our likes at post structure, set this function as completion, let the likes value can escape from this function and can be used in the FeedCell.
    // Without post-likes structure, we can only get post's likes from many records of post-likes, time-consuming.
    func adjustLikes(postId:String,addLike:Bool,completion:@escaping(Int)->())
    {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        if addLike {
            // Update user-likes structure
            USER_LIKES_REF.child(currentUid).updateChildValues([postId:1],withCompletionBlock: {(err,ref) in
                //send Like Notification To Server()
                self.sendLikeNotificationToServer()
                
                // Update post-likes strcuture
                POST_LIKES_REF.child(postId).updateChildValues([currentUid:1],withCompletionBlock: {(err,ref) in
                    // This like can not escape from this scope, this value won't be changed rightly.
                    self.likes += 1
                    self.didLike = true
                    completion(self.likes)
                    // Update likes at posts structure
                    POST_REF.child(postId).child("likes").setValue(self.likes)
                })
            })
        }
        else{
            USER_LIKES_REF.child(currentUid).child(postId).observeSingleEvent(of: .value) { (snapshot) in
                // Get notification Id to remove
                if let notificationId = snapshot.value as? String{
                    // Remove notification from server
                    NOTIFICAITON_REF.child(self.ownerId).child(notificationId).removeValue { (err, ref) in
                        self.removeLike(withCompletion: { (likes) in
                            completion(likes)
                        })
                    }
                }
                else
                {
                    // This is a self-likes post, don't have remove notification.
                    self.removeLike(withCompletion: { (likes) in
                        completion(likes)
                    })
                }
                
            }
        }
    }
    
    func removeLike(withCompletion completion: @escaping (Int) -> ()){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        // Remove user-likes structure
        USER_LIKES_REF.child(currentUid).child(postId).removeValue(completionBlock: {(err,ref) in
            // Remove post-likes structure
            POST_LIKES_REF.child(self.postId).child(currentUid).removeValue(completionBlock: {(err,ref) in
                guard self.likes > 0 else{return}
                self.likes -= 1
                self.didLike = false
                // Update likes at posts structure
                POST_REF.child(self.postId).child("likes").setValue(self.likes)
                completion(self.likes)
            })
        })
        
    }
    func sendLikeNotificationToServer(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let postId = self.postId else {return}
        let creationDate = Int(NSDate().timeIntervalSince1970)
        // We don't send notificaiton to the current user.
        if currentUid != self.ownerId{
            let values = ["checked":0,
                          "creationDate": creationDate,
                          "uid":currentUid,
                          "type":LIKE_INT_VALUE,
                          "postId":postId] as [String : Any]
            // Notification database reference
            let notificationRef = NOTIFICAITON_REF.child(self.ownerId).childByAutoId()
            notificationRef.updateChildValues(values,withCompletionBlock: {(err,ref) in
                // Set the notification id to the user_likes structure
                USER_LIKES_REF.child(currentUid).child(self.postId).setValue(notificationRef.key)
            })
        }
    }
    
    func deletePost(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        // Delete from storage according to post image url
        Storage.storage().reference(forURL: self.postImageUrl).delete(completion:nil)
        
        // Remove from user-feed by getting follower's id from "user-followers"
        USER_FOLLOWERS_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let followerId = snapshot.key
            USER_FEED_REF.child(followerId).child(followerId).removeValue()
        }
        
        // Remove from USER_FEED
        USER_FEED_REF.child(currentUid).child(postId).removeValue()
        
        // Remove from "user-posts"
        USER_POSTS_REF.child(currentUid).child(postId).removeValue()
        
        // Remove from "user-likes"
        POST_LIKES_REF.child(postId).observe(.childAdded) { (snapshot) in
            let userId = snapshot.key
            USER_LIKES_REF.child(userId).child(self.postId).observeSingleEvent(of: .childAdded) { (snapshot) in
                // Remove from "notification"
                guard let notificationId = snapshot.value as? String else {return}
                // The notification belong to the post's ownerId
                NOTIFICAITON_REF.child(self.ownerId).child(notificationId).removeValue { (error, ref) in
                    // Remove from "post-likes"
                    POST_LIKES_REF.child(self.postId).removeValue()
                    USER_LIKES_REF.child(userId).child(self.postId).removeValue()
                }
            }
        }
        // Delete from  "hashtag-post"
        let words = caption.components(separatedBy: .whitespacesAndNewlines)
        for var word in words {
            if word.hasPrefix("#"){
                word = word.trimmingCharacters(in: .punctuationCharacters)
                word = word.trimmingCharacters(in: .symbols)
                word = word.lowercased()
                HASHTAG_POST_REF.child(word).child(self.postId).removeValue()
            }
        }
        
        // Remove from "comments"
        COMMENT_REF.child(postId).removeValue()
        
        // Remove from "posts"
        POST_REF.child(postId).removeValue()
        
        // Refresh pages after delete.
        CONSTANTS_FeedVC?.handleRefresh()
        CONSTANTS_ProfileVC?.handleRefresh()
    }
}
