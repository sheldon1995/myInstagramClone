//
//  ChatCell.swift
//  InstgramClone
//
//  Created by Sheldon on 1/20/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
class ChatCell: UICollectionViewCell {
    
    // MARK: Variables
    
    // Set a anchor.
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    var message : Message?{
        didSet{
            // Set text
            guard let messageText = message?.messageText else {return}
            textView.text = messageText
            
            // Set image url
            guard let chatPartnerId = message?.getChatPartnerId() else {return}
            Database.fetchUser(with: chatPartnerId) { (user) in
                guard let profileImgUrl = user.profileImageUrl else {return}
                self.profileImageView.loadImage(with: profileImgUrl)
            }
        }
    }
    
    let bubbleView : UIView = {
        let view = UIView()
        view.backgroundColor = .mainBlue
        view.layer.cornerRadius = 14
        // A Boolean indicating whether sublayers are clipped to the layer’s bounds.
        // Core Animation creates an implicit clipping mask that matches the bounds of the layer and includes any corner radius effects.
        view.layer.masksToBounds = true
        // A Boolean value that determines whether the view’s autoresizing mask is translated into Auto Layout constraints.
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 15)
        tv.backgroundColor = .clear
        tv.textColor = .white
        tv.isEditable = false
        // A Boolean value that determines whether the view’s autoresizing mask is translated into Auto Layout constraints.
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    // MARK: Properties
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: -4, paddingRight: 9, width: 32, height: 32)
        profileImageView.layer.cornerRadius = 32/2
        
        
        // Bubble view right anchor
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        bubbleViewRightAnchor?.isActive = true
        
        // Bubble view left anchor
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        bubbleViewLeftAnchor?.isActive = false
        
        // Bubble view top anchor
        bubbleView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        
        // Bubble view width anchor
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        
        // Bubble view height anchor
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        // bubble view text view anchor
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
