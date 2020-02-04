//
//  PostViewController.swift
//  InstgramClone
//
//  Created by Sheldon on 1/8/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase

class PostViewController: UIViewController, UITextViewDelegate {
    // MARK: Properties
    enum UploadAction{
        case UploadPost
        case SaveChanges
        
        init(index: Int){
            switch index {
            case 0: self = .UploadPost
            case 1: self = .SaveChanges
            default: self = .UploadPost
            }
        }
    }
    var inEditMode = false
    var selectedImage : UIImage?
    var toEditPost : Post?
    var uploadAction: UploadAction!
    let photoImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let captionTextView : UITextView = {
        let tv = UITextView()
        tv.backgroundColor = UIColor.systemGroupedBackground
        tv.font = UIFont.systemFont(ofSize: 12)
        return tv
    }()
    
    let actionButton : UIButton = {
        // Without the type, the button won't work when selected.
        let button = UIButton(type: .system)
        button.backgroundColor = .disableColor
        //button.setTitle("Share", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.isEnabled = false
        button.addTarget(self, action: #selector(handleUploadAction), for: .touchUpInside)
        return button
    }()
    
    // When the text is empty, disable the button
    func textViewDidChange(_ textView: UITextView) {
        guard !textView.text.isEmpty else {
            actionButton.isEnabled = false
            actionButton.backgroundColor = .disableColor
            return
        }
        actionButton.isEnabled = true
        actionButton.backgroundColor = .enableColor
    }
    
    
    
    // MARK: Handlers
    @objc func handleCancel(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateUserFeed(with postId:String){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        // Database valuse
        let values = [postId:1]
        
        // Let the current's follower see his post's id.
        USER_FOLLOWERS_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let followerUid = snapshot.key
            USER_FEED_REF.child(followerUid).updateChildValues(values)
        }
        // Update current user feed
        USER_FEED_REF.child(currentUid).updateChildValues(values)
    }
    
    @objc func handleUploadAction(){
        // Determine what actions are gonna happen.
        buttonSelector(uploadAction: uploadAction)
    }
    
    // Determine what actions are gonna happen.
    func buttonSelector(uploadAction: UploadAction){
        switch uploadAction {
        case .UploadPost:
            handleUploadPost()
        case .SaveChanges:
            handleEditPost()
        }
    }
    
    // Handle edit post
    func handleEditPost(){
        guard let post = self.toEditPost else {return}
        guard let changedText = captionTextView.text else {return}
        
        // Upload hash tag to server.
        uploadHashTagToServer(withPostId: post.postId)
        let creationData = Int(NSDate().timeIntervalSince1970)
        POST_REF.child(post.postId).child("creationDate").setValue(creationData)
        POST_REF.child(post.postId).child("caption").setValue(changedText) { (error, ref) in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // Handle upload post
    func handleUploadPost(){
        // Parameters
        guard
            let caption = captionTextView.text,
            let postImg = photoImageView.image,
            let currentUid = Auth.auth().currentUser?.uid else {return}
        
        // Image upload data
        guard let uploadData = postImg.jpegData(compressionQuality: 0.5) else { return }
        
        // Creation data
        let creationData = Int(NSDate().timeIntervalSince1970)
        
        // Update storage, an object representing a universally unique value that bridges to UUID
        let filename = NSUUID().uuidString
        
        // UPDATE: - In order to get download URL must add filename to storage ref like this
        let storageRef = STORAGE_PROFILE_IMG_REF.child(filename)
        
        storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
            // handle error
            if let error = error {
                print("Failed to upload image to Firebase Storage with error", error.localizedDescription)
                return
            }
            // UPDATE: - Firebase 5 must now retrieve download url
            storageRef.downloadURL(completion: { (downloadURL, error) in
                
                // Profile imagew url
                guard let profileImageUrl = downloadURL?.absoluteString else {
                    print("DEBUG: Profile image url is nil")
                    return
                }
                
                // Values is gonna be push to database.
                let values = ["caption": caption,
                              "creationDate": creationData,
                              "likes": 0,
                              "profileImageUrl": profileImageUrl,
                              "ownerId":currentUid] as [String : Any]
                
                
                let postId = POST_REF.childByAutoId()
                guard let postKey = postId.key else { return }
                // Upload info to database
                postId.updateChildValues(values, withCompletionBlock: { (error, ref) in
                    
                    // Update "user-post" structure, to find a user's posts' id quickly and then use these posts' id to fetch detailed post info from "posts" structure.
                    USER_POSTS_REF.child(currentUid).updateChildValues([postKey:1])
                    
                    
                    // Update post feed structure.
                    self.updateUserFeed(with: postKey)
                    
                    // Update the post' id to hashtag-post.
                    self.uploadHashTagToServer(withPostId: postKey)
                    
                    // Upload mention notification to server.
                    if caption.contains("@"){
                        self.uploadMentionNotification(forPostId: postKey, withText: caption,withType: POST_MENTION_INT_VALUE)
                    }
                    
                    CONSTANTS_FeedVC?.handleRefresh()
                    CONSTANTS_ProfileVC?.handleRefresh()
                    // Return to home page, by setting tab bar's index to 0, which is the index of main page.
                    self.dismiss(animated: true, completion:{
                        self.tabBarController?.selectedIndex = 0
                    })
                })
            })
        })
    }
    
    func configureViewComponents(){
        view.addSubview(photoImageView)
        photoImageView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 92, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
        
        view.addSubview(captionTextView)
        captionTextView.anchor(top: view.topAnchor, left: photoImageView.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 92, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 100)
        
        view.addSubview(actionButton)
        actionButton.anchor(top: photoImageView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 12, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 40)
    }
    
    func loadImage(){
        guard let selectedImage = selectedImage else {return}
        photoImageView.image = selectedImage
    }
    
    // MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // load image at image view.
        loadImage()
        
        // Configure all view components
        configureViewComponents()
        
        // Set text view delegate
        captionTextView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if uploadAction == .SaveChanges{
            guard let post = self.toEditPost else {return}
            guard let selectedImgUrl = post.postImageUrl else {return}
            self.navigationItem.title = "Edit Post"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
            navigationController?.navigationBar.tintColor = .black
            photoImageView.loadImage(with: selectedImgUrl)
            captionTextView.text = post.caption
            actionButton.setTitle("Save", for: .normal)
        }
        else{
            actionButton.setTitle("Share", for: .normal)
        }
        
    }
    
    // MARK: API
    func uploadHashTagToServer(withPostId postId:String){
        guard let caption = captionTextView.text else {return}
        
        // Split the sentence to single word and these words are stored in a string array.
        let words:[String] = caption.components(separatedBy: .whitespacesAndNewlines)
        
        // Loop the words array word by word to check the prefix.
        for var word in words {
            if word.hasPrefix("#")
            {
                // Grab the word and let it only contains the letters
                // Returns a character set containing the characters in Unicode General Category P*.
                word = word.trimmingCharacters(in: .punctuationCharacters)
                // Returns a character set containing the characters in Unicode General Category S*.
                word = word.trimmingCharacters(in: .symbols)
                
                word = word.lowercased()
                let hashTagValues = [postId:1]
                // Update value.
                HASHTAG_POST_REF.child(word).updateChildValues(hashTagValues)
            }
        }
    }
}
