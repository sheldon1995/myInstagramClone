//
//  File.swift
//  InstgramClone
//
//  Created by Sheldon on 1/3/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
extension UIView {
    /*
     Left-top corner of screen
     xxxxxx
     y
     y
     y
     y
     */
    func anchor(top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?, paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat){
        
        // This is the way to activate programmatic constrains
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            self.bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let right = right {
            self.rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}


let keyWindow = UIApplication.shared.connectedScenes
    .filter({$0.activationState == .foregroundActive})
    .map({$0 as? UIWindowScene})
    .compactMap({$0})
    .first?.windows
    .filter({$0.isKeyWindow}).first




extension Database{
    static func fetchUser(with uid: String, completion:@escaping(User) ->()){
        // Without doing this, when unfollow a user and follow again, the information will appear twice.
        USER_REF.child(uid).observeSingleEvent(of: .value) {(snapshot) in
            guard let dictionary = snapshot.value as? Dictionary<String,AnyObject> else {return}
            
            // Construct users.
            let user = User(uid: uid, dictionary: dictionary)
            
            completion(user)
        }
    }
    
    // Assoicate each post with its user.
    static func fetchPost(with postId: String, completion:@escaping(Post) ->()){
        // Without doing this, when unfollow a user and follow again, the information will appear twice.
        POST_REF.child(postId).observeSingleEvent(of: .value) {(snapshot) in
            guard let dictionary = snapshot.value as? Dictionary<String,AnyObject> else {return}
            guard let owerUid = dictionary["ownerId"] as? String else {return}
            Database.fetchUser(with: owerUid) { (user) in
                let post = Post(postId: postId, user: user, dictionary: dictionary)
                completion(post)
            }
            
        }
    }
    
}

extension UIColor {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
    
    static let mainBlue = rgb(red: 0, green: 137, blue: 249)
    static let disableColor = rgb(red: 149, green: 204, blue: 244)
    static let enableColor = rgb(red: 17, green: 154, blue: 237)
    static let myLightGray = rgb(red: 230, green: 230, blue: 230)
    static let mygray = rgb(red: 240, green: 240, blue: 240)
}

extension UIButton{
    func configure(didFollow: Bool){
        if didFollow{
            self.setTitle("Following", for: .normal)
            self.setTitleColor(.black, for: .normal)
            self.layer.borderWidth = 0.5
            self.layer.borderColor = UIColor.lightGray.cgColor
            self.backgroundColor = .white
        }
        else{
            self.setTitle("Follow", for: .normal)
            self.setTitleColor(.white, for: .normal)
            self.layer.borderWidth = 0
            self.backgroundColor = .mainBlue
        }
    }
}

extension UIViewController{
    // Help to fetch user with username.
    func getMentionedUser(withUsername username:String){
        USER_REF.observe(.childAdded) { (snapshot) in
            let uid = snapshot.key
            USER_REF.child(uid).observeSingleEvent(of: .value) { (snaphot) in
                guard let dictionary = snapshot.value as? Dictionary<String,AnyObject> else {return}
                if dictionary["username"] as? String == username{
                    Database.fetchUser(with: uid) { (user) in
                        // Create instance of user profile vc
                        let userProfileVC = ProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
                        
                        // Pass each user from searchVC to profileVC
                        userProfileVC.user = user
                        
                        // Push new controller
                        self.navigationController?.pushViewController(userProfileVC, animated: true)
                        return
                    }
                }
            }
        }
    }
    
    // Upload mention noficication.
    func uploadMentionNotification(forPostId postId:String, withText text: String, withType notificationType:Int){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        let creationDate = Int(NSDate().timeIntervalSince1970)
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        // Split the words into word.
        for var word in words{
            // if a word has the prefix "@".
            if word.hasPrefix("@"){
                word = word.trimmingCharacters(in: .symbols)
                word = word.trimmingCharacters(in: .punctuationCharacters)
                USER_REF.observe(.childAdded) { (snapshot) in
                    let uid = snapshot.key
                    // Don't send notification to current user self.
                    
                    USER_REF.child(uid).observeSingleEvent(of: .value) { (snapshot) in
                        guard let dictionary = snapshot.value as? Dictionary<String,AnyObject> else {return}
                        if dictionary["username"] as? String == word{
                            // Create a notification.
                            let values = ["checked":0,
                                          "creationDate": creationDate,
                                          "postId": postId,
                                          "uid":currentUid,
                                          "type":notificationType] as [String : Any]
                            if currentUid != uid{
                                // Notification database reference
                                NOTIFICAITON_REF.child(uid).childByAutoId().updateChildValues(values)
                                
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
}

extension Date{
    func timeAgoToDisplay() -> String{
        let secondsAgo = Int(Date().timeIntervalSince(self))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let month = 4 * week
        let quotient : Int
        let unit : String
        
        if secondsAgo < minute{
            quotient = secondsAgo
            unit = "SECOND"
        }
        else if secondsAgo < hour{
            quotient = secondsAgo / minute
            unit = "MIN"
        }
        else if secondsAgo < day{
            quotient = secondsAgo / hour
            unit = "HOUR"
        }
        else if secondsAgo < week{
            quotient = secondsAgo / day
            unit = "DAY"
        }
        else if secondsAgo < month{
            quotient = secondsAgo / week
            unit = "WEEK"
        }
        else{
            quotient = secondsAgo / month
            unit = "MONTH"
        }
        
        return "\(quotient) \(unit)\(quotient == 1 ? "" :"S") AGO"
    }
}




