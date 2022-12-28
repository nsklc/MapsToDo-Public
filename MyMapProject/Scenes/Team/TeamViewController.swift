//
//  PaymentViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 20.02.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit
import ChameleonFramework
import SwipeCellKit
import Firebase
import RealmSwift

class TeamViewController: SwipeTableViewController {
    /*
    private let db = Firestore.firestore()
    private let user = Auth.auth().currentUser
    
    var teamMembers = [[String:String]]()
    //var teamMembersStates = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .singleLine
        
        title = "Team"
        
        //tableView.backgroundView = UIImageView(image: UIImage(named: K.imagesFromXCAssets.picture7))
        //tableView.backgroundView?.alpha = 0.3
        listenInvites()
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
    }
    
    //MARK: - editActionsForRowAt
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let teamMember = teamMembers[indexPath.row]
        let teamMemberMail = teamMember.first!.key
        let state = teamMember.first!.value
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { [self] action, indexPath in
            // handle action by updating model with deletion
            let ac = UIAlertController(title: "Delete Membership", message: "All shared data will be deleted \(teamMemberMail)'s device.", preferredStyle: .alert)
            
            let submitAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
               
                
                db.collection("Invites").whereField("invitedMail", isEqualTo: teamMemberMail)
                    .getDocuments() { (querySnapshot, error) in
                        guard let documents = querySnapshot?.documents else {
                            print("Error fetching documents: \(error!)")
                            return
                        }
                        if documents.count > 0 {
                            //print(documents.first?.documentID)
                            let inviteID = documents.first?.documentID
                            if let inviteID = inviteID {
                                db.collection("Invites").document(inviteID).delete()
                                teamMembers.remove(at: indexPath.row)
                            }
                        }
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default)
            ac.addAction(cancelAction)
            ac.addAction(submitAction)
            
            present(ac, animated: true)
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(systemName: K.systemImages.trashFill)
        
        let reSend = SwipeAction(style: .default, title: "Resend" ) { [self] action, indexPath in
            // handle action by updating model with go to map
            
            db.collection("Invites").whereField("invitedMail", isEqualTo: teamMemberMail)
                .getDocuments() { (querySnapshot, error) in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        return
                    }
                    if documents.count > 0 {
                        //print(documents.first?.documentID)
                        let inviteID = documents.first?.documentID
                        if let inviteID = inviteID {
                            let teamInvitesRef = db.collection("Invites").document(inviteID)
                            
                            teamInvitesRef.setData([
                                "inviteState": "Waiting for approval"], merge: true
                                )
                            teamMembers[indexPath.row].updateValue("Waiting for approval", forKey: teamMemberMail)
                            tableView.reloadData()
                        }
                    }
            }
             
        }

        // customize the action appearance
        reSend.image = UIImage(systemName: K.systemImages.locationFill)
        reSend.backgroundColor = #colorLiteral(red: 0.03921568627, green: 0.5176470588, blue: 1, alpha: 1)
        
        /*let Permissions = SwipeAction(style: .default, title: "Permissions") { [self] action, indexPath in
            selectedMemberMail = teamMemberMail
            self.performSegue(withIdentifier: K.segueIdentifiers.goToPermissionsViewController, sender: self)
        }

        // customize the action appearance
        Permissions.image = UIImage(systemName: K.systemImages.rectangleAndPencilAndEllipsisrtl)
        
        Permissions.backgroundColor = UIColor.flatLime()*/
        
        if state == "Rejected" || state == "Left" {
            return [deleteAction, reSend]
        } else {
            return [deleteAction]
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        return options
    }
    
    
    //MARK: - TableView DataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamMembers.count
    }
    
    /*override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! SwipeTableViewCell
     cell.delegate = self
     return cell
     }*/
    
    // Provide a cell object for each row.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        //var state = "Waiting for approval"
        
        
        let teamMember = teamMembers[indexPath.row]
        let teamMemberMail = teamMember.first?.key
        let state = teamMember.first?.value
        //let state = teamMembers[indexPath.row].values
        
        //cell.textLabel?.text = teamMember.title
        cell.textLabel?.text = teamMemberMail
        //status = teamMember.status
        
        let label = UILabel()
        label.text = state
        switch state {
        case "Waiting for approval":
            //cell.backgroundColor = UIColor.flatYellow()
            label.backgroundColor = UIColor.flatYellow()
        case "Active":
            //cell.backgroundColor = UIColor.flatBlue()
            label.backgroundColor = UIColor.flatGreen()
        case "Rejected":
            //cell.backgroundColor = UIColor.flatBlue()
            label.backgroundColor = UIColor.flatRed()
        case "Left":
            label.backgroundColor = UIColor.flatRed()
        default:
            cell.detailTextLabel?.text = ""
            cell.backgroundColor = UIColor.flatYellowDark()
        }
        cell.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        if let color = label.backgroundColor {
            label.textColor = ContrastColorOf(color, returnFlat: true)
        }
        
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        label.heightAnchor.constraint(equalTo: cell.heightAnchor, constant: 0).isActive = true
        label.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 0.4).isActive = true
        label.rightAnchor.constraint(equalTo: cell.rightAnchor, constant: 0).isActive = true
        //cell.textLabel?.textColor = ContrastColorOf(cell.backgroundColor!, returnFlat: true)
        //cell.detailTextLabel?.textColor = ContrastColorOf(cell.backgroundColor!, returnFlat: true)
        
        return cell
    }
    
    //MARK: - Table Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let teamMember = teamMembers[indexPath.row]
        //let state = teamMember.first?.value
        //if state == K.invites.inviteStatus.active {
            //self.performSegue(withIdentifier: K.segueIdentifiers.goToPermissionsViewController, sender: self)
        //}
        tableView.deselectRow(at: indexPath, animated: true)
    }
    //MARK: - prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
        if segue.identifier == K.segueIdentifiers.goToPermissionsViewController {
            let destinationVC = segue.destination as! PermissionsViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                let teamMember = teamMembers[indexPath.row]
                destinationVC.memberMail = teamMember.first!.key
            }
        }
        */
    }
    //MARK: - plusButtonTapped
    @IBAction func plusButtonTapped(_ sender: UIBarButtonItem) {
        
        let ac = UIAlertController(title: "Enter Email", message: "An invitation message will be sent to this email.", preferredStyle: .alert)
        ac.addTextField()
        ac.textFields![0].placeholder = "Email Address"
        ac.textFields![0].autocorrectionType = .no
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [self, unowned ac] _ in
            let email = ac.textFields![0].text
            if let user = user,let userEmail = user.email {
                let db = Firestore.firestore()
                
                db.collection("Invites").whereField("invitedMail", isEqualTo: email!)
                    .getDocuments() { (querySnapshot, error) in
                        guard let documents = querySnapshot?.documents else {
                            print("Error fetching documents: \(error!)")
                            return
                        }
                        /*
                        if documents.isEmpty {
                            let inviteID = UUID().uuidString
                            
                            let teamInvitesRef = db.collection("Invites").document(inviteID)
                            
                            teamInvitesRef.setData([
                                                    K.invites.bossID: user.uid,
                                                    K.invites.bossEmail: userEmail,
                                                    K.invites.invitedMail: email,
                                                    K.invites.inviteState: K.invites.inviteStatus.waitingForApproval,
                                                    //K.invites.userRole: K.invites.userRoles.admin ],
                                                    merge: true
                            )
                        } else {
                            for document in documents {
                                let data = document.data()
                                if let inviteState = data["inviteState"] as? String {
                                    if inviteState == K.invites.inviteStatus.left || inviteState == K.invites.inviteStatus.rejected {
                                        
                                    } else if inviteState == K.invites.inviteStatus.active {
                                        
                                    } else if inviteState == K.invites.inviteStatus.waitingForApproval {
                                        
                                    }
                                }
                            }
                        }
                        */
                    }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        
        present(ac, animated: true)
        
    }
    //MARK: - listenInvites
    func listenInvites() {
        if let user = user, let userEmail = user.email {
            
            db.collection("Invites").whereField("bossEmail", isEqualTo: userEmail)
                .addSnapshotListener { [self] querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error fetching snapshots: \(error!)")
                        return
                    }
                    snapshot.documentChanges.forEach { diff in
                        if (diff.type == .added) {
                            //print("New invite: \(diff.document.data())")
                            let data = diff.document.data()
                                if let invitedMail = data["invitedMail"] as? String, let state = data["inviteState"] as? String {
                                    teamMembers.append([invitedMail:state])
                                }
                        }
                        if (diff.type == .modified) {
                            //print("Modified invite: \(diff.document.data())")
                            let data = diff.document.data()
                                if let invitedMail = data["invitedMail"] as? String, let state = data["inviteState"] as? String {
                                    var temp = 0
                                    for index in 0...teamMembers.count-1 {
                                        if teamMembers[index].keys.first == invitedMail {
                                            temp = index
                                        }
                                    }
                                    teamMembers.remove(at: temp)
                                    teamMembers.insert([invitedMail : state], at: temp)
                                }
                        }
                        if (diff.type == .removed) {
                            //print("Removed invite: \(diff.document.data())")
                            let data = diff.document.data()
                                if let invitedMail = data["invitedMail"] as? String, let state = data["inviteState"] as? String {
                                    //teamMembers.remove(at: teamMembers.firstIndex(of: [invitedMail : state])!)
                                }
                        }
                    }
                    tableView.reloadData()
                }
        }
    }
    
    
    
    */
}
