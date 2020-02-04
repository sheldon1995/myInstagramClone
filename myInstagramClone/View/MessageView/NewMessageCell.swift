//
//  NewMessageCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/20/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit

class NewMessageCell: UITableViewCell {
    // MARK: Properties
    
    var user: User?{
        didSet{
            guard let profileImageUrl = user?.profileImageUrl else { return }
            guard let userName = user?.userName else { return }
            guard let fullName = user?.name else { return }
            // Set photo, texttable and detail text table.
            profileImageView.loadImage(with: profileImageUrl)
            textLabel?.text = userName
            detailTextLabel?.text = fullName
        }
    }
    
    let profileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        //iv.backgroundColor = .lightGray
        return iv
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
        
        //textLabel?.text = "Gege Fan"
        //detailTextLabel?.text = "I am pretty good today."
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    
}
