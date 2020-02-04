//
//  SelectPhotoCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/11/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit

class SelectPhotoCell: UICollectionViewCell {
    
    // MARK: Properties
    let photoImageView: UIImageView = {
        
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
