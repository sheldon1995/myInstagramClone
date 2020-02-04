//
//  NotificationCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/16/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {
    // MARK: Properties
    var delegate :NotificationDelegte?
    var notification : Notification?{
        didSet{
            // Configure profile image.
            guard let user = notification?.user else {return}
            guard let profileImageUrl = user.profileImageUrl else {return}

            profileImageView.loadImage(with: profileImageUrl)
            
            // Configure notification label.
            configureNotificationLabel()
            
            // Configure notification type and set button or post image view.
            configureNotificationType()
            
        }
    }
    
    let profileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    let notificationLabel:UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }()
    
    lazy var followUnfollowButton : UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 3
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleFollowTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var postImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        let postTap = UITapGestureRecognizer(target: self, action: #selector(handlePostImageTapped))
        postTap.numberOfTouchesRequired = 1
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(postTap)
        return iv
    }()
    // MARK: Handlers
    @objc func handleFollowTapped(){
        delegate?.handleFollowTapped(for: self)
    }
    
    @objc func handlePostImageTapped(){
        delegate?.handlePostTapped(for: self)
    }
    
    // Congifute the notification label content.
    func configureNotificationLabel(){
        guard let notification = self.notification else {return}
        guard let user = notification.user else {return}
        guard let userName = user.userName else {return}
        // Configure notification time
        guard let notificationDate = getNotificationTime() else {return}
        
        
        let notificationMessage = notification.notificationType.description
        
        let attributedText = NSMutableAttributedString(string: "\(userName)", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)])
        attributedText.append(NSAttributedString(string: " \(notificationMessage)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
        attributedText.append(NSAttributedString(string: " \(notificationDate)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
        notificationLabel.attributedText = attributedText
    }
    
    // Configute notification type.
    func configureNotificationType(){
        guard let notification = self.notification else {return}
        // User is used to check if current user is following this one.
        guard let user = notification.user else {return}
        
        if notification.notificationType != .follow {
            addSubview(postImageView)
            postImageView.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 40, height: 40)
            postImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            if let post = notification.post
            {
                postImageView.loadImage(with: post.postImageUrl)
            }
            followUnfollowButton.isHidden = true
            postImageView.isHidden = false
        }
        else{
            
            addSubview(followUnfollowButton)
            followUnfollowButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 90, height: 30)
            followUnfollowButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

            followUnfollowButton.isHidden = false
            postImageView.isHidden = true
            
            // Set button's title by configuring if the user is followed or not.
            configureIsFollowed(user: user)
        }
        
        addSubview(notificationLabel)
        notificationLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 100, width: 0, height: 0)
        notificationLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        // print("DEBUG: Follow button width constraint is \(followUnfollowButton.frame.width)")
    }
    
    func configureIsFollowed(user:User){
        // Configure the user is followed or not by current user.
        user.checkIfUserIsFollowed(completion: {(followed) in
            if followed{
                self.followUnfollowButton.configure(didFollow: true)
            }
            else{
                self.followUnfollowButton.configure(didFollow: false)
            }
            
        })
    }
    
    func getNotificationTime() -> String?{
        guard let notif = self.notification else {return nil}
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.allowedUnits = [.second,.minute,.hour,.day,.weekOfMonth]
        dateFormatter.maximumUnitCount = 1
        dateFormatter.unitsStyle = .abbreviated
        let now = Date()
        let dateToDisplay = dateFormatter.string(from: notif.creationDate, to: now)
       
        return dateToDisplay
        
    }
    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // The selection style is a backgroundView constant that determines the color of a cell when it is selected
        selectionStyle = .none
        // Add profile image view
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        profileImageView.layer.cornerRadius = 40 / 2
        
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
