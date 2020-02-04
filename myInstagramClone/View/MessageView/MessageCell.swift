//
//  MessageCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/19/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
class MessageCell: UITableViewCell {
    // MARK: Properties
    var message:Message?{
        didSet{
            guard let messageText = message?.messageText else {return}
            detailTextLabel?.text = messageText
            if let seconds = message?.creationDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                timeLabel.text = dateFormatter.string(from: seconds)
            }
            
            configureUserData()
        }
    }
    let profileImageView: CustomImageView = {

        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    let timeLabel : UILabel = {
        let label = UILabel()
        label.text = "1 day ago"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()
    
    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        // The cell has no distinct style for when it is selected.
        selectionStyle = .none
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        profileImageView.layer.cornerRadius = 50 / 2
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(timeLabel)
        timeLabel.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 12, width: 0, height: 0)

    }
    
    // Configure text label and detail text label.
    override func layoutSubviews() {
        // If don't call this, the whole function won't work.
        super.layoutSubviews()
        // Set text and detail text label fram
        textLabel?.frame = CGRect(x: 68, y: textLabel!.frame.origin.y, width: self.frame.width, height: (textLabel?.frame.height)!)
        detailTextLabel?.frame = CGRect(x: 68, y: detailTextLabel!.frame.origin.y, width: self.frame.width, height: (textLabel?.frame.height)!)
        
        textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
        detailTextLabel?.textColor = .lightGray
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Handlers
    func configureUserData(){
        // Who we are talking to.
        guard let chatPartnerId = message?.getChatPartnerId() else {return}
        Database.fetchUser(with: chatPartnerId) { (user) in
            self.profileImageView.loadImage(with: user.profileImageUrl)
            self.textLabel?.text = user.userName
        }
    }
    
}
