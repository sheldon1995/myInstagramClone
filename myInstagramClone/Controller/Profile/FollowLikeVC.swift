//
//  FollowVC.swift
//  InstgramClone
//
//  Created by Sheldon on 1/10/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "FollowCell"

class FollowLikeVC: UITableViewController,FollowCellDelegate {
    
    // MARK: Properities
    var followCurrentKey:String?
    var likeCurrentKey:String?
    enum viewMode : Int{
        case following
        case follower
        case like
        init(index:Int) {
            switch index {
            case 0: self = .following
            case 1: self =  .follower
            case 2: self = .like
            default: self = .following
                
            }
        }
        
    }
    var postId:String!
    var viewMode : viewMode!
    var uid:String?
    // Set user array.
    var followingOrErUser = [User]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register cell classes
        tableView.register(FollowLikeCell.self, forCellReuseIdentifier: reuseIdentifier)
        // Configure nav title.
        configureNavTitle()
        
        // Configure user data.
        fetchUsersData()
        
        // Clean the separator color between each cells.
        tableView.separatorColor = .clear
    }
    
    // MARK: TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return followingOrErUser.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,for: indexPath) as! FollowLikeCell
        
        // indexPath.row increase from 0 to ...
        cell.user = followingOrErUser[indexPath.row]
        
        // set delegate, to make the delegate work!
        cell.delegate = self
        return cell
    }
    
    // Hight for row
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // When click one table view cell..., navigate from search view to profile view.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = followingOrErUser[indexPath.row]
        
        // Create instance of user profile vc
        let userProfileVC = ProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
        
        // Pass each user from searchVC to profileVC
        userProfileVC.user = user
        
        // Push new controller
        navigationController?.pushViewController(userProfileVC, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if followingOrErUser.count > 3{
            if indexPath.row == followingOrErUser.count - 1{
                fetchUsersData()
            }
        }
    }
    // Mark: Handlers
    func configureNavTitle(){
        guard let viewMode = self.viewMode else {return }
        switch viewMode {
        case .follower: navigationItem.title = "Followers"
        case .following: navigationItem.title = "Followings"
        case .like: navigationItem.title = "Likes"
        }
    }
    
    func getDataBaseReference() -> DatabaseReference?{
        guard let viewMode = self.viewMode else {return nil}
        
        switch viewMode {
        // Grab data from user-following if click the following label at profile page.
        case .follower: return USER_FOLLOWERS_REF
        // Grab data from user-follower if click the follower label at profile page.
        case .following: return USER_FOLLOWING_REF
        case .like: return POST_LIKES_REF
        }
        
    }
    
    func fetchUsersData(){
        guard let ref = getDataBaseReference() else {return}
        guard let viewMode = self.viewMode else {return}
        switch viewMode {
        case .follower, .following:
            // We are fetching based on uid,
            guard let uid = self.uid else { return }
            if followCurrentKey == nil{
                ref.child(uid).queryLimited(toLast: 4).observe(.value) { (snapshot) in
                    // The fifth post from one fetch.
                    guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                    guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                    
                    // Grab these 5 post and append to posts array.
                    allObjects.forEach { (snapshot) in
                        let postId = snapshot.key
                        Database.fetchUser(with: postId) { (post) in
                            self.followingOrErUser.append(post)
                            
                            // This reloadData() must be included in this range.
                            self.tableView?.reloadData()
                            
                        }
                    }
                    // Record the last visited one.
                    self.followCurrentKey = first.key                }
            }
            else{
                ref.child(uid).queryOrderedByKey().queryEnding(atValue: self.followCurrentKey).queryLimited(toLast: 5).observe(.value) { (snapshot) in
                    guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                    guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                    allObjects.forEach { (snapshot) in
                        let followingErId = snapshot.key
                        if followingErId != self.followCurrentKey{
                            Database.fetchUser(with: followingErId) { (user) in
                                self.followingOrErUser.append(user)
                                // This reloadData() must be included in this range.
                                self.tableView?.reloadData()
                            }
                        }
                    }
                    // Record the last visited one.
                    self.followCurrentKey = first.key
                }
            }
        // We are fetching based on postId.
        case .like:
            guard let postId = self.postId else {return}
            if likeCurrentKey == nil {
                ref.child(postId).queryLimited(toLast: 4).observe(.value) { (snapshot) in
                    guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                    guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                    
                    // Grab these 5 post and append to posts array.
                    allObjects.forEach { (snapshot) in
                        let likeUserId = snapshot.key
                        Database.fetchUser(with: likeUserId) { (likeUser) in
                            self.followingOrErUser.append(likeUser)
                            
                            // This reloadData() must be included in this range.
                            self.tableView?.reloadData()
                        }
                    }
                    // Record the last visited one.
                    self.likeCurrentKey = first.key
                    
                }
            }
            else{
                // Once user scroll down to the bottom.
                // queryOrderedByKey: is used to generate a reference to a view of the data that's been sorted by child key.
                // The upper bound (currentKey) is inclusive
                ref.child(postId).queryOrderedByKey().queryEnding(atValue: self.likeCurrentKey).queryLimited(toLast: 5).observe(.value) { (snapshot) in
                    // we don't want the duplicated one.
                    guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                    guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                    
                    // Grab these 5 post and append to posts array.
                    allObjects.forEach { (snapshot) in
                        let likeUserId = snapshot.key
                        // we don't want the duplicated one.
                        if snapshot.key != self.likeCurrentKey {
                            Database.fetchUser(with: likeUserId) { (likeUser) in
                                self.followingOrErUser.append(likeUser)
                                
                                // This reloadData() must be included in this range.
                                self.tableView?.reloadData()
                            }
                        }
                    }
                    self.likeCurrentKey = first.key
                }
            }
            
        }
    }
    
    
    // Type the follow button
    func handleFollowTapped(for cell: FollowLikeCell) {
        guard let user = cell.user else {return}
        if user.isFollowed{
            user.unfollow()
            cell.followUnfollowButton.setTitleColor(.white, for: .normal)
            cell.followUnfollowButton.setTitle("Follow", for: .normal)
            cell.followUnfollowButton.layer.borderWidth = 0
            cell.followUnfollowButton.backgroundColor = .mainBlue
        }
        else{
            user.follow()
            cell.followUnfollowButton.setTitleColor(.black, for: .normal)
            cell.followUnfollowButton.setTitle("Following", for: .normal)
            cell.followUnfollowButton.layer.borderWidth = 0.5
            cell.followUnfollowButton.layer.borderColor = UIColor.lightGray.cgColor
            cell.followUnfollowButton.backgroundColor = .white
        }
    }
}
