//
//  GroupViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 1.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework
import SwipeCellKit
import FirebaseAuth

class GroupListViewController: SwipeTableViewController, UITextFieldDelegate {
        
    var fieldsController: FieldsController?
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .singleLine
        
        title = NSLocalizedString("Groups", comment: "")

        tableView.backgroundView = UIImageView(image: UIImage(named: K.imagesFromXCAssets.picture7))
        tableView.backgroundView?.alpha = 0.3
        loadGroups()
    }
   
    //MARK: - editActionsForRowAt
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        if fieldsController!.groups![indexPath.row].title == NSLocalizedString("Groupless Group", comment: "") {
            return nil
        }
        let deleteAction = SwipeAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")){ action, indexPath in
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Delete group  %@ ", comment: ""), self.fieldsController!.groups![indexPath.row].title), message: K.deleteGroupWithAllFields, preferredStyle: .alert)
            
            let deleteWithFields = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { (action) in
                
                if let groupForDeletion = self.fieldsController!.groups?[indexPath.row] {
                    for field in groupForDeletion.fields {
                        self.fieldsController?.selectedField = field
                        self.fieldsController?.deleteFieldFromCloud(field: self.fieldsController!.selectedField)
                        self.fieldsController?.deleteFieldFromDB(field: self.fieldsController!.selectedField)
                    }
                    self.fieldsController!.deleteGroupFromCloud(group: groupForDeletion)
                    self.fieldsController!.deleteGroupFromDB(group: groupForDeletion)
                }
                self.tableView.reloadData()
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in }
            
            alert.addAction(deleteWithFields)
            //alert.addAction(deleteGroupItems)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }

        // customize the action appearance
        deleteAction.image = UIImage(systemName: K.systemImages.trashFill)
  
        let changeTitle = SwipeAction(style: .default, title: NSLocalizedString("Title", comment: "")) { action, indexPath in
            var textField = UITextField()
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Change %@'s Title", comment: ""), self.fieldsController!.groups![indexPath.row].title), message: "", preferredStyle: .alert)
           
            let action = UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: .default) { [self] (action) in
                
                if let text = textField.text {
                    let oldGroup = fieldsController!.groups![indexPath.row]
                    if let group = self.fieldsController!.groups!.first(where: {$0.title == text}) {
                        for field in self.fieldsController!.groups![indexPath.row].fields {
                            if let polygon = self.fieldsController!.polygons.first(where: {$0.title == field.id}) {
                                fieldsController!.changeFieldGroup(field: field, oldGroup: oldGroup, newGroup: group, polygon: polygon)
                            }
                            fieldsController!.changeFieldGroupAtCloud(field: field, newGroup: group)
                            //fieldsController!.setColor(color: group.color, field: field)
                        }
                        fieldsController!.deleteGroupFromCloud(group: oldGroup)
                        fieldsController!.deleteGroupFromDB(group: oldGroup)
                    } else {
                        if text.count != 0 {
                            fieldsController!.changeGroupTitle(group: oldGroup, title: text)
                            fieldsController!.changeGroupTitleAtCloud(group: oldGroup, title: text)
                        }
                    }
                }
                tableView.reloadData()
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            }
            
            alert.addTextField { (alertTextField) in
                alertTextField.placeholder = NSLocalizedString("New Title", comment: "")
                textField = alertTextField
                alertTextField.delegate = self
            }
            
            alert.addAction(action)
            alert.addAction(cancelAction)
           
            self.present(alert, animated: true, completion: nil)
        }

        // customize the action appearance
        changeTitle.image = UIImage(systemName: K.systemImages.rectangleAndPencilAndEllipsisrtl)
        changeTitle.backgroundColor = UIColor.flatYellow()

      
        return [deleteAction, changeTitle]
    }
    
    // Use this if you have a UITextField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = textField.text ?? ""

        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }

        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        if updatedText.count >= 20 {
            textField.layer.borderWidth = 0.50
            textField.layer.borderColor = UIColor.flatRed().cgColor
        } else {
            textField.layer.borderWidth = 0
        }

        // make sure the result is under 16 characters
        return updatedText.count <= 20
    }
    
    override func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        return options
    }
    
    
    //MARK: - TableView DataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fieldsController!.groups?.count ?? 1
       }

    /*override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! SwipeTableViewCell
        cell.delegate = self
        return cell
    }*/
    
    // Provide a cell object for each row.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
          
        if let group = fieldsController!.groups?[indexPath.row]{
        
        //cell.textLabel!.text = group.title
        
        guard let groupColor =  UIColor(hexString: group.color) else {fatalError()}
            
        //cell.backgroundColor = groupColor
        
        if group.fields.count == 0 || group.fields.count == 1{
            cell.detailTextLabel?.text = String(format: NSLocalizedString("%ld Field", comment: ""), group.fields.count)
        } else {
            cell.detailTextLabel?.text = String(format: NSLocalizedString("%ld Fields", comment: ""), group.fields.count)
        }
        //cell.textLabel?.textColor = ContrastColorOf(groupColor, returnFlat: true)
        
        //cell.detailTextLabel?.textColor = ContrastColorOf(cell.backgroundColor!, returnFlat: true)
        
        let label = UILabel()
        label.text = group.title
        label.textAlignment = .center
        
        label.textColor = ContrastColorOf(groupColor, returnFlat: true)
        label.backgroundColor = groupColor
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        label.heightAnchor.constraint(equalTo: cell.heightAnchor, constant: 0).isActive = true
        label.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 0.4).isActive = true
        //label.centerXAnchor.constraint(equalTo: cell.centerXAnchor, constant: 0).isActive = true
        label.leftAnchor.constraint(equalTo: cell.leftAnchor, constant: 0).isActive = true
        
        cell.backgroundColor = UIColor.clear
    }
        return cell
    }
    //MARK: - loadGroups
    func loadGroups() {
        
        //fieldsController!.groups = realm.objects(Group.self)
        
        self.tableView.reloadData()
    }
    //MARK: - Table Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: K.segueIdentifiers.goToItems, sender: self)
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.segueIdentifiers.goToItems {
            let destinationVC = segue.destination as! ToDoListViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.selectedGroup = fieldsController!.groups?[indexPath.row]
            }
        }
    }
    
}

