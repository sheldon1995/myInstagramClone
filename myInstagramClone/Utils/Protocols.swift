//
//  Protocols.swift
//  InstgramClone
//
//  Created by Sheldon on 1/10/20.
//  Copyright © 2020 wentao. All rights reserved.
//


/*
 What is protocol?
 
 */

protocol UserProfileHeaderDelegate {
    func handleEditFollowTapped(for header: UserProfileHeader)
    func setUserStats(for header: UserProfileHeader)
    func handleFollowingsTapped(for header: UserProfileHeader)
    func handleFollowersTapped(for header: UserProfileHeader)
}

protocol FollowCellDelegate {
    func handleFollowTapped(for cell:FollowLikeCell)
}

protocol FeedCellDelegate {
    func handleUserNameButtonTapped(for cell:FeedCell)
    func handleOptionsTapped(for cell:FeedCell)
    func handleLikeTapped(for cell:FeedCell, isDoubleTapped:Bool)
    func handleCommentTapped(for cell:FeedCell)
    func handleCongifureLikeButton(for cell:FeedCell)
    func handleShowLikes(for cell:FeedCell)
}
protocol NotificationDelegte {
    func handleFollowTapped(for cell:NotificationCell)
    func handlePostTapped(for cell:NotificationCell)
}
protocol Printable {
    var description: String{get}
}

protocol CommentInputAccesoryViewDelegate {
    func didSubmit(forComment comment: String)
}

