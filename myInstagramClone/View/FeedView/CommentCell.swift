//
//  CommentCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/16/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import ActiveLabel
class CommentCell: UICollectionViewCell {
    // MARK: Properties
    var comment: Comment?{
        didSet{
            // Set profile image
            guard let user = comment?.user else {return}
            guard let profileImageUrl = user.profileImageUrl else {return}
            
            // Set comment label (Activelabel)
            configureCommentLable()
            
            //let creationDate = comment.creationDate
            profileImageView.loadImage(with: profileImageUrl)
            
        }
    }
    
    let profileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let commentLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.enabledTypes = [.mention,.hashtag]
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        return label
    }()
    
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame:frame)
        // Add profile image view
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        profileImageView.layer.cornerRadius = 40 / 2
        
        addSubview(commentLabel)
        commentLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 4, paddingLeft: 8, paddingBottom: 0, paddingRight: 4, width: 0, height: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Functions
    func getCommentTime() -> String?{
        guard let comment = self.comment else {return nil}
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.allowedUnits = [.second,.minute,.hour,.day,.weekOfMonth]
        dateFormatter.maximumUnitCount = 1
        dateFormatter.unitsStyle = .abbreviated
        let now = Date()
        let dateToDisplay = dateFormatter.string(from: comment.creationDate, to: now)
        
        return dateToDisplay
        
    }
    
    func configureCommentLable(){
        guard let user = comment?.user else {return}
        guard let userName = user.userName else {return}
        guard let comment = self.comment else {return}
        guard let commentText = comment.comment else {return}
        // guard let commentTime = getCommentTime() else {return}
        
        // Look for username as pattern
        let customType = ActiveType.custom(pattern:"^\(userName)\\b")
        
        commentLabel.enabledTypes = [.mention,.hashtag,.url,customType]
        
        commentLabel.configureLinkAttribute = { (type,attributes,isSelected) in
            var atts = attributes
            switch type {
            case .custom:
                // Set the size and font of user name.
                atts[NSAttributedString.Key.font] = UIFont.boldSystemFont(ofSize: 12)
            default:
                ()
            }
            return atts
        }
        commentLabel.customize { (label) in
            label.text = "\(userName) \(commentText)"
            // Set color of username
            label.customColor[customType] = .black
            label.font = UIFont.systemFont(ofSize: 12)
            // Set color of comment text.
            label.textColor = .black
        }
    }
    
}
