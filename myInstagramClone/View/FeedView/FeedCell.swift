//
//  FeedCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/13/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
import ActiveLabel
class FeedCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    // MARK: Properties
    var delegate: FeedCellDelegate?
    var isZooming = false
    var originalImageCenter:CGPoint?
    var post : Post?{
        didSet{
            
            guard let ownerUid = post?.ownerId else {return}
            guard let postImgUrl = post?.postImageUrl else {return}
            guard let likes = post?.likes else {return}
            guard let postTime = post?.creationDate else {return}
            
            Database.fetchUser(with: ownerUid) { (user) in
                self.profileImageView.loadImage(with: user.profileImageUrl)
                self.userNameButton.setTitle(user.userName, for: .normal)
                self.configurePostCaption(user: user)
            }
            photoImageView.loadImage(with: postImgUrl)
            likesLabel.text = "\(likes) like"
            captionLabel.text = post?.caption
            
            postTimeLabel.text = postTime.timeAgoToDisplay()
            // If the post is alreay liked, set heart as solid one.
            CongifureLikeButton()
            
        }
    }
    
    let profileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.zPosition = -1
        return iv
    }()
    
    // To make the target works, the button should be set as lazy var.
    lazy var userNameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Username", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.addTarget(self, action: #selector(handelUserNameTapped), for: .touchUpInside)
        // The reason the  label shows up above the image is because of the layers zPosition. Lets give the caption a negative zPosition value so that the imageView will always be above it.
        button.layer.zPosition = -1
        return button
    }()
    
    lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.addTarget(self, action: #selector(handleOptionsTapped), for: .touchUpInside)
        button.layer.zPosition = -1
        return button
    }()
    
    lazy var photoImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        // Add gesuture recognizer.
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapToLike))
        // The number of fingers required to tap for the gesture to be recognized.
        // Double tapped, so the number is 2.
        likeTap.numberOfTapsRequired = 2
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(likeTap)
        return iv
    }()
    
    // The tint color for this like button is to make the button's color from blue to black.
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
       
        button.tintColor = .black
        button.addTarget(self, action: #selector(handleLikeTapped), for: .touchUpInside)
        button.layer.zPosition = -1
        return button
    }()
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "comment"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(handlerCommentTapped), for: .touchUpInside)
        button.layer.zPosition = -1
        return button
    }()
    
    let messageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send2"), for: .normal)
        button.tintColor = .black
        button.layer.zPosition = -1
        return button
    }()
    
    let bookPostButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon"), for: .normal)
        button.tintColor = .black
        button.layer.zPosition = -1
        return button
    }()
    
    lazy var likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        
        // Add gesuture recognizer.
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(handleShowLikes))
        // The number of fingers required to tap for the gesture to be recognized.
        likeTap.numberOfTouchesRequired = 1
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(likeTap)
        label.layer.zPosition = -1
        return label
    }()
    
    let captionLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.numberOfLines = 0
        label.layer.zPosition = -1
        return label
    }()
    
    let postTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.layer.zPosition = -1
        return label
    }()
    
    // MARK: Functinos
    
    // likeButton,commentButton,messageButton
    func configureActionButton(){
        let stackView = UIStackView(arrangedSubviews: [likeButton,commentButton,messageButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        stackView.anchor(top: photoImageView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 120, height: 50)
        
        addSubview(bookPostButton)
        bookPostButton.anchor(top: photoImageView.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 14, width: 20, height: 24)
        
    }
    /*
     Steps to use hashtag:
     1. add sentence 'Pod ActiveLavel' to Podfile
     2. command "pod update"
     3. Change type of "captionLabel" from "UILabel" to "ActiveLabel".
     4. Change configurePostCaption(user) function. (We can't use attributed string anymore.)
     5.
     */
    func configurePostCaption(user:User){
        guard let post = self.post else {return}
        guard let postCaption = post.caption else {return}
        guard let userName = post.user.userName else {return}
        
        // Look for username as pattern
        let customType = ActiveType.custom(pattern:"^\(userName)\\b")
        
        captionLabel.enabledTypes = [.mention,.hashtag,.url,customType]
        
        captionLabel.configureLinkAttribute = { (type,attributes,isSelected) in
            var atts = attributes
            switch type {
            case .custom:
                // Set the size and font of user name.
                atts[NSAttributedString.Key.font] = UIFont.boldSystemFont(ofSize: 13)
            default:
                ()
            }
            return atts
        }
        captionLabel.customize { (label) in
            label.text = "\(userName) \(postCaption)"
            // Set color of username
            label.customColor[customType] = .black
            label.font = UIFont.systemFont(ofSize: 11)
            // Set color of caption text.
            label.textColor = .black
            captionLabel.numberOfLines = 2
        }
    }    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Note that returning true is guaranteed to allow simultaneous recognition
        return true
    }
    @objc func handelUserNameTapped(){
        delegate?.handleUserNameButtonTapped(for: self)
    }
    
    @objc func handleOptionsTapped(){
        delegate?.handleOptionsTapped(for: self)
    }
    
    @objc func handleLikeTapped(){
        delegate?.handleLikeTapped(for: self, isDoubleTapped: false)
    }
    @objc func handlerCommentTapped(){
        delegate?.handleCommentTapped(for: self)
    }
    
    @objc func CongifureLikeButton(){
        delegate?.handleCongifureLikeButton(for: self)
    }
    
    @objc func handleShowLikes(){
        delegate?.handleShowLikes(for: self)
    }
    
    @objc func handleDoubleTapToLike(){
        delegate?.handleLikeTapped(for: self, isDoubleTapped: true)
    }
    
    // MARK: Handlers
    @objc func handleZoom(sender:UIPinchGestureRecognizer){
        if sender.state == .began {
            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
            let newScale = currentScale*sender.scale
            if newScale > 1 {
                self.isZooming = true
            }
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.photoImageView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            guard let center = self.originalImageCenter else {return}
            UIView.animate(withDuration: 0.3, animations: {
                self.photoImageView.transform = CGAffineTransform.identity
                self.photoImageView.center = center
            }, completion: { _ in
                self.isZooming = false
            })
        }
        
    }
    @objc func handlepan(sender:UIPanGestureRecognizer){
        //  when the gesture state is “.began” we will set the originalImageCenter to the current center of the view, but only if isZooming is true:
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
        }
        else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.photoImageView.superview)
        }
        
    }
    //  if two gesture recognizers should be allowed to recognize gestures simultaneously.
    
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        profileImageView.layer.cornerRadius = 40/2
        
        addSubview(userNameButton)
        userNameButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        userNameButton.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(optionsButton)
        optionsButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        optionsButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        
        addSubview(photoImageView)
        photoImageView.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        // Height = Width
        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        
        configureActionButton()
        
        addSubview(likesLabel)
        likesLabel.anchor(top: likeButton.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: -4, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(captionLabel)
        captionLabel.anchor(top: likeButton.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 15, paddingLeft: 10, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        addSubview(postTimeLabel)
        postTimeLabel.anchor(top: captionLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 9, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(sender:)))
        pinch.delegate = self
        photoImageView.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlepan(sender:)))
        pan.delegate = self
        photoImageView.addGestureRecognizer(pan)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
