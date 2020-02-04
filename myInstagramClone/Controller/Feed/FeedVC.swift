//
//  MainPageCollectionViewController.swift
//  InstgramClone
//
//  Created by Sheldon on 1/8/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
import ActiveLabel
private let reuseIdentifier = "FeedCell"

class FeedVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, FeedCellDelegate {
    
    
    // MARK: - Properties
    var user: User?
    var posts = [Post]()
    
    // Just view this single post.
    var viewSinglePost = false
    var post:Post?
    var currentKey: String?
    var userProfileController:ProfileVC?
    var searhTableController: SeachTableViewController?
    var firstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register cell classes
        self.collectionView!.register(FeedCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView.backgroundColor = .white
        
        // Configure refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        // Logout and share
        configureNavigationBar()
        
        // Set user's token
        setUserFCMToken()
        
        // It is uncessary to call fetchPosts() if we only want to show one post
        // Fetch all posts
        if !viewSinglePost
        {
            fetchPosts()
        }
        

        CONSTANTS_FeedVC = self
    }
    

    
    // MARK: UICollectionViewFlowLayout
    
    // Set collection view lay out for cell
    // We want one cell per row.
    // !!! If UICollectionViewDelegateFlowLayout is not included, this function won't work.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        var height = width + 8 + 40 + 8
        height += 110
        return CGSize(width: width, height: height)
    }
    
    // This function is called whenever a cell is gonna be displayed.
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if posts.count > 4{
            if indexPath.row == posts.count-1{
                // Call fetch posts again.
                fetchPosts()
            }
        }
    }
    
    // Return the number of sections
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // Return the number of items
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewSinglePost {
            return 1
        }
        else{
            return posts.count
            
        }
    }
    
    // Set cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FeedCell
        
        // set delegate, to make the delegate work!
        cell.delegate = self
        
        if viewSinglePost{
            if let post = self.post {
                cell.post = post              
            }
        }
        else{
            cell.post = posts[indexPath.row]
        }
        
        
        handleHashtagTapped(forCell: cell)
        handelUsernameLabelTapped(forCell: cell)
        handleMentionTapped(forCell: cell)
        return cell
    }
    
    // MARK: Handlers
    func handleShowLikes(for cell: FeedCell) {
        let followLikeVC = FollowLikeVC()
        guard let post = cell.post else {return}
        guard let postId = post.postId else {return}
        
        followLikeVC.postId = postId
        followLikeVC.viewMode = FollowLikeVC.viewMode(index: 2)
        
        navigationController?.pushViewController(followLikeVC, animated: true)
    }
    
    // Set the like button see if the post is alreaday liked by current user.
    func handleCongifureLikeButton(for cell: FeedCell) {
        guard let post = cell.post else {return}
        guard let postId = post.postId else {return}
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        USER_LIKES_REF.child(currentUid).observeSingleEvent(of: .value){(snapshot) in
            if snapshot.hasChild(postId){
                cell.likeButton.setImage(#imageLiteral(resourceName: "like_selected"), for: .normal)
                // Every post starts as false, need to set it as true if this post is already liked.
                post.didLike = true
            }
            else{
                cell.likeButton.setImage(#imageLiteral(resourceName: "like_unselected"), for: .normal)
               
            }
        }
    }
    
    // Refresh feed page.
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
    
    // Go to message VC.
    @objc func handleShowMessages(){
        let messageVC = MessagesVC()
        navigationController?.pushViewController(messageVC, animated: true)
    }
    
    // Log out
    @objc func handleLogOut(){
        // Declare alert controller
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Add alert action
        alertController.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: {
            (_) in
            do{
                // Attempt sign out
                try Auth.auth().signOut()
                
                // Present log in controller
                let navController = UINavigationController(rootViewController: LoginViewController())
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true, completion: nil)
                // "Successfully logged out"
            }
            catch{
                // Handle error
                print("Failed to sign out")
            }
        }))
        
        // Add cancel action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // Jump to a user's profile page when click the user's name at the feed cell.
    func handleUserNameButtonTapped(for cell: FeedCell) {
        // Get the post of this cell.
        guard let post = cell.post else {return}
        // Create instance of user profile vc
        let userProfileVC = ProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
        
        // Pass each user from searchVC to profileVC
        userProfileVC.user = post.user
        
        // Push new controller
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    
    // Delete, edit post.
    func handleOptionsTapped(for cell: FeedCell) {
        
        guard let post = cell.post else {return}
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        if post.ownerId == currentUid{
            // An action sheet displayed in the context of the view controller that presented it.
            let alertController = UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)
            // Destructive will display red text color.
            let deletePostAction = UIAlertAction(title: "Delete Post", style: .destructive, handler: { (_) in
                // Delete post
                post.deletePost()
                
                // Refresh the page
                if !self.viewSinglePost{
                    self.handleRefresh()
                }
                else{
                    if let userProfileControler = self.userProfileController{
                        userProfileControler.handleRefresh()
                        
                    }
                    if let searhTableController = self.searhTableController{
                        searhTableController.handleRefresh()
                    }
                    // Just pops the current view out of all views (go back to previous one)
                    _ = self.navigationController?.popViewController(animated: true)
                }
            })
            // Default will dispaly blue text color.
            let editPostAction = UIAlertAction(title: "Edit Post", style: .default) { (_) in
                // Edit post, present post VC.
                let postVC = PostViewController()
            
                postVC.inEditMode = true
                postVC.toEditPost = post
                // 1 means save changes.
                postVC.uploadAction = .init(index: 1)
                
                let navigationController = UINavigationController(rootViewController: postVC)
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController,animated: true, completion: nil)
     
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(deletePostAction)
            alertController.addAction(editPostAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
        
        
    }
    
    // When mention tag tapped.
    func handleMentionTapped(forCell cell:FeedCell){
        cell.captionLabel.handleMentionTap { (mention) in
            self.getMentionedUser(withUsername: mention)
        }
    }
    
    // Handle like button tapped
    func handleLikeTapped(for cell: FeedCell, isDoubleTapped:Bool) {
        guard let post = cell.post else {return}
        guard let postId = post.postId else {return}
        if post.didLike{
            // Unlike
            if !isDoubleTapped{
                // Double tap doesn't have any influenece to unlike
                post.adjustLikes(postId: postId, addLike: false,completion: {(likes) in
                    cell.likesLabel.text = "\(likes) likes"
                    cell.likeButton.setImage(#imageLiteral(resourceName: "like_unselected"), for: .normal)
                })
            }
        }
        else{
            // Handle like
            post.adjustLikes(postId: postId, addLike: true,completion: {(likes) in
                cell.likeButton.setImage(#imageLiteral(resourceName: "like_selected"), for: .normal)
                cell.likesLabel.text = "\(likes) likes"
            })
        }
    }
    
    // Handle comment tapped
    func handleCommentTapped(for cell: FeedCell) {
        // Pass the post id to comment vc to build comments structure.
        guard let post = cell.post else {return}
        let commentVC = CommentVC(collectionViewLayout: UICollectionViewFlowLayout())
        commentVC.post = post
        navigationController?.pushViewController(commentVC, animated: true)
    }
    
    // When hash tag tapped.
    func handleHashtagTapped(forCell cell:FeedCell){
        cell.captionLabel.handleHashtagTap { (hashtag) in
            let hashtagController = HashtagVC(collectionViewLayout: UICollectionViewFlowLayout())
            hashtagController.hashtag = hashtag
            self.navigationController?.pushViewController(hashtagController, animated: true)
        }
    }
    
    
    // When user name tapped
    func handelUsernameLabelTapped(forCell cell:FeedCell){
        guard let userName = cell.post?.user.userName else {return}
        let customType = ActiveType.custom(pattern:"^\(userName)\\b")
        cell.captionLabel.handleCustomTap(for: customType) { (_) in
            // Jump to user's profile.
            self.handleUserNameButtonTapped(for: cell)
        }
    }
    
    // MARK: API
    
    // Set Token according to uses rather than devices.
    func setUserFCMToken(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let fcmToken = Messaging.messaging().fcmToken else {return}
        
        let values = ["fcmToken": fcmToken]
        
        // Update fcm tokens for users who don't have fcm token.
        USER_REF.child(currentUid).updateChildValues(values)
    }
    
    
    // Add pagination. When we at the bottom, we want our fetchPosts() get called again.
    func fetchPosts()
    {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        // We only load 5 last post at once.
        if currentKey == nil{
             USER_FEED_REF.child(currentUid).queryLimited(toLast: 5).observeSingleEvent(of: .value) { (snapshot) in
                
                // Stop refreshing
                self.collectionView.refreshControl?.endRefreshing()
                // The fifth post from one fetch.
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                // Grab these 5 post and append to posts array.
                allObjects.forEach { (snapshot) in
                    let postId = snapshot.key
                    self.fetchPostsHelper(withPostId: postId)

                }
                // Record the last visited one.
                self.currentKey = first.key
            }
        }
        else{

            // Once user scroll down to the bottom.
            // queryOrderedByKey: is used to generate a reference to a view of the data that's been sorted by child key.
            // The upper bound (currentKey) is inclusive
            USER_FEED_REF.child(currentUid).queryOrderedByKey().queryEnding(atValue: self.currentKey).queryLimited(toLast: 6).observeSingleEvent(of: .value) { (snapshot) in
                // we don't want the duplicated one.
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                // Grab these 5 post and append to posts array.
                allObjects.forEach { (snapshot) in
                    let postId = snapshot.key
                    // we don't want the duplicated one.
                    if snapshot.key != self.currentKey {
                        self.fetchPostsHelper(withPostId: postId)
                    }
                }
                self.currentKey = first.key
            }
        }
    }
    
    func fetchPostsHelper(withPostId postId:String){
        
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
    
    func configureNavigationBar() {
        // If just show one post, give the "back" item to go back to profile page.
        if !viewSinglePost{
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "LogOut", style: .plain, target: self, action: #selector(handleLogOut))
            
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "send2"), style: .plain, target: self, action: #selector(handleShowMessages))
        self.navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo2"))
        
    }
}
