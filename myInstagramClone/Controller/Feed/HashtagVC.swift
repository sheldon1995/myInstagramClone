//
//  HashtagVC.swift
//  InstgramClone
//
//  Created by Sheldon on 1/23/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
private let reuseIdentifier = "hashtagCell"

class HashtagVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    // MARK: Properties
    
    var posts = [Post]()
    var hashtag : String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        
        // Register cell.
        self.collectionView!.register(HashtagCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Fetch post according to the hashtag
        fetchHashtagPosts()
        
        // Configure navigation bar's title
        configureNavigationBar()
        
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! HashtagCell
        cell.post = posts[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    
    // Did select row for collection view
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let feedVC = FeedVC(collectionViewLayout: UICollectionViewFlowLayout())
        // Just view one post.
        feedVC.viewSinglePost = true
        
        // View this one
        feedVC.post = posts[indexPath.row]
        
        // Push new controller
        navigationController?.pushViewController(feedVC, animated: true)
    }
    
    // MARK: API
    func configureNavigationBar(){
        guard let title = self.hashtag else {return}
        navigationItem.title = title
    }
    
    func fetchHashtagPosts(){
        guard let hashtag = self.hashtag else {return}
        // Need to be lower cased. Need to use observe not ovbserveSingleEvent.
        HASHTAG_POST_REF.child(hashtag.lowercased()).observe(.childAdded) { (snapshot) in
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
    }
}
