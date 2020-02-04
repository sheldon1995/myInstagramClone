//
//  UserProfileHeader.swift
//  InstgramClone
//
//  Created by Sheldon on 1/9/20.
//  Copyright © 2020 wentao. All rights reserved.
//
/*
 To fix image flicker (photos get dulicated).
 */
import UIKit
import Firebase
class UserProfileHeader: UICollectionViewCell {
    
    // MARK: Properties
    var delegate: UserProfileHeaderDelegate?
    
    var user: User?{
        didSet{
            // Configure edit profile button
            configureEditProfileFollowButton()
            
            // Set user stats
            setUserStats(for: user)
            
            // Set fullName
            let fullName = user?.name
            nameLabel.text = fullName
        
            // Set profile image
            guard let profileImageUrl = user?.profileImageUrl else {return}
            profileImageView.loadImage(with: profileImageUrl)
        }
    }
    
    
    let profileImageView: CustomImageView = {
        /*
         Create an ImageView
         Set needed properities
         Return this ImageView
         */
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = .black
        return label
    }()
    
    let postLabel : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        
        let attributedText = NSMutableAttributedString(string: "5\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: "posts", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
        label.attributedText = attributedText
        return label
    }()
    
    // change the label to lazy var to be able to recognize these type gestur recognizes that are about to add.
    lazy var followersLabel : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        
        let attributedText = NSMutableAttributedString(string: "\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: "followers", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
        label.attributedText = attributedText
        // Add gesuture recognizer.
        let followTap = UITapGestureRecognizer(target: self, action: #selector(handleFollowersTapped))
        // The number of fingers required to tap for the gesture to be recognized.
        followTap.numberOfTouchesRequired = 1
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(followTap)
        return label
    }()
    
    // change the label to lazy var to be able to recognize these type gestur recognizes that are about to add.
    lazy var followingLabel : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        
        let attributedText = NSMutableAttributedString(string: "\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: "followings", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
        label.attributedText = attributedText
        // Add gesuture recognizer.
        let followTap = UITapGestureRecognizer(target: self, action: #selector(handleFollowingsTapped))
        // The number of fingers required to tap for the gesture to be recognized.
        followTap.numberOfTouchesRequired = 1
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(followTap)
        
        return label
    }()
    
    lazy var editProfileFollowButton : UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Loading", for: .normal)
        button.layer.cornerRadius = 3
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleEditProfileFollow), for: .touchUpInside)
        return button
    }()
    
    let gridButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "grid"), for: .normal)
        return button
    }()
    
    
    let listButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "list"), for: .normal)
        return button
    }()
    
    let bookmarkButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon"), for: .normal)
        return button
    }()
    
    // MARK: Handlers
    
    @objc func handleFollowersTapped(){
        delegate?.handleFollowersTapped(for: self)
    }
    
    @objc func handleFollowingsTapped(){
        delegate?.handleFollowingsTapped(for: self)
    }
    
    // Deal with events when click edit/follow/unfollow
    @objc func handleEditProfileFollow(){
        delegate?.handleEditFollowTapped(for: self)
    }
    
    func setUserStats(for user: User?){
        delegate?.setUserStats(for: self)
    }
    // Configure users' stats
    func configureUserStats(){
        let stackView = UIStackView(arrangedSubviews: [postLabel, followersLabel, followingLabel])
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        stackView.anchor(top: self.topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 12, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 50)
    }
    
    
    
    
    func configureToolBar(){
        let topDividerView = UIView()
        topDividerView.backgroundColor = .lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = .lightGray
        
        let stackView = UIStackView(arrangedSubviews: [gridButton,listButton,bookmarkButton])
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        addSubview(topDividerView)
        addSubview(bottomDividerView)
        
        stackView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        topDividerView.anchor(top: stackView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
    }
    
    // The user's id == current user's id, button's title is "Edit profile", else "Follow"
    func configureEditProfileFollowButton(){
        guard let currentUid = Auth.auth().currentUser?.uid else {
            return
        }
        guard let user = self.user else {
            return
        }
        if currentUid == user.uid{
            editProfileFollowButton.setTitle("Edit Profile", for: .normal)
            editProfileFollowButton.setTitleColor(.black, for: .normal)
        }
        else{
            // Configure the user is followed or not by current user.
            user.checkIfUserIsFollowed(completion: {(followed) in
                if followed{
                    self.editProfileFollowButton.setTitle("Following", for: .normal)
                }
                else{
                    self.editProfileFollowButton.setTitle("Follow", for: .normal)
                }
                
            })
            
            editProfileFollowButton.setTitleColor(.white, for: .normal)
            editProfileFollowButton.backgroundColor = .mainBlue
        }
    }
    
    
    
    // MARK: Init
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: self.topAnchor, left: self.leftAnchor, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 80, height: 80)
        profileImageView.layer.cornerRadius = 80 / 2
        
        addSubview(nameLabel)
        nameLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        nameLabel.anchor(top: profileImageView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        
        configureUserStats()
        
        addSubview(editProfileFollowButton)
        editProfileFollowButton.anchor(top: postLabel.bottomAnchor, left: postLabel.leftAnchor, bottom: nil, right: self.rightAnchor, paddingTop: 4, paddingLeft: 8, paddingBottom: 0, paddingRight: 12, width: 0, height: 30)
        configureToolBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
