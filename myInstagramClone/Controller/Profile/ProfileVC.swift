//
//  ProfileCollectionViewController.swift
//  InstgramClone
//
//  Created by Sheldon on 1/8/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
private let reuseIdentifier = "Cell"
private let headIdentifier = "ProfileHeader"

class ProfileVC: UICollectionViewController, UICollectionViewDelegateFlowLayout,UserProfileHeaderDelegate {
    
    
    // MARK: Properties
    // Set user
    var user: User?
    var posts = [Post]()
    var currentKey : String?
    var firstLoad = true
    // -Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch user data. If userToLoadFromSearchVC == nil, we present current user data.
        if self.user == nil
        {
            fetchCurrentUserData()
        }
        
        // Register cell classes
        self.collectionView!.register(ProfilePostCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Register collection header
        self.collectionView!.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headIdentifier)
        
        // Background color
        collectionView.backgroundColor = .white
        
        
        // Configure refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        
        // Fetch posts
        fetchPosts()
        
        CONSTANTS_ProfileVC = self
        
        collectionView.dragDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.dropDelegate = self
    }
    // MARK: UICollectionViewFlowLayout
    
    // Set collection view lay out for cell
    // We want divide up into four cells per row.
    // 3 is to account for three kind of separating line.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    // Asks the delegate for the spacing between successive items in the rows
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    // Cell spacing
    // Asks the delegate for the spacing between successive rows
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    // MARK: UICollectionViewDataSource
    
    // Pagination, call fetchPost() again.
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if posts.count > 8 {
            if indexPath.row == posts.count - 1{
                self.fetchPosts()
            }
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    // Set size of header
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 190)
    }
    
    // Set cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ProfilePostCell
        cell.post = posts[indexPath.item]
        return cell
    }
    
    // Add did select
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let feedVC = FeedVC(collectionViewLayout: UICollectionViewFlowLayout())
        // Just view one post.
        feedVC.viewSinglePost = true
        // Set userprofiler controller.
        feedVC.userProfileController = self
        // View this one
        feedVC.post = posts[indexPath.row]
        
        // Push new controller
        navigationController?.pushViewController(feedVC, animated: true)
    }
    
    // Set header
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // Declare header
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headIdentifier, for: indexPath) as! UserProfileHeader
        
        
        // set delegate, to make the delegate work!
        header.delegate = self
        
        // set the user in header, if userToLoadFromSearchVC is not nil, show the user information got from seach vc.
        header.user = self.user
        navigationItem.title = user?.userName
        return header
    }
    
    // MARK: API
    
    // Retrive information from database, get user information and store data to User object.
    func fetchCurrentUserData() {
        
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        USER_REF.child(currentUid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else { return }
            let uid = snapshot.key
            let user = User(uid: uid, dictionary: dictionary)
            self.user = user
            
            // Necessary to call the reload data.
            self.collectionView?.reloadData()
        }
    }
    
    // Fetch posts
    func fetchPosts(){
        
        // The other user get into the user profile page by searching, show this use's post.
        var uid : String!
        if let user = self.user{
            uid = user.uid
        }
        else{
            uid = Auth.auth().currentUser?.uid
        }
        // Pagination
        if currentKey == nil{
            // We can't use .childadded for pagination
            // Only grab last 9 posts.
            USER_POSTS_REF.child(uid).queryLimited(toLast: 9).observeSingleEvent(of: .value) { (snapshot) in
                // Stop refresh
                self.collectionView.refreshControl?.endRefreshing()
                
                
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                allObjects.forEach { (snapshot) in
                    let postId = snapshot.key
                    Database.fetchPost(with: postId) { (post) in
                        self.posts.append(post)
                        
                        // Always show the newest post first.
                        
                        self.posts.sort { (post1, post2) -> Bool in
                            return post1.creationDate>post2.creationDate
                        }
                        // This reloadData() is necessary.
                        self.collectionView.reloadData()
                    }
                }
                self.currentKey = first.key
            }
        }
        else{
            USER_POSTS_REF.child(uid).queryOrderedByKey().queryEnding(atValue: self.currentKey).queryLimited(toLast: 7).observeSingleEvent(of: .value)  { (snapshot) in
                // we don't want the duplicated one.
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                // Grab these 4 post and append to posts array.
                allObjects.forEach { (snapshot) in
                    let postId = snapshot.key
                    // we don't want the duplicated one.
                    if snapshot.key != self.currentKey {
                        Database.fetchPost(with: postId) { (post) in
                            self.posts.append(post)
                            
                            // Always show the newest post first.
                            self.posts.sort { (post1, post2) -> Bool in
                                return post1.creationDate>post2.creationDate
                            }
                            // This reloadData() must be included in this range.
                            self.collectionView?.reloadData()
                            
                        }
                    }
                }
                self.currentKey = first.key
            }
        }
        
    }
    
    @objc func handleRefresh(){
        // Remove all contents at posts array
        posts.removeAll(keepingCapacity: false)
        
        // Set current key as nil
        currentKey = nil
        
        // Fetch post again, need to stop refreshing.
        fetchPosts()
        
        // Reload data
        collectionView.reloadData()
    }
    
    // MARK: ProfileHeader Protocols
    // Define functions in UserProfileHeaderDelegate
    func handleEditFollowTapped(for header: UserProfileHeader) {
        
        guard let user = header.user else {return}
        // Edit profile
        if header.editProfileFollowButton.titleLabel?.text == "Edit Profile"{
            // Jump to editprofile VC
            let editProfileVC = EditProfileVC()
            
            editProfileVC.user = user
            editProfileVC.profileVC = self
            
            let navigationController = UINavigationController(rootViewController: editProfileVC)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController,animated: true, completion: nil)
            //            navigationController?.pushViewController(editProfileVC, animated: true)
        }
            // Unfollow
        else if header.editProfileFollowButton.titleLabel?.text == "Following"{
            user.unfollow()
            header.editProfileFollowButton.setTitle("Follow", for: .normal)
        }
            // Follow
        else if header.editProfileFollowButton.titleLabel?.text == "Follow"{
            user.follow()
            header.editProfileFollowButton.setTitle("Following", for: .normal)
        }
        
    }
    
    // Set the number of posts, followers, followings
    func setUserStats(for header: UserProfileHeader) {
        
        var numberOfFollowers:Int!
        var numberOfFollowings:Int!
        var numberOfPosts:Int!
        
        guard let uid = header.user?.uid else {return}
        // Get number of followers
        /*
         The observe is going to sort of listen to any events that are changeing our database,
         like removal or adding of events or value.
         */
        USER_FOLLOWERS_REF.child(uid).observe(.value) { (snapshot) in
            if let snapshot = snapshot.value as? Dictionary<String,AnyObject>{
                numberOfFollowers = snapshot.count
            }
            else{
                numberOfFollowers = 0
            }
            let attributeText = NSMutableAttributedString(string: "\(numberOfFollowers!)\n", attributes: [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 14)])
            attributeText.append(NSAttributedString(string: "followers", attributes:[NSAttributedString.Key.font:UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor:UIColor.lightGray]))
            header.followersLabel.attributedText = attributeText
        }
        /*
         ObserveSingleEvent is only observe our database one time, can not update changes in real time.
         */
        USER_FOLLOWING_REF.child(uid).observe(.value) { (snapshot) in
            if let snapshot = snapshot.value as? Dictionary<String,AnyObject>{
                numberOfFollowings = snapshot.count
            }
            else{
                numberOfFollowings = 0
            }
            let attributeText = NSMutableAttributedString(string: "\(numberOfFollowings!)\n", attributes: [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 14)])
            attributeText.append(NSAttributedString(string: "followings", attributes:[NSAttributedString.Key.font:UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor:UIColor.lightGray]))
            header.followingLabel.attributedText = attributeText
        }
        
        // Get the number of posts
        USER_POSTS_REF.child(uid).observe(.value) { (snapshot) in
            if let snapshot = snapshot.value as? Dictionary<String,AnyObject>{
                numberOfPosts = snapshot.count
            }
            else{
                numberOfPosts = 0
            }
            let attributeText = NSMutableAttributedString(string: "\(numberOfPosts!)\n", attributes: [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 14)])
            attributeText.append(NSAttributedString(string: "posts", attributes:[NSAttributedString.Key.font:UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor:UIColor.lightGray]))
            header.postLabel.attributedText = attributeText
        }
    }
    
    // Handler Following Tapped
    func handleFollowingsTapped(for header: UserProfileHeader) {
        let followVC = FollowLikeVC()
        followVC.viewMode = FollowLikeVC.viewMode(index: 0)
        followVC.uid = user?.uid
        navigationController?.pushViewController(followVC, animated: true)
    }
    
    // Handle Follower Tapped
    func handleFollowersTapped(for header: UserProfileHeader) {
        let followVC = FollowLikeVC()
        
        followVC.viewMode = FollowLikeVC.viewMode(index: 1)
        followVC.uid = user?.uid
        navigationController?.pushViewController(followVC, animated: true)
    }
    
    // Reorder Our Posts
    func reorderPosts(coordinator: UICollectionViewDropCoordinator, destinationIndexPath : IndexPath, collectionView:UICollectionView){
        // Animates multiple insert, delete, reload, and move operations as a group.
        // The first item is the one we drag.
        if let post = coordinator.items.first,let sourceIndexPath = post.sourceIndexPath {
            collectionView.performBatchUpdates({
                // Remove the item
                self.posts.remove(at: sourceIndexPath.item )
                // Insert the item
                self.posts.insert(post.dragItem.localObject as! Post, at: destinationIndexPath.item)
                
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }, completion: nil)
            // Animates the item to the specified index path in the collection view.
            coordinator.drop(post.dragItem, toItemAt: destinationIndexPath)
        }
        
        
    }
}

// Drag and Drop

extension ProfileVC: UICollectionViewDropDelegate{
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag{
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }else{
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath : IndexPath
        if let indexPath = coordinator.destinationIndexPath{
            destinationIndexPath = indexPath
        }
        else{
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section) - 1
            destinationIndexPath = IndexPath(item: row, section: section)
            
        }
        
        if coordinator.proposal.operation == .move{
            reorderPosts(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        }
        
    }
    
    
    
}
extension ProfileVC: UICollectionViewDragDelegate{
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let post = self.posts[indexPath.row]
        let itemProvider = NSItemProvider(object: post.caption as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = post
        return [dragItem]
        
    }
    
    
}
