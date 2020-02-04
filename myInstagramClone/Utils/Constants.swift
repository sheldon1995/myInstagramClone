//
//  Constants.swift
//  InstgramClone
//
//  Created by Sheldon on 1/12/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import Firebase

let DB_REF = Database.database().reference()

let USER_REF = DB_REF.child("users")

let POST_REF = DB_REF.child("posts")

let USER_FOLLOWERS_REF = DB_REF.child("user-followers")

let USER_FOLLOWING_REF = DB_REF.child("user-following")


let STORAGE_REF = Storage.storage().reference()

let STORAGE_PROFILE_IMG_REF = STORAGE_REF.child("profile_images")

let USER_POSTS_REF = DB_REF.child("user-posts")

let USER_FEED_REF = DB_REF.child("user-feed")

let USER_LIKES_REF = DB_REF.child("user-likes")

let POST_LIKES_REF = DB_REF.child("post-likes")

let COMMENT_REF = DB_REF.child("comments")

let NOTIFICAITON_REF = DB_REF.child("notifications")
// Three types of notification.
let LIKE_INT_VALUE = 0

let COMMENT_INT_VALUE = 1

let FOLLOW_INT_VALUE = 2

let COMMENT_MENTION_INT_VALUE = 3

let POST_MENTION_INT_VALUE = 4

let MESSAGE_REF = DB_REF.child("messages")

let USER_MESSAGES_REF = DB_REF.child("user-messages")


let HASHTAG_POST_REF = DB_REF.child("hashtag-post")

var POST_A_NEW_POST = false

// Refresh page
var CONSTANTS_FeedVC : FeedVC?

var CONSTANTS_ProfileVC : ProfileVC?
