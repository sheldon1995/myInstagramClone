//
//  FollowCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/10/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
class FollowLikeCell: UITableViewCell {
    
    // Properties
    var delegate: FollowCellDelegate?
    var user: User?{
        didSet{
            configureFollowCellButton()
            
            guard let profileImageUrl = user?.profileImageUrl else { return }
            guard let userName = user?.userName else { return }
            profileImageView.loadImage(with: profileImageUrl)
            userNameLabel.text = userName
            
            // Hidden follow botton when click the current user's following/follower information
            if user?.uid == Auth.auth().currentUser?.uid{
                followUnfollowButton.isHidden = true
            }
        }
    }
    let profileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true

        return iv
    }()
    
    let userNameLabel:UILabel = {
        let userNameLab = UILabel() 
        userNameLab.font = UIFont.boldSystemFont(ofSize: 13)
        return userNameLab
    }()
    
    lazy var followUnfollowButton : UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 3
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.addTarget(self, action: #selector(handleFollowTapped), for: .touchUpInside)
        return button
    }()
    
    
    // MARK: Handlers
    @objc func handleFollowTapped() {
        delegate?.handleFollowTapped(for: self)
    }
    func configureFollowCellButton(){
        // Configure the user is followed or not by current user.
        // guard let otherUserId = user?.uid else {return}
        user?.checkIfUserIsFollowed(completion: {(followed) in
            if followed {
                self.followUnfollowButton.configure(didFollow: true)
            }
            else{
                self.followUnfollowButton.configure(didFollow: false)
            }
        })
    }
    
    
    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style,reuseIdentifier:reuseIdentifier)
        
        
        // Add profile image view
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 48, height: 48)
        profileImageView.layer.cornerRadius = 48 / 2
        
        addSubview(userNameLabel)
        userNameLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 100, height: 24)
        userNameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        addSubview(followUnfollowButton)
        followUnfollowButton.anchor(top: nil, left: nil, bottom: nil, right: self.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 100, height: 30)
        followUnfollowButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        // If we don't want the selectino color when click one cell
        self.selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
