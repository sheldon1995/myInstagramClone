//
//  CommentInputTextView.swift
//  InstgramClone
//
//  Created by Sheldon on 1/27/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit

class CommentInputTextView: UITextView {
    let placeholderLabel : UILabel = {
        let label = UILabel()
        label.text = "Enter comment.."
        label.textColor = .myLightGray
        return label
    }()
    
    
    // MARK: Init
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame,textContainer: textContainer)
        
        // To solve the problem that the text inside the UIextView will overlap the "Enter comment"
        // Add an obsever, listening to the change of text view.
        NotificationCenter.default.addObserver(self, selector: #selector(handleInputTextChanged), name: UITextView.textDidChangeNotification, object: nil)
        
        addSubview(placeholderLabel)
        placeholderLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Handlers
    
    // When text is not empty, hidden place holder.
    @objc func handleInputTextChanged(){
        placeholderLabel.isHidden = !self.text.isEmpty
    }

}
