//
//  CommentInputAccessoryView.swift
//  InstgramClone
//
//  Created by Sheldon on 1/27/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit

class CommentInputAccessoryView: UIView {
    
    // MARK: Properties
    var delegate: CommentInputAccesoryViewDelegate?
    
    let commentTextView: CommentInputTextView = {
        let tv = CommentInputTextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        return tv
    }()
    
    let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Post", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleCommentPost), for: .touchUpInside)
        return button
    }()
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // resizing performed by expanding or shrinking a view's height.
        autoresizingMask = .flexibleHeight
        
        // Add post button first, to sovle the problem that if text inside the textfiled is too long and overlap the postButton.
        addSubview(postButton)
        postButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 12, width: 50, height: 50)
        
        // safeAreaLayoutGuide: The layout guide representing the portion of your view that is unobscured by bars and other content.
        addSubview(commentTextView)
        commentTextView.anchor(top: topAnchor, left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: postButton.leftAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .myLightGray
        addSubview(separatorView)
        separatorView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ?
    override var intrinsicContentSize: CGSize{
        return .zero
    }
    
    func clearCommentTextView(){
        // Reset place holder to show up.
        commentTextView.placeholderLabel.isHidden = false
        commentTextView.text = nil
    }
    // MARK: Handlers
    @objc func handleCommentPost(){
        guard let comment = commentTextView.text else {return}
        delegate?.didSubmit(forComment: comment)
    }
    
}
