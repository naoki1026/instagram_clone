//
//  User.swift
//  instagramClone
//
//  Created by Naoki Arakawa on 2019/03/27.
//  Copyright © 2019 Naoki Arakawa. All rights reserved.
//

import Firebase

class User {
  
  //attributes
  //データベース上に保有しているユーザー情報である
  //辞書型で保有している
  var username : String!
  var name : String!
  var profileImageUrl : String!
  var uid : String!
  var isFollowed = false
  
  
  init(uid: String, dictionary: Dictionary<String, AnyObject>) {
    
    self.uid = uid
    
    //"username"は辞書型におけるキー値である
    if let username = dictionary["username"] as? String {
      self.username = username
      
    }
    
    if let name = dictionary["name"] as? String {
      self.name = name
      
    }
    
    if let profileImageUrl = dictionary["profileImageUrl"] as? String {
      self.profileImageUrl = profileImageUrl
      
    }
  }
  
  func follow() {
    guard let currentUid = Auth.auth().currentUser?.uid else { return }
    
    // UPDATE: - get uid like this to work with update
    guard let uid = uid else { return }
    
    // set is followed to true
    //フォローされていたらtrueを返す
    self.isFollowed = true
    
    // add followed user to current user-following structure
    //フォローした人を自分のアカウント情報に追加
    USER_FOLLOWING_REF.child(currentUid).updateChildValues([uid: 1])
    
    // add current user to followed user-follower structure
    //フォローされた人にフォローワーが追加
    USER_FOLLOWER_REF.child(uid).updateChildValues([currentUid: 1])
    
    //upload follow notification to server
    uploadNotificationToServer()
    
    // upload follow notification to server
//    uploadFollowNotificationToServer()
    
    // add followed users posts to current user-feed
    //フォローしたらメイン画面の画像表示に追加される
    USER_POSTS_REF.child(uid  ).observe(.childAdded) { (snapshot) in
      let postId = snapshot.key
      USER_FEED_REF.child(currentUid).updateChildValues([postId: 1])
      
    }
  }
  
  func unfollow() {
    guard let currentUid = Auth.auth().currentUser?.uid else { return }
    
    // UPDATE: - get uid like this to work with update
    guard let uid = uid else { return }
    
    self.isFollowed = false
    
    USER_FOLLOWING_REF.child(currentUid).child(uid).removeValue()
    
    USER_FOLLOWER_REF.child(uid).child(currentUid).removeValue()
    
    //フォローしなくなったら画像の表示をやめる
    USER_POSTS_REF.child(uid).observe(.childAdded) { (snapshot) in
      let postId = snapshot.key
      USER_FEED_REF.child(currentUid).child(postId).removeValue()
      
    }
  }

  func checkIfUserIsFollowed(completion: @escaping(Bool) -> ()) {
    
    guard let currentUid = Auth.auth().currentUser?.uid else { return }
    
    USER_FOLLOWING_REF.child(currentUid).observeSingleEvent(of: .value) { (snapshot) in
      
      if snapshot.hasChild(self.uid) {
        
        self.isFollowed = true
        completion(true)
        
      } else {
        
        self.isFollowed = false
        completion(false)
        
      }
    }
  }
  
  func uploadNotificationToServer(){
    
    guard let currentUid = Auth.auth().currentUser?.uid else {return}
    let creationDate = Int(NSDate().timeIntervalSince1970)
    
    //notification values
    let values = ["checked" : 0,
                  "creationDate" : creationDate,
                  "uid" : currentUid,
                  "type" : FOLLOW_INT_VALUE
                  ] as [String : Any]
    
    NOTIFICATIONS_REF.child(self.uid).childByAutoId().updateChildValues(values)
    
  }
}
  
//  func uploadFollowNotificationToServer() {
//
//    guard let currentUid = Auth.auth().currentUser?.uid else { return }
//    let creationDate = Int(NSDate().timeIntervalSince1970)
//
//    // notification values
//    let values = ["checked": 0,
//                  "creationDate": creationDate,
//                  "uid": currentUid,
//                  "type": FOLLOW_INT_VALUE] as [String : Any]
//
//
//    NOTIFICATIONS_REF.child(self.uid).childByAutoId().updateChildValues(values)
//  }
