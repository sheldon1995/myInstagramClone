//
//  NotificationTableViewController.swift
//  InstgramClone
//
//  Created by Sheldon on 1/8/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
private let reuseIdentifier = "NotificationCell"


class NotificationTableViewController: UITableViewController,NotificationDelegte {
    
    
    // MARK: Properties
    var notifications = [Notification]()
    var currentKey:String?
    var timer:Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Notificaiton title
        navigationItem.title = "Notifications"
        // No sparator at table view
        tableView.separatorColor = .clear
        
        
        // Configure refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        // Register cell classes.
        tableView.register(NotificationCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        // Fetch notifications
        fetchNotifications()
    }
    
    // MARK: - TableViewDataSource
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if notifications.count > 4{
            if indexPath.row == notifications.count - 1{
                fetchNotifications()
            }
        }
    }
    
    // Click the cell, what will happen.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        let userProfileVC = ProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileVC.user = notification.user
        navigationController?.pushViewController(userProfileVC, animated: true)
        
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return notifications.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,for: indexPath) as! NotificationCell
        cell.notification = notifications[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    // MARK: API
    
    func fetchNotificationHelper(withNotificationId notificationId:String, dataSnapshot snapshot:DataSnapshot){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let dictionary = snapshot.value as? Dictionary<String,AnyObject> else {return}
        guard let uid = dictionary["uid"] as? String else {return}
        Database.fetchUser(with: uid) { (user) in
            // Check if the post exits, if so, this notification is like or comment type.
            if let postId = dictionary["postId"] as? String{
                Database.fetchPost(with: postId) { (post) in
                    let notification = Notification(user: user, post: post, dictionary: dictionary)
                    self.notifications.append(notification)
                    
                    // Stop refreshing
                    self.tableView.refreshControl?.endRefreshing()
                    // Get the newest notification
                    // Help to solve the bug that sometimes the button and postImage show up together.
                    self.handleReloadTable()
                }
            }
                // Follow type notification
            else{
                let notification =  Notification(user: user, dictionary: dictionary)
                self.notifications.append(notification)
                
                // Stop refreshing
                self.tableView.refreshControl?.endRefreshing()
                // Get the newest notification
                self.handleReloadTable()
            }
        }
        NOTIFICAITON_REF.child(currentUid).child(notificationId).child("checked").setValue(1)
    }
    // When fetch notifications, also set the "checked" value as 1.
    func fetchNotifications(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        if currentKey == nil{
            
            NOTIFICAITON_REF.child(currentUid).queryLimited(toLast: 5).observeSingleEvent(of: .value) { (snapshot) in
                // Stop refreshing
                self.tableView.refreshControl?.endRefreshing()
                
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                allObjects.forEach { (snapshot) in
                    let notificationId = snapshot.key
                    self.fetchNotificationHelper(withNotificationId: notificationId, dataSnapshot: snapshot)
                }
                self.currentKey = first.key
            }
        }
        else{
            NOTIFICAITON_REF.child(currentUid).queryOrderedByKey().queryEnding(atValue: self.currentKey).queryLimited(toLast: 10).observeSingleEvent(of: .value) { (snapshot) in
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                allObjects.forEach { (snapshot) in
                    let notificationId = snapshot.key
                    if notificationId != self.currentKey{
                        self.fetchNotificationHelper(withNotificationId: notificationId, dataSnapshot: snapshot)
                    }
                }
                self.currentKey = first.key
            }
        }
        
    }
    
    // Refresh feed page.
    @objc func handleRefresh(){
        // Remove all contents at posts array
        notifications.removeAll(keepingCapacity: false)
        
        
        currentKey = nil
        
        // Fetch post again, need to stop refreshing.
        fetchNotifications()
        
      
        // Reload data
        tableView.reloadData()
    }
    
    @objc func handleSortNotifications(){
        self.notifications.sort { (notif1, notif2) -> Bool in
            return notif1.creationDate > notif2.creationDate
        }
        self.tableView.reloadData()
    }
    
    func handleReloadTable(){
        self.timer?.invalidate()
        
        // Creates a timer and schedules it on the current run loop in the default mode.
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handleSortNotifications), userInfo: nil, repeats: false)
    }
    // MARK: Delegate
    func handleFollowTapped(for cell: NotificationCell) {
        guard let user = cell.notification?.user else {return}
        if user.isFollowed{
            // Unfollow
            user.unfollow()
            // Extension of button.
            cell.followUnfollowButton.configure(didFollow: false)
        }
        else{
            // Follow
            user.follow()
            // Extension of button.
            cell.followUnfollowButton.configure(didFollow: true)
        }
        
    }
    
    func handlePostTapped(for cell: NotificationCell) {
        guard let post = cell.notification?.post else {return}
        
        let feedController = FeedVC(collectionViewLayout: UICollectionViewFlowLayout())
        feedController.viewSinglePost = true
        feedController.post = post
        navigationController?.pushViewController(feedController, animated: true)
    }
}
