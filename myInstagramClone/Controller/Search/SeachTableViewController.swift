//
//  SeachTableViewController.swift
//  InstgramClone
//
//  Created by Sheldon on 1/8/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
/*
 Table view is used to search
 
 Collection view is used to show all posts.
 
 */
private let reuseIdentifier = "SearchUserCell"
class SeachTableViewController: UITableViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    // Set user array.
    var users = [User]()
    var filterUsers = [User]()
    var posts = [Post]()
    var searchBar = UISearchBar()
    var inSearchMode = false
    var collectionView: UICollectionView!
    var collectionViewEnabled = true
    var currentKey :String?
    var userCurrentKey: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell classes
        tableView.register(SearchUserCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        
        // Separator insets for search by username.
        // 64 = left padding space + width + 8 = 8 + 48 + 8 + 64
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 64, bottom: 0, right: 0)
        
        
        // Congigure search bar
        configureSearchBar()
        
        // Configure collection view
        configureCollectionView()
        
        // Configure refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
        
        
        // Fetch all post at collection view
        fetchPosts()
        
    }
    
    
    // MARK: - Table view data source
    // Return the number of sections in the table view.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // The numbeor of cell
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If in the search mode, show the results in the filterUsers array.
        if inSearchMode{
            return filterUsers.count
        }
        return users.count
    }
    
    // Each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,for: indexPath) as! SearchUserCell
        
        var user :User!
        if inSearchMode{
            user = self.filterUsers[indexPath.row]
        }
        else
        {
            user = self.users[indexPath.row]
        }
        
        // indexPath.row increase from 0 to ...
        cell.user = user
        
        return cell
    }
    
    // When click one table view cell..., navigate from search view to profile view.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var user :User!
        if inSearchMode{
            user = self.filterUsers[indexPath.row]
        }
        else
        {
            user = self.users[indexPath.row]
        }
        
        // Create instance of user profile vc
        let userProfileVC = ProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
        
        // Pass each user from searchVC to profileVC
        userProfileVC.user = user
        
        // Push new controller
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    // Hight for row
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if users.count > 3{
            if indexPath.row == users.count - 1{
                fetchUsersData()
            }
        }
    }
    // MARK: CollectionView
    
    // This function is called whenever a cell is gonna be displayed.
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if posts.count > 20{
            if indexPath.row == posts.count-1{
                // Call fetch posts again.
                fetchPosts()
            }
        }
    }
    
    func configureCollectionView(){
        let layout = UICollectionViewFlowLayout()
        // Vertical scroll screen.
        layout.scrollDirection = .vertical
        
        // Minus tabBar and navigation bar.
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - (tabBarController?.tabBar.frame.height)! - (navigationController?.navigationBar.frame.height)!)
        
        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white
        collectionView.register(SearchPostCell.self, forCellWithReuseIdentifier: "SearchPostCell")
        
        tableView.addSubview(collectionView)
        tableView.separatorColor = .clear
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Note (view.frame.width)- 2 / 3 is wrong.
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    // Return cell object
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchPostCell", for: indexPath) as! SearchPostCell
        cell.post = posts[indexPath.row]
        return cell
    }
    
    // Did select row for collection view
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let feedVC = FeedVC(collectionViewLayout: UICollectionViewFlowLayout())
        // Just view one post.
        feedVC.viewSinglePost = true
        
        // Set search vc
        feedVC.searhTableController = self
        
        // View this one
        feedVC.post = posts[indexPath.row]
        
        // Push new controller
        navigationController?.pushViewController(feedVC, animated: true)
    }
    
    // MARK: Functions
    // Fetch all users' data
    func fetchUsersData(){
        if userCurrentKey == nil{
            USER_REF.queryLimited(toLast: 4).observeSingleEvent(of: .value) { (snapshot) in
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                // Grab these 4 users and append to user array.
                allObjects.forEach { (snapshot) in
                    let userId = snapshot.key
                    Database.fetchUser(with: userId) { (user) in
                        self.users.append(user)
                        // This reloadData() must be included in this range.
                        self.tableView?.reloadData()
                    }
                }
                // Record the last visited one.
                self.userCurrentKey = first.key
            }
        }
        else {
            USER_REF.queryOrderedByKey().queryEnding(atValue: self.userCurrentKey).queryLimited(toLast: 5).observeSingleEvent(of: .value) { (snapshot) in
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                allObjects.forEach { (snapshot) in
                    let userId = snapshot.key
                    if userId != self.userCurrentKey{
                        Database.fetchUser(with: userId) { (user) in
                            self.users.append(user)
                            // This reloadData() must be included in this range.
                            self.tableView?.reloadData()
                        }
                        
                    }
                }
                // Record the last visited one.
                self.userCurrentKey = first.key
                
            }
        }
    }
    
    // Get all posts using pagination.
    func fetchPosts(){
        
        // We only load 5 last post at once.
        if currentKey == nil{
            // Scroll down to next page and this fetch post will be called again.
            POST_REF.queryLimited(toLast: 21).observeSingleEvent(of: .value) { (snapshot) in
                // Stop refreshing
                self.tableView.refreshControl?.endRefreshing()
                
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                // Grab these 5 post and append to posts array.
                allObjects.forEach { (snapshot) in
                    let postId = snapshot.key
                    Database.fetchPost(with: postId) { (post) in
                        self.posts.append(post)
                        
                        // Always show the newest post first.
                        self.posts.sort { (post1, post2) -> Bool in
                            return post1.creationDate>post2.creationDate
                        }
                        // This reloadData() must be included in this range.
                        self.collectionView?.reloadData()
                    }
                }
                // Record the last visited one.
                self.currentKey = first.key
            }
        }
        else{
            // Once user scroll down to the bottom.
            // queryOrderedByKey: is used to generate a reference to a view of the data that's been sorted by child key.
            // The upper bound (currentKey) is inclusive
            POST_REF.queryOrderedByKey().queryEnding(atValue: self.currentKey).queryLimited(toLast: 12).observeSingleEvent(of: .value) { (snapshot) in
                // we don't want the duplicated one.
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                // Grab these 5 post and append to posts array.
                allObjects.forEach { (snapshot) in
                    let postId = snapshot.key
                    // we don't want the duplicated one.
                    if snapshot.key != self.currentKey {
                        Database.fetchPost(with: postId) { (post) in
                            self.posts.append(post)
                            
                            // Always show the newest post first.
                            self.posts.sort { (post1, post2) -> Bool in
                                return post1.creationDate>post2.creationDate
                            }
                            // This reloadData() must be included in this range.
                            self.collectionView?.reloadData()
                        }
                    }
                }
                self.currentKey = first.key
            }
        }
    }
    
    // Build up search bat at the top
    func configureSearchBar(){
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder = "Search user by username"
        navigationItem.titleView = searchBar
        searchBar.tintColor = .black
    }
    
    // Refresh page
    @objc func handleRefresh(){
        // Remove all contents at posts array
        posts.removeAll(keepingCapacity: false)
        
        // Set current key as nil
        currentKey = nil
        
        // Fetch post again, need to stop refreshing.
        fetchPosts()
        
        // Reload data
        collectionView.reloadData()
    }
    
    // MARK: SearchBar
    // Customize our search bar to search by username
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Fetch user data, grab each user and append to users array.
        fetchUsersData()
        
        // At the beginning of editing, show cancel button.
        searchBar.showsCancelButton = true
        // When using search bar, hidden the collection veiw.
        collectionView.isHidden = true
        collectionViewEnabled = false
        
        // Table view separator color
        tableView.separatorColor = .lightGray
    }
    
    // What happen when text did change.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Set all search text as lower cased
        let searchTest = searchText.lowercased()
        
        // If search text is empty, don't get into search mode.
        if searchText.isEmpty || searchText == " "{
            inSearchMode = false
            tableView.reloadData()
        }
        else{
            inSearchMode = true
            // Set the users array's filter and store the result into filterUsers array..
            filterUsers = users.filter({ (user) -> Bool in
                return user.userName.contains(searchTest)
            })
            tableView.reloadData()
        }
    }
    
    // What happen when cancel button get clicked.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        // Hidden cancel button
        searchBar.showsCancelButton = false
        // Clean up search content
        searchBar.text = nil
        // Restore inSearchmode to false.
        inSearchMode = false
        
        // Reshow the collection view.
        collectionView.isHidden = false
        collectionViewEnabled = true
        
        tableView.separatorColor = .clear
        // Reload the table view if we click the search bar again.
        tableView.reloadData()
    }
}
