//
//  User.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/8/1.
//  Copyright (c) 2014年 ifLab. All rights reserved.
//

import Foundation
import CoreData

class User: NSManagedObject {
    
    enum Gender: Int {
        case Male = 1
        case Female = 2
        case Secret = 3
    }
    
    @NSManaged var gender: NSNumber?
    @NSManaged var birthday: NSNumber?
    @NSManaged var jobID: NSNumber?
    @NSManaged var signature: String?
    @NSManaged var agreementCount: NSNumber?
    @NSManaged var answerFavoriteCount: NSNumber?
    @NSManaged var answerCount: NSNumber?
    @NSManaged var avatarURL: String?
    @NSManaged var followerCount: NSNumber?
    @NSManaged var followingCount: NSNumber?
    @NSManaged var id: NSNumber
    @NSManaged var markCount: NSNumber?
    @NSManaged var name: String?
    @NSManaged var questionCount: NSNumber?
    @NSManaged var thankCount: NSNumber?
    @NSManaged var topicFocusCount: NSNumber?
    
    var followed: Bool? = nil
    var avatar: UIImage? = nil
    
    class func clearCookies() {
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in storage.cookies as [NSHTTPCookie] {
            storage.deleteCookie(cookie)
        }
        NSUserDefaults.standardUserDefaults().removeObjectForKey("Cookies")
        NSUserDefaults.standardUserDefaults().synchronize()
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }
    
    class func fetchUserByID(ID: NSNumber, strategy: Model.Strategy, success: ((User) -> Void)?, failure: ((NSError) -> Void)?) {
        switch strategy {
        case .CacheOnly:
            fetchUserUsingCacheByID(ID, success: success, failure: failure)
            break
        case .NetworkOnly:
            fetchUserUsingNetworkByID(ID, success: success, failure: failure)
            break
        case .CacheFirst:
            fetchUserUsingCacheByID(ID, success: success, failure: {
                error in
                self.fetchUserUsingNetworkByID(ID, success: success, failure: failure)
            })
            break
        case .NetworkFirst:
            fetchUserUsingNetworkByID(ID, success: success, failure: {
                error in
                self.fetchUserUsingCacheByID(ID, success: success, failure: failure)
            })
            break
        default:
            break
        }
    }
    
    private class func fetchUserUsingCacheByID(ID: NSNumber, success: ((User) -> Void)?, failure: ((NSError) -> Void)?) {
        Model.fetchManagedObjectByTemplateName("User_By_ID", ID: ID, success: success, failure: failure)
    }
    
    private class func fetchUserUsingNetworkByID(ID: NSNumber, success: ((User) -> Void)?, failure: ((NSError) -> Void)?) {
        Model.GET("User Extra Information",
            parameters: [
                "uid": ID
            ],
            success: {
                data in
                let user = Model.autoGenerateManagedObjectByEntityName("User", ID: ID) as User
                user.id = ID
                user.name = data["user_name"] as? String
                user.avatarURL = User.avatarURLWithURI(data["avatar_file"] as String)
                user.followerCount = (data["fans_count"] as NSString).integerValue
                user.followingCount = (data["friend_count"] as NSString).integerValue
                user.questionCount = (data["question_count"] as NSString).integerValue
                user.answerCount = (data["answer_count"] as NSString).integerValue
                user.topicFocusCount = (data["topic_focus_count"] as NSString).integerValue
                user.agreementCount = (data["agree_count"] as NSString).integerValue
                user.thankCount = (data["thanks_count"] as NSString).integerValue
                user.answerFavoriteCount = (data["answer_favorite_count"] as NSString).integerValue
                user.followed = (data["has_focus"] as NSNumber == 1)
                success?(user)
            }, failure: failure)
    }
    
    class func fetchFollowingListByUserID(ID: NSNumber, strategy: Model.Strategy, page: Int, count: Int, success: (([User]) -> Void)?, failure: ((NSError) -> Void)?) {
        switch strategy {
        case .CacheOnly:
            fetchFollowingListUsingCacheByUserID(ID, page: page, count: count, success: success, failure: failure)
            break
        case .NetworkOnly:
            fetchFollowingListUsingNetworkByUserID(ID, page: page, count: count, success: success, failure: failure)
            break
        case .CacheFirst:
            fetchFollowingListUsingCacheByUserID(ID, page: page, count: count, success: success, failure: {
                error in
                self.fetchFollowingListUsingNetworkByUserID(ID, page: page, count: count, success: success, failure: failure)
            })
            break
        case .NetworkFirst:
            fetchFollowingListUsingNetworkByUserID(ID, page: page, count: count, success: success, failure: {
                error in
                self.fetchFollowingListUsingCacheByUserID(ID, page: page, count: count, success: success, failure: failure)
            })
            break
        }
    }
    
    private class func fetchFollowingListUsingNetworkByUserID(ID: NSNumber, page: Int, count: Int, success: (([User]) -> Void)?, failure: ((NSError) -> Void)?) {
        Model.GET("User Following List",
            parameters: [
                "uid": ID,
                "page": page,
                "per_page": count
            ],
            success: {
                data in
                if (data["total_rows"] as NSString).integerValue > 0 {
                    var users = [User]()
                    let a = ID
                    for value in data["rows"] as [NSDictionary] {
                        let b = (value["uid"] as NSString).integerValue
                        User_User.updateRelationship(a: a, b: b)
                        let user = Model.autoGenerateManagedObjectByEntityName("User", ID: b) as User
                        user.name = value["user_name"] as? String
                        user.avatarURL = User.avatarURLWithURI(value["avatar_file"] as String)
                        user.signature = value["signature"] as? String
                        users.append(user)
                    }
                    success?(users)
                } else {
                    failure?(NSError()) // Needs specification
                }
            },
            failure: failure)
    }
    
    private class func fetchFollowingListUsingCacheByUserID(ID: NSNumber, page: Int, count: Int, success: (([User]) -> Void)?, failure: ((NSError) -> Void)?) {
        User_User.fetchRelationshipsUsingCacheByUserAID(ID,
            page: page,
            count: count,
            success: {
                user_users in
                var users = [User]()
                for user_user in user_users as [User_User] {
                    User.fetchUserByID(user_user.b,
                        strategy: .CacheOnly,
                        success: {
                            user in
                            users.append(user)
                        },
                        failure: failure)
                }
                success?(users)
            },
            failure: failure)
    }
    
    class func fetchFollowerListByUserID(ID: NSNumber, strategy: Model.Strategy, page: Int, count: Int, success: (([User]) -> Void)?, failure: ((NSError) -> Void)?) {
        switch strategy {
        case .CacheOnly:
            fetchFollowerListUsingCacheByUserID(ID, page: page, count: count, success: success, failure: failure)
            break
        case .NetworkOnly:
            fetchFollowerListUsingNetworkByUserID(ID, page: page, count: count, success: success, failure: failure)
            break
        case .CacheFirst:
            fetchFollowerListUsingCacheByUserID(ID, page: page, count: count, success: success, failure: {
                error in
                self.fetchFollowerListUsingNetworkByUserID(ID, page: page, count: count, success: success, failure: failure)
            })
            break
        case .NetworkFirst:
            fetchFollowerListUsingNetworkByUserID(ID, page: page, count: count, success: success, failure: {
                error in
                self.fetchFollowerListUsingCacheByUserID(ID, page: page, count: count, success: success, failure: failure)
            })
            break
        }
    }
    
    private class func fetchFollowerListUsingNetworkByUserID(ID: NSNumber, page: Int, count: Int, success: (([User]) -> Void)?, failure: ((NSError) -> Void)?) {
        Model.GET("User Follower List",
            parameters: [
                "uid": ID,
                "page": page,
                "per_page": count
            ],
            success: {
                data in
                if (data["total_rows"] as NSString).integerValue > 0 {
                    var users = [User]()
                    let b = ID
                    for value in data["rows"] as [NSDictionary] {
                        let a = (value["uid"] as NSString).integerValue
                        User_User.updateRelationship(a: a, b: b)
                        let user = Model.autoGenerateManagedObjectByEntityName("User", ID: a) as User
                        user.name = value["user_name"] as? String
                        user.avatarURL = User.avatarURLWithURI(value["avatar_file"] as String)
                        user.signature = value["signature"] as? String
                        users.append(user)
                    }
                    success?(users)
                } else {
                    failure?(NSError()) // Needs specification
                }
            },
            failure: failure)
    }
    
    private class func fetchFollowerListUsingCacheByUserID(ID: NSNumber, page: Int, count: Int, success: (([User]) -> Void)?, failure: ((NSError) -> Void)?) {
        User_User.fetchRelationshipsUsingCacheByUserBID(ID,
            page: page,
            count: count,
            success: {
                user_users in
                var users = [User]()
                for user_user in user_users as [User_User] {
                    User.fetchUserByID(user_user.a,
                        strategy: .CacheOnly,
                        success: {
                            user in
                            users.append(user)
                        },
                        failure: failure)
                }
                success?(users)
            },
            failure: failure)
    }
    
    class func loginWithCookieAndCacheInStorage(#success: ((User) -> Void)?, failure: ((NSError) -> Void)?) {
            let data = NSUserDefaults.standardUserDefaults().objectForKey("Cookies") as? NSData
            if data == nil {
                failure?(NSError()) // Needs specification
            } else {
                let cookies = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as [NSHTTPCookie]
                let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
                for cookie in cookies {
                    storage.setCookie(cookie)
                }
                Model.GET("User UID",
                    parameters: nil,
                    success: {
                        data in
                        self.fetchUserByID(
                            data["uid"] as NSNumber,
                            strategy: .CacheFirst,
                            success: success,
                            failure: failure)
                    }, failure: failure)
            }
    }
    
    class func loginWithName(name: String, password: String, success: ((User) -> Void)?, failure: ((NSError) -> Void)?) {
        clearCookies()
        Model.POST("User Login",
            parameters: [
                "user_name": name.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!,
                "password": password.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            ],
            success: {
                data in
                let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies as [NSHTTPCookie]
                let data = NSKeyedArchiver.archivedDataWithRootObject(cookies)
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(data, forKey: "Cookies")
                defaults.synchronize()
                self.loginWithCookieAndCacheInStorage(success: success, failure: failure)
            },
            failure: failure)
    }
    
    // Needs to be modified
    func fetchProfileUsingNetwork(#success: (() -> Void)?, failure: ((NSError) -> Void)?) {
        Model.GET("User Basic Information",
            parameters: [
                "uid": id
            ],
            success: {
                data in
                let value = data[0] as NSDictionary
                self.name = value["user_name"] as? String
                self.gender = value["sex"] is NSNull ? Gender.Secret.toRaw() : (value["sex"] as NSString).integerValue
                self.birthday = value["birthday"] is NSNull ? nil : (value["birthday"] as NSString).integerValue
                self.jobID = (value["job_id"] as NSString).integerValue
                self.signature = value["signature"] as? String
                success?()
            },
            failure: failure)
    }
    
    func toggleFollow(#success: (() -> Void)?, failure: ((NSError) -> Void)?) {
        Model.GET("Follow User",
            parameters: [
                "uid": id
            ],
            success: {
                data in
                self.followed = (data["type"] as? String == "add")
                success?()
            },
            failure: failure)
    }
    
    private let imageView = UIImageView()
    
    func fetchAvatarImage(#success: (() -> Void)?, failure: ((NSError) -> Void)?) {
        if avatarURL != nil {
            imageView.setImageWithURLRequest(NSURLRequest(URL: NSURL(string: avatarURL!)),
                placeholderImage: nil,
                success: {
                    request, response, image in
                    self.avatar = image
                    success?()
                    return
                },
                failure: {
                    request, response, error in
                    failure?(error)
                    return
                })
        } else {
            failure?(NSError()) // Needs specification
        }
    }
    
    class func avatarURLWithURI(URI: String) -> String {
        return Model.website + Model.paths["User Avatar"]! + URI
    }
    
}
