//
//  ProfilePostCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/12/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit

class ProfilePostCell: UICollectionViewCell {
    
    var post: Post?{
        didSet{
            guard let postImageUrl = post?.postImageUrl else { return }
            postImageView.loadImage(with: postImageUrl)
        }
    }
    
    // MARK: Properties
    let postImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame:frame)
        addSubview(postImageView)
        postImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
