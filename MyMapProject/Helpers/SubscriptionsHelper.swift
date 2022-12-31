//
//  SubscriptionsHelper.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 20.03.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import Foundation
import Purchases
import RealmSwift
import Firebase

class SubscriptionsHelper {
    static var app: SubscriptionsHelper = {
        SubscriptionsHelper()
    }()
    
    private let realm: Realm! = try? Realm()
    
    private var userDefaults: Results<UserDefaults>?
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let user = Auth.auth().currentUser
    
    init() {
        // Get userDefaults in the realm
        userDefaults = realm.objects(UserDefaults.self)
    }
    
    // MARK: - checkUserSubscription
    @objc func checkUserSubscription() {
        Purchases.shared.purchaserInfo { [self] (purchaserInfo, error) in
            
            if let purchaserInfo = purchaserInfo {
                if purchaserInfo.entitlements.active.isEmpty {
                    if userDefaults?.first?.accountType == K.Invites.AccountTypes.proAccount {
                        // print("user need to be deActive member or active member.")
                        
                        let nc = NotificationCenter.default
                        nc.post(name: Notification.Name("deleteDB"), object: nil)
                        
                        // Sign out the user
                        let firebaseAuth = Auth.auth()
                        do {
                            try firebaseAuth.signOut()
                        } catch let signOutError as NSError {
                          print("Error signing out: %@", signOutError)
                        }
                        
                        do {
                            try realm.write({
                                userDefaults?.first?.accountType = K.Invites.AccountTypes.freeAccount
                            })
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                } else {
                    
                    if userDefaults?.first?.accountType == K.Invites.AccountTypes.freeAccount {
                        
                        if purchaserInfo.entitlements[K.Entitlements.professional]?.isActive == true {
                            // print("user need to be professional member")
                            do {
                                try realm.write({
                                    userDefaults?.first?.accountType = K.Invites.AccountTypes.proAccount
                                })
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        
                        // save all overlays to the firebase 
                        
                    }
                }
            }
            
        }
    }
}
