//
//  SearchUserCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/9/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit

class SearchUserCell: UITableViewCell {
    
    // Properties
    
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
        return iv
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        // A style for a cell with a left-aligned label across the top and a left-aligned label below it in smaller gray text.
        super.init(style: .subtitle, reuseIdentifier:reuseIdentifier)
        
        // Add profile image view
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 48, height: 48)
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 48 / 2
        
        // If we don't want the selectino color when click one cell
        self.selectionStyle = .none
                
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = CGRect(x:68, y:textLabel!.frame.origin.y  , width: textLabel!.frame.width, height:textLabel!.frame.height)
        textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        
        detailTextLabel?.frame = CGRect(x: 68, y:detailTextLabel!.frame.origin.y+2, width: self.frame.width, height: detailTextLabel!.frame.height)
        detailTextLabel?.textColor = .lightGray
        detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
