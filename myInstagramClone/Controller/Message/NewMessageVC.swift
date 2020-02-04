//
//  NewMessageController.swift
//  InstgramClone
//
//  Created by Sheldon on 1/20/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
class NewMessageVC : UITableViewController{
    var reuseIdentifier = "NewMesssageCell"
    var users = [User]()
    var messageController : MessagesVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register cell classes
        tableView.register(NewMessageCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        // Configure navigatino bar.
        configureNavigationBar()
        
        // Fetch suggested users.
        fetchFollowingUsers()
    }
    
    // MARK: - Table view data source
    // Number of sections.
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    // Number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    // Height for row at.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    // Set cell.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! NewMessageCell
        cell.user = users[indexPath.row]
        return cell
    }
    
    // Did select.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.messageController?.showChatController(forUser: user)
        }
    }
    
    func configureNavigationBar(){
        navigationItem.title = "New Message"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.leftBarButtonItem?.tintColor = .black
    }
    
    // MARK: Handlers
    // Jump back to the previous page.
    @objc func handleCancel(){
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: API
    // Fetch following users, these users are suggested talking object.
    func fetchFollowingUsers(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        USER_FOLLOWING_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let userId = snapshot.key
            Database.fetchUser(with: userId) { (user) in
                self.users.append(user)
                // Don't forget to reload data in table view.
                self.tableView.reloadData()
            }
        }
    }
}
