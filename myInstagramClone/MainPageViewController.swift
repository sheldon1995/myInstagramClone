//
//  MainPageViewController.swift
//  InstgramClone
//
//  Created by Sheldon on 1/8/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
class MainPageViewController: UITabBarController, UITabBarControllerDelegate {
    
    // MARK: Properties
    let dot = UIView()
    var notificationIds = [String]()
    var didCheckEveryNotification = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // The tab bar controller’s delegate object.
        // You can use the delegate object to track changes to the items in the tab bar and to monitor the selection of tabs.
        self.delegate = self
        // Configure view controllers
        configureViewController()
        
        // Ovserve whether all notifications are checked.
        observeNotifications()
        
        // Configure notification dot
        configureNotificationBar()
        
        
        // Check user validation
        checkIfUserLoggedIn()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    // Function to create view controllers that exist within tab bar controller
    func configureViewController(){
        // Home controller
        let feedVC = configureNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: FeedVC(collectionViewLayout: UICollectionViewFlowLayout()))
        
        // Search controller
        let searchVC = configureNavController(unselectedImage: #imageLiteral(resourceName: "comment"), selectedImage: #imageLiteral(resourceName: "search_selected"), rootViewController: SeachTableViewController())
    
        
        // Select image controller
        let selectImageVC = configureNavController(unselectedImage: #imageLiteral(resourceName: "plus_unselected"), selectedImage: #imageLiteral(resourceName: "plus_unselected"))
        
        
        // Notification controller
        let notificationVC = configureNavController(unselectedImage: #imageLiteral(resourceName: "like_unselected"), selectedImage: #imageLiteral(resourceName: "like_selected"), rootViewController: NotificationTableViewController())
        
        // Profile controller
        let profileVC = configureNavController(unselectedImage: #imageLiteral(resourceName: "profile_selected"), selectedImage: #imageLiteral(resourceName: "profile_selected"), rootViewController: ProfileVC(collectionViewLayout:UICollectionViewFlowLayout()))
        
    
        // View controller added to tab bar
        viewControllers = [feedVC,searchVC,selectImageVC,notificationVC,profileVC]
        
        // Tab bar tint color
        tabBar.tintColor = .black
    }
    
    // MARK: UITableBarController
    // Whenever we select a view controller in our tab bar, the function is called.
    // Index starts from 0 ...
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.firstIndex(of: viewController)
        if index == 2 {
            
            let selectImageVC = SelectImageVC(collectionViewLayout: UICollectionViewFlowLayout())
            
            let navController = UINavigationController(rootViewController: selectImageVC)
            
            // Present page with full screen.
            navController.modalPresentationStyle = .fullScreen
            
            // Navigation bar is the space at the top, like back, next.
            navController.navigationBar.tintColor = .black
            present(navController, animated: true, completion: nil)
            return false
        }
        else if index == 3{
            dot.isHidden = true
            return true
        }
        return true
    }
    
    // Construct navigation controllers
    func configureNavController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController = UIViewController())->UINavigationController{
        let navController = UINavigationController(rootViewController: rootViewController)
        
        // The image used to represent the item.
        navController.tabBarItem.image = unselectedImage
        
        // The image displayed when the tab bar item is selected.
        navController.tabBarItem.selectedImage = selectedImage
        
        navController.navigationBar.tintColor = .black
        
        return navController
    }
    
    // MARK: Functions
    // Check if user is logged in.
    func checkIfUserLoggedIn(){
        if Auth.auth().currentUser == nil{
            DispatchQueue.main.async{
                // Present log in controller.
                let navController = UINavigationController(rootViewController:LoginViewController())
                // Present page with full screen.
                navController.modalPresentationStyle = .fullScreen
                // Navigate to the page.
                self.present(navController, animated: true, completion: nil)
            }
        }
    }
    
    func configureNotificationBar(){
        
        if UIDevice().userInterfaceIdiom == .phone {
            
            let tabBarHeight = tabBar.frame.height
          
            if UIScreen.main.nativeBounds.height == 2436 {
                // configure dot for iphone x
                dot.frame = CGRect(x: view.frame.width / 5 * 3, y: view.frame.height - tabBarHeight, width: 6, height: 6)
            } else {
                // configure dot for other phone models
                dot.frame = CGRect(x: view.frame.width / 5 * 3, y: view.frame.height - 16, width: 6, height: 6)
            }
            
            // create dot
            dot.center.x = (view.frame.width / 5 * 3 + (view.frame.width / 5) / 2)
            dot.backgroundColor = UIColor(red: 233/255, green: 30/255, blue: 99/255, alpha: 1)
            dot.layer.cornerRadius = dot.frame.width / 2
            self.view.addSubview(dot)
            dot.isHidden = true
        }
    }
    // If any one of notifications is unchecked, set dot.isHidden = false
    func observeNotifications(){
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        /*
         If we logged out A with another user B, if we send notification to A, the dot appears at the b's notification's icon.
         Because we are using observe(.childAdded).
         childAdded ususally show action dynamaticly.
         */
        // Clean up the array.
        self.notificationIds.removeAll()
        NOTIFICAITON_REF.child(currentUid).observeSingleEvent(of: .value) { (snapshot) in
            guard let allObject = snapshot.children.allObjects as? [DataSnapshot] else {return}
            allObject.forEach { (snapshot) in
                let notificationId = snapshot.key
                NOTIFICAITON_REF.child(currentUid).child(notificationId).child("checked").observeSingleEvent(of: .value) { (snapshot) in
                    guard let checked = snapshot.value as? Int else {return}
                    // Is not checked
                    if checked == 0 {
                        self.dot.isHidden = false
                    }
                        // It is checked
                    else{
                        self.dot.isHidden = true
                    }
                }
            }
        }
    }
}
