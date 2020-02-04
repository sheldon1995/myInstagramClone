//
//  CommentVC.swift
//  InstgramClone
//
//  Created by Sheldon on 1/16/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
private let reuseIdentifier = "CommentCell"

class CommentVC:UICollectionViewController,UICollectionViewDelegateFlowLayout{
    // MARK: Properties
    var post:Post?
    var comments = [Comment]()
    
    // Clean up code by using CommentInputAccessoryView
    lazy var containerView : CommentInputAccessoryView = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 60)
        let containerView = CommentInputAccessoryView(frame: frame)
        // It is necessary
        containerView.delegate = self
        
        containerView.backgroundColor = .white
        
    
        return containerView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Navigation title.
        navigationItem.title = "Comments"
        
        // If this property is set to true and bounces is true, vertical dragging is allowed even if the content is smaller than the bounds of the scroll view.
        collectionView.alwaysBounceVertical = true
        
        // The keyboard follows the dragging touch offscreen, and can be pulled upward again to cancel the dismiss.
        collectionView.keyboardDismissMode = .interactive
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0)
        
        // Register cell classes.
        self.collectionView!.register(CommentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Background color.
        collectionView.backgroundColor = .white
        
        // Get all comments assiciated with the post.
        fetchComments()
        
    }
    // This function defines the actions happened before the next view show up.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    // This function defines the actions happened after the next view show up.
    // When changed to this Comment view, hide the tabBar.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // Show the container view at the bottom
    override var inputAccessoryView: UIView?{
        get{
            return containerView
        }
    }
    // Let keyboard to show up.
    override var canBecomeFirstResponder: Bool{
        return true
    }
    // MARK: UICollection View
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Dynamiclly expand the size of cell, without this, some long comments will be cut.
        
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        // The dummcell is initialized with this frame
        let dummCell = CommentCell(frame: frame)
        dummCell.comment = comments[indexPath.row]
        // Lays out the subviews immediately, if layout updates are pending.
        dummCell.layoutIfNeeded()
        // The max size that the cell expand.
        let targetSize = CGSize(width: collectionView.frame.width, height: 1000)
        let estimatedSize = dummCell.systemLayoutSizeFitting(targetSize)
        
        // Returns the greater of two comparable values.
        let height = max(40+8+8, estimatedSize.height)
        return CGSize(width: view.frame.width, height:height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CommentCell
        cell.comment = comments[indexPath.row]
        // This function must be called.
        handleHashtagTapped(forCell: cell)
        handleMentionTapped(forCell: cell)
        return cell
    }
    
    // MARK: Handler

    func uploadCommentNotificationToServer(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let postId = self.post?.postId else {return}
        guard let ownerId = self.post?.ownerId else {return}
        let creationDate = Int(NSDate().timeIntervalSince1970)
        // We don't send notificaiton to the current user.
        if currentUid != self.post?.ownerId{
            let values = ["checked":0,
                          "creationDate": creationDate,
                          "uid":currentUid,
                          "type":COMMENT_INT_VALUE,
                          "postId":postId] as [String : Any]
            // Notification database reference
            let notificationRef = NOTIFICAITON_REF.child(ownerId).childByAutoId()
            notificationRef.updateChildValues(values)
            
        }
    }
    
    //MARK: API
    // Fetch all comments
    func fetchComments(){
        guard let postId = self.post?.postId else {return}
        COMMENT_REF.child(postId).observe(.childAdded) { (snapshot) in
            guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else { return }
            // let commentId = snapshot.key
            // print(snapshot)
            guard let uid = dictionary["uid"] as? String else {return}
            // Need to get user at this place rather than at the comment class to let the user escape from completion block and can be used in the comment cell.
            Database.fetchUser(with: uid) { (user) in
                let comment = Comment(user: user, dictionary: dictionary)
                self.comments.append(comment)
                // Necessary to call the reload data.
                self.collectionView?.reloadData()
            }
            
        }
    }
    
    func handleHashtagTapped(forCell cell: CommentCell){
        cell.commentLabel.handleHashtagTap { (hashtag) in
            let hashtagController = HashtagVC(collectionViewLayout: UICollectionViewFlowLayout())
            hashtagController.hashtag = hashtag
            self.navigationController?.pushViewController(hashtagController, animated: true)
        }
    }
    
    // When mention tag tapped.
    func handleMentionTapped(forCell cell:CommentCell){
        cell.commentLabel.handleMentionTap { (mention) in
            self.getMentionedUser(withUsername: mention)
        }
    }
    
}

extension CommentVC: CommentInputAccesoryViewDelegate{
    func didSubmit(forComment comment: String) {
        guard let postId = self.post?.postId else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let creationData = Int(NSDate().timeIntervalSince1970)
        
        let values = ["commentText":comment,
                      "uid":uid,
                      "creationData":creationData] as [String : Any]
        
        // Whenever our child values get updated at database, we set comment text field as nil
        COMMENT_REF.child(postId).childByAutoId().updateChildValues(values) { (err, ref) in
            self.uploadCommentNotificationToServer()
            // Send mention notification to user.
            if comment.contains("@")
            {
                self.uploadMentionNotification(forPostId: postId, withText: comment,withType: COMMENT_MENTION_INT_VALUE)
                
            }
            self.containerView.clearCommentTextView()
        }
    }
    
    
}
