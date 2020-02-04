//
//  ChatVC.swift
//  InstgramClone
//
//  Created by Sheldon on 1/20/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
private let reuseIdentifier = "Cell"

class ChatVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: Properties
    var user:User?
    var messages = [Message]()
    
    
    lazy var containerView : UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 100, height: 55)
        
        // Add post button first, to sovle the problem that if text inside the textfiled is too long and overlap the postButton.
        containerView.addSubview(postButton)
        postButton.anchor(top: nil, left: nil, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 12, width: 50, height: 0)
        postButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
        containerView.addSubview(messageTextField)
        messageTextField.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: postButton.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        
        
        let separatorView = UIView()
        separatorView.backgroundColor = .myLightGray
        containerView.addSubview(separatorView)
        separatorView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        // It solves the problem that the keyboard overlap the container.
        containerView.backgroundColor = .white
        return containerView
    }()
    let messageTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter message..."
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleSendMessage), for: .touchUpInside)
        return button
    }()
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        // Register cell classes
        self.collectionView!.register(ChatCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        configureNavigationBar()
        
        // Obser messages and get messages'id and fetch messages using fetchMessage() function.
        observeMessages()
    }
    
    // This function defines the actions happened before the next view show up.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    // This function defines the actions happened after the next view show up.
    // When changed to this Comment view, hide the tabBar.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // Show the container view at the bottom
       override var inputAccessoryView: UIView?{
           get{
               return containerView
           }
       }
       // Let keyboard to show up.
       override var canBecomeFirstResponder: Bool{
           return true
       }
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 80 is place hold value.
        var height:CGFloat = 80
        let message = messages[indexPath.row]
        height = estimateFrameForTest(message.messageText).height + 15

        return CGSize(width: view.frame.width, height: height)
    }
    // Number of section.
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // Set number of items in one section
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // Set cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ChatCell
        cell.message = messages[indexPath.row]
        configureMessages(cell: cell, message: messages[indexPath.row])
        return cell
    }
    
    // MARK: Handlers
    func configureNavigationBar(){
        guard let user = self.user else {return}
        // Set navigation item's title as user's username.
        navigationItem.title = user.userName
        let infoButton = UIButton(type: .infoLight)
        infoButton.tintColor = .black
        infoButton.addTarget(self , action: #selector(handleInfoTapped), for: .touchUpInside)
        // Right bar button item.
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.rightBarButtonItem = infoBarButtonItem
        
    }
    
    @objc func handleInfoTapped(){
        // When we click this button, it takes us to profile.
        // Need to initizlize the controller collectionViewLayout: UICollectionViewFlowLayout or CRASH.
        let userProfileController = ProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = self.user
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    @objc func handleSendMessage(){
        uploadMessageToServer()
        messageTextField.text = nil
    }
    
    // MARK: API
    func uploadMessageToServer(){
        guard let message = messageTextField.text else {return}
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let user = self.user else {return}
        guard let toId = user.uid else {return}
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        let messageValues = ["creationDate": creationDate,
                        "fromId":currentUid,
                        "toId":toId,
                        "messageText":message] as [String : Any]
        
        let messageRef = MESSAGE_REF.childByAutoId()
        guard let messageId = messageRef.key else {return}
        messageRef.updateChildValues(messageValues)
        
        // Upload message for current user
        USER_MESSAGES_REF.child(currentUid).child(toId).updateChildValues([messageId:1])
        // Upload message for other user.
        USER_MESSAGES_REF.child(toId).child(currentUid).updateChildValues([messageId:1])
    }
    
    func observeMessages(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let chatPartnerId = self.user?.uid else {return}
        
        USER_MESSAGES_REF.child(currentUid).child(chatPartnerId).observe(.childAdded) { (snapshot) in
            let messageId = snapshot.key
            self.fetchMessage(with: messageId)
        }
    }
    
    func fetchMessage(with messageId:String){
        MESSAGE_REF.child(messageId).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? Dictionary<String,AnyObject> else {return}
            let message = Message(dictionary: dictionary)
            
            self.messages.append(message)
            self.collectionView.reloadData()
            
        }
    }
    // Dynamiclly control the size of cell.
    func estimateFrameForTest (_ text:String) ->CGRect {
        let size = CGSize(width: 200, height: 100)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)], context: nil)
    }
    
    //
    func configureMessages(cell: ChatCell, message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        // Set the width of bubble according to message text.
        cell.bubbleWidthAnchor?.constant = estimateFrameForTest(message.messageText).width + 30
        // Set the height of bubble according to message text.
        cell.frame.size.height = estimateFrameForTest(message.messageText).height + 15
        // Configure cell based on who is talking
        if message.fromId == currentUid{
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.bubbleView.backgroundColor = .mainBlue
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
        }
        else{
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.bubbleView.backgroundColor = .mygray
            cell.textView.textColor = .black
            cell.profileImageView.isHidden = false
        }
        
    }
}
