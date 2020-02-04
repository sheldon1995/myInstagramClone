//
//  MessagesVC.swift
//  InstgramClone
//
//  Created by Sheldon on 1/19/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
class MessagesVC: UITableViewController {
    var reuseIdentifier = "MesssageCell"
    var messages = [Message]()
    var messagesDictionary = [String:Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register cell classes
        tableView.register(MessageCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        // Configure navigatino bar.
        configureNavigationBar()
        
        // Fetch message to show them at Message view controller
        fetchMessages()
    }
    
    // MARK: - Table view data source
    // Number of sections.
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    // Number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return messages.count
    }
    
    // Height for row at
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    // Set cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! MessageCell
        cell.message = messages[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        let chatPartnerId = message.getChatPartnerId()
        Database.fetchUser(with: chatPartnerId) { (user) in
            self.showChatController(forUser: user)
        }
    }
    
    // MARK: Handlers
    func configureNavigationBar(){
        navigationItem.title = "Messages"
        // A button specialized for placement on a toolbar or tab bar.
        // Add 十 as the right bar button item.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNewMessage))
    }
    
    func showChatController(forUser user: User){
        let chatController = ChatVC(collectionViewLayout: UICollectionViewFlowLayout())
        chatController.user = user
        navigationController?.pushViewController(chatController, animated: true)
    }
    
    
    @objc func handleNewMessage(){
        let newMessageController = NewMessageVC()
        // Need call showChatController(user) at NewMessageVC by define a  var messageController : MessagesVC? at NewMessageVC.
        newMessageController.messageController = self
        let navigationController = UINavigationController(rootViewController: newMessageController)
        navigationController.modalPresentationStyle = .fullScreen
        self.present(navigationController,animated: true,completion: nil)
    }
    
    // MARK: API
    // Get into "user-messages" structure, find the current user and get all messages' id and fetch messages from "messages" structure.
    func fetchMessages(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        // Clean up
        self.messages.removeAll()
        self.messagesDictionary.removeAll()
        self.tableView.reloadData()
        
        // Get all chatting user id
        USER_MESSAGES_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            
            let uid = snapshot.key
            // Get all message id related to one user.
            USER_MESSAGES_REF.child(currentUid).child(uid).observe(.childAdded) { (snapshot) in
                let messageId = snapshot.key
                self.fetchMessage(with: messageId)
            }
        }
    }
    
    func fetchMessage(with messageId:String){
        MESSAGE_REF.child(messageId).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? Dictionary<String,AnyObject> else {return}
            let message = Message(dictionary: dictionary)
            // This is the key we want to use to dictionary.
            let chatPartnerId = message.getChatPartnerId()
            //
            self.messagesDictionary[chatPartnerId] = message
            self.messages = Array(self.messagesDictionary.values)
            
            self.tableView.reloadData()
            
        }
    }
    
}
