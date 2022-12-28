//
//  MembershipViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 25.02.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

class MembershipViewController: UIViewController {
    /*
    @IBOutlet weak var leaveTeamButton: UIButton!
    
    @IBOutlet weak var bossEmailLabel: UILabel!
    
    let realm: Realm! = try? Realm()
    
    private var userDefaults: Results<UserDefaults>?
    
    var fieldsController: FieldsController?
    var linesController: LinesController?
    var placesController: PlacesController?
    
    private let user = Auth.auth().currentUser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userDefaults = realm.objects(UserDefaults.self)
        
        title = "Team Membership"
        
        bossEmailLabel.text = "Admin's Email: \(userDefaults?.first?.bossEmail ?? "")"
        bossEmailLabel.adjustsFontSizeToFitWidth = true
        bossEmailLabel.textAlignment = .center
        
        bossEmailLabel.translatesAutoresizingMaskIntoConstraints = false
        bossEmailLabel.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8).isActive = true
        bossEmailLabel.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
        bossEmailLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        bossEmailLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: 0).isActive = true
        
        leaveTeamButton.translatesAutoresizingMaskIntoConstraints = false
        leaveTeamButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        leaveTeamButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
        leaveTeamButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        leaveTeamButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        leaveTeamButton.clipsToBounds = true
        leaveTeamButton.layer.cornerRadius = leaveTeamButton.bounds.height*0.3
        //leaveTeamButton.layer.borderWidth = 1
        leaveTeamButton.setTitle("Leave Team", for: .normal)
        leaveTeamButton.backgroundColor = UIColor.flatRedDark()
        leaveTeamButton.setTitleColor(UIColor.flatWhite(), for: .normal)
        leaveTeamButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
    }
    //MARK: - leaveTeamButtonTapped
    @IBAction func leaveTeamButtonTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Leave Team", message: "If you leave the team all overlays and to-do items will be deleted.", preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Leave", style: .destructive) { [self]_ in
            if let user = user, let email = user.email {
                do {
                    try realm.write({
                        userDefaults!.first!.bossID = user.uid
                        userDefaults!.first!.bossEmail = user.email ?? ""
                        userDefaults!.first!.accountType = "deActiveMember"
                    })
                } catch {
                    print("Error saving context, \(error)")
                }
                
                let db = Firestore.firestore()
                db.collection("Invites").whereField("invitedMail", isEqualTo: email).whereField("inviteState", isEqualTo: "Active")
                    .getDocuments() { (querySnapshot, error) in
                        guard let documents = querySnapshot?.documents else {
                            print("Error fetching documents: \(error!)")
                            return
                        }
                        if documents.count > 0 {
                            print(documents.first?.documentID)
                            let inviteID = documents.first?.documentID
                            let bossEmail = documents.map { $0["bossEmail"] }
                            let bossID = documents.map { $0["bossID"]! }
                            let invitedMail = documents.map { $0["invitedMail"]! }
                            print("bossEmail: \(bossEmail)")
                            print("bossID: \(bossID)")
                            print("invitedMail: \(invitedMail)")
                            
                            if let inviteID = inviteID {
                                let teamInvitesRef = db.collection("Invites").document(inviteID)
                                
                                teamInvitesRef.setData(["inviteState": "Left"], merge: true
                                )
                                deleteDB()
                            }
                        }
                    }
                navigationController?.popToRootViewController(animated: true)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    //MARK: - deleteDB
    func deleteDB() {
        placesController?.groundOverlays.forEach({ (GMSGroundOverlay) in
            GMSGroundOverlay.map = nil
        })
        linesController?.polylines.forEach({ (GMSPolyline) in
            GMSPolyline.map = nil
        })
        fieldsController?.polygons.forEach({ (GMSPolygon) in
            GMSPolygon.map = nil
        })
        placesController?.groundOverlays.removeAll()
        linesController?.polylines.removeAll()
        fieldsController?.polygons.removeAll()
        
        do {
            try realm.write({
                self.realm.delete(fieldsController!.fields!)
                self.realm.delete(fieldsController!.groups!)
                self.realm.delete(linesController!.lines!)
                self.realm.delete(placesController!.places!)
            })
        } catch {
            print("Error saving context, \(error)")
        }
    }
    */
}
