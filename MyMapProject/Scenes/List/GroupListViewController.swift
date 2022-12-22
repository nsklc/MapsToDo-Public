//
//  GroupViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 1.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import ChameleonFramework
import SwipeCellKit

class GroupListViewController: SwipeTableViewController, UITextFieldDelegate {
        
    var fieldsController: FieldsController?
    
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
        
        guard fieldsController!.groups![indexPath.row].title == NSLocalizedString("Groupless Group", comment: ""),
              let fieldsController = self.fieldsController,
              let groups = fieldsController.groups else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")){ action, indexPath in
            
            AlertsHelper.deleteAlert(on: self,
                                     with: .group,
                                     overlayTitle: groups[indexPath.row].title) { [weak self] in
                guard let self = self,
                      let fieldsController = self.fieldsController,
                      let groups = fieldsController.groups else { return }
                
                let groupForDeletion = groups[indexPath.row]
                for field in groupForDeletion.fields {
                    fieldsController.selectedField = field
                    fieldsController.deleteFieldFromCloud(field: fieldsController.selectedField)
                    fieldsController.deleteFieldFromDB(field: fieldsController.selectedField)
                }
                fieldsController.deleteGroupFromCloud(group: groupForDeletion)
                fieldsController.deleteGroupFromDB(group: groupForDeletion)
                
                self.tableView.reloadData()
            }
        }

        // customize the action appearance
        deleteAction.image = UIImage(systemName: K.systemImages.trashFill)
  
        let changeTitle = SwipeAction(style: .default, title: NSLocalizedString("Title", comment: "")) { action, indexPath in
            
            guard let fieldsController = self.fieldsController,
                  let groups = fieldsController.groups else { return }
            
            AlertsHelper.changeTitleAlert(on: self,
                                          title: groups[indexPath.row].title,
                                          overlayType: .group) { [weak self] newTitle in
                guard let self = self,
                      let fieldsController = self.fieldsController,
                      let groups = fieldsController.groups else { return }
                let oldGroup = groups[indexPath.row]
                if let group = groups.first(where: {$0.title == newTitle}) {
                    for field in groups[indexPath.row].fields {
                        if let polygon = fieldsController.polygons.first(where: {$0.title == field.id}) {
                            fieldsController.changeFieldGroup(field: field, oldGroup: oldGroup, newGroup: group, polygon: polygon)
                        }
                        fieldsController.changeFieldGroupAtCloud(field: field, newGroup: group)
                        //fieldsController!.setColor(color: group.color, field: field)
                    }
                    fieldsController.deleteGroupFromCloud(group: oldGroup)
                    fieldsController.deleteGroupFromDB(group: oldGroup)
                } else {
                    if newTitle.count != 0 {
                        fieldsController.changeGroupTitle(group: oldGroup, title: newTitle)
                        fieldsController.changeGroupTitleAtCloud(group: oldGroup, title: newTitle)
                    } else {
                        AlertsHelper.errorAlert(on: self,
                                                with: NSLocalizedString("Oops!", comment: ""), errorMessage: NSLocalizedString("Group needs a title.", comment: ""))
                    }
                }
                self.tableView.reloadData()
            }
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

