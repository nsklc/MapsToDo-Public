//
//  CategoryViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 10.08.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import ChameleonFramework
import SwipeCellKit
import GoogleMaps

final class FieldListViewController: SwipeTableViewController, UITextFieldDelegate {
    
    var fieldsController: FieldsController?
    var cameraPositionPath: GMSPath?
    var selectedGroup: Group?
    var isMetric: Bool?
    var groupsCollectionView:UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()

        fieldsController!.loadFieldsAndGroups()
        self.tableView.reloadData()
        
        tableView.backgroundView = UIImageView(image: UIImage(named: K.imagesFromXCAssets.picture7))
        tableView.backgroundView?.alpha = 0.3
        
    }
    
    @IBAction func filterGroupButtonTapped(_ sender: UIBarButtonItem) {
        hideFilterGroupCollection(hide: !groupsCollectionView!.isHidden)
    }
    
    func hideFilterGroupCollection(hide: Bool) {
        groupsCollectionView?.isHidden = hide
    }
    //MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        groupsCollectionView = UICollectionView(frame: CGRect(x: view.frame.width-(view.frame.width/4), y: 0, width: view.frame.width/4, height: view.frame.height/5), collectionViewLayout: layout)
        
        guard let groupsCollectionView = groupsCollectionView else {
            fatalError()
        }
        view.addSubview(groupsCollectionView)
        groupsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        groupsCollectionView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3).isActive = true
        groupsCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3).isActive = true
        groupsCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        groupsCollectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
        
        layout.itemSize = CGSize(width: groupsCollectionView.frame.width-5, height: 20)
        groupsCollectionView.collectionViewLayout = layout
        
        groupsCollectionView.dataSource = self
        groupsCollectionView.delegate = self
        groupsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        groupsCollectionView.backgroundColor = UIColor.flatWhite()

        self.view.addSubview(groupsCollectionView)
        hideFilterGroupCollection(hide: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        return options
    }

    //MARK: - editActionsForRowAt
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
//        cameraPositionForMapView[0] =  (fieldsController!.fields?[indexPath.row].polygonMarkersPositions[0].latitude)!
//        cameraPositionForMapView[1] = (fieldsController!.fields?[indexPath.row].polygonMarkersPositions[1].longitude)!
//        cameraPositionForMapView[2] = fabs((-0.008 * (fieldsController!.fields?[indexPath.row].circumference)!) + 22)
        if let polygon = self.fieldsController!.polygons.first(where: {$0.title == fieldsController!.fields![indexPath.row].id}) {
            cameraPositionPath = polygon.path
        }
        
        let deleteAction = SwipeAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [self] action, indexPath in
            // handle action by updating model with deletion
            
            deleteField(field: (fieldsController?.fields![indexPath.row])!)
            
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(systemName: K.systemImages.trashFill)
        
        let findInTheMap = SwipeAction(style: .default, title: NSLocalizedString("Location", comment: "") ) { action, indexPath in
            // handle action by updating model with go to map
            
            //_ = self.navigationController?.popViewController(animated: true)
            self.temp()
             
        }

        // customize the action appearance
        findInTheMap.image = UIImage(systemName: K.systemImages.locationFill)
        findInTheMap.backgroundColor = #colorLiteral(red: 0.03921568627, green: 0.5176470588, blue: 1, alpha: 1)
        
        let changeTitle = SwipeAction(style: .default, title: NSLocalizedString("Title", comment: "")) { action, indexPath in
            var textField = UITextField()
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Change %@'s Title", comment: ""), self.fieldsController!.fields![indexPath.row].title), message: "", preferredStyle: .alert)
           
            let action = UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: .default) { (action) in
                if let title = textField.text {
                    var isValidName = true
                    var errorMessage = NSLocalizedString("Field needs a title.", comment: "")
                    if title.count == 0 {
                        isValidName = false
                        errorMessage = NSLocalizedString("Field needs a title.", comment: "")
                    }
                    for field in self.fieldsController!.fields! {
                        if field.title == title {
                            isValidName = false
                            errorMessage = NSLocalizedString("Fields cannot have the same title.", comment: "")
                        }
                    }
                    
                    if isValidName {
                        self.fieldsController?.changeFieldTitle(field: self.fieldsController!.fields![indexPath.row], title: title)
                        self.fieldsController?.changeFieldTitleAtCloud(field: self.fieldsController!.fields![indexPath.row], title: title)
                        self.tableView.reloadData()
                    } else {
                        let alert = UIAlertController(title: errorMessage, message: "", preferredStyle: .alert)
                        
                        let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (action) in
                            //self.arrowButton.isHidden = false
                        }
                        
                        alert.addAction(editItemsAction)
                        
                        self.present(alert, animated: true, completion: nil)
                    }
                }
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
        if fieldsController!.fields![indexPath.row].color != UIColor.flatYellow().hexValue() {
            changeTitle.backgroundColor = UIColor.flatYellow()
        } else {
            changeTitle.backgroundColor = UIColor.flatBlue()
        }
        
        
        let changeGroup = SwipeAction(style: .default, title: NSLocalizedString("Group", comment: "")) { action, indexPath in
            var textField = UITextField()
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Change %@'s Group", comment: ""), self.fieldsController!.fields![indexPath.row].title), message: "", preferredStyle: .alert)
           
            let action = UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: .default) { [self] (action) in
                
                if let field = self.fieldsController!.fields!.first(where: {$0.id == fieldsController!.fields![indexPath.row].id}) {
                    
                    if let groupTitle = textField.text {
                        if let newGroup = fieldsController!.groups!.first(where: {$0.title == groupTitle}) {
                            if let polygon = self.fieldsController!.polygons.first(where: {$0.title == field.id}) {
                                fieldsController!.changeFieldGroup(field: field, oldGroup: (field.parentGroup.first)!, newGroup: newGroup, polygon: polygon)
                                fieldsController!.changeFieldGroupAtCloud(field: field, newGroup: newGroup)
                                fieldsController!.setColor(color: newGroup.color, field: field)
                                fieldsController!.saveColor(field: field, color: newGroup.color)
                            }
                        } else {
                            if groupTitle.count != 0 {
                                if let polygon = self.fieldsController!.polygons.first(where: {$0.title == field.id}) {
                                    let newGroup = Group()
                                    newGroup.title = groupTitle
                                    newGroup.color = UIColor.flatBlueDark().hexValue()
                                    fieldsController!.addNewGroup(newGroup: newGroup)
                                    fieldsController!.saveGroupToCloud(group: newGroup)
                                    fieldsController!.changeFieldGroup(field: field, oldGroup: (field.parentGroup.first)!, newGroup: newGroup, polygon: polygon)
                                    fieldsController!.changeFieldGroupAtCloud(field: field, newGroup: newGroup)
                                    fieldsController!.loadFieldsAndGroups()
                                }
                            } else {
                                
                            }
                        }
                    }
                    
                }
                
                
                tableView.reloadData()
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            }
            
            alert.addTextField { (alertTextField) in
                alertTextField.placeholder = NSLocalizedString("New Group Title", comment: "")
                textField = alertTextField
                alertTextField.delegate = self
            }
            
            alert.addAction(action)
            alert.addAction(cancelAction)
           
            self.present(alert, animated: true, completion: nil)
        }

        // customize the action appearance
        changeGroup.image = UIImage(systemName: K.systemImages.rectangleAndPencilAndEllipsisrtl)
        if fieldsController!.fields![indexPath.row].color != UIColor.flatLime().hexValue() {
            changeGroup.backgroundColor = UIColor.flatLime()
        } else {
            changeGroup.backgroundColor = UIColor.flatBlue()
        }
        
        return [deleteAction, findInTheMap, changeTitle, changeGroup]
    }
    //MARK: - deleteField
    func deleteField(field: Field) {
        fieldsController?.selectedField = field
        
        let alert = UIAlertController(title: String(format: NSLocalizedString("Delete %@", comment: ""), fieldsController!.selectedField.title), message: NSLocalizedString("Field's overlay, to-do items and photos will be deleted.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [self] (uiAlertAction) in
            
            
            fieldsController?.deleteFieldFromCloud(field: fieldsController!.selectedField)
            fieldsController?.deleteFieldFromDB(field: fieldsController!.selectedField)
            fieldsController!.loadFieldsAndGroups()
            tableView.reloadData()
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        
       
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
    
    //MARK: - temp
    func temp() {
        
        
        
        performSegue(withIdentifier: K.segueIdentifiers.backToMapView, sender: self)
    }
    //MARK: - prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.segueIdentifiers.goToItems {
            let destinationVC = segue.destination as! ToDoListViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.selectedGroup = fieldsController!.fields?[indexPath.row].parentGroup.first
                destinationVC.selectedField = fieldsController!.fields?[indexPath.row]
            }
        } else if segue.identifier == K.segueIdentifiers.backToMapView {
            
            let destinationVC = segue.destination as! MapViewController
            if let cameraPositionPath = cameraPositionPath {
                destinationVC.cameraPositionPath = cameraPositionPath
            }
            
        }
    }
    //MARK: - TableView DataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fieldsController!.fields?.count ?? 1
       }
    
       //MARK: - cellForRowAt
       override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
          
        if let field = fieldsController!.fields?[indexPath.row]{
            
                cell.textLabel!.text = field.title
               
                guard let fieldColor =  UIColor(hexString: field.color) else {fatalError()}
                
                cell.backgroundColor = UIColor.flatWhite()
                
                cell.textLabel?.textColor = ContrastColorOf(cell.backgroundColor!, returnFlat: true)
                
                let label = UILabel()
                label.text = field.parentGroup.first?.title
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                label.textColor = ContrastColorOf(fieldColor, returnFlat: true)
                label.backgroundColor = fieldColor
                label.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(label)
                label.heightAnchor.constraint(equalTo: cell.heightAnchor, constant: 0).isActive = true
                label.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 0.4).isActive = true
                //label.centerXAnchor.constraint(equalTo: cell.centerXAnchor, constant: 0).isActive = true
                label.rightAnchor.constraint(equalTo: cell.rightAnchor, constant: 0).isActive = true
            }
            cell.backgroundColor = UIColor.clear
            //cell.contentView.alpha = 0.5
            return cell
       }
    
    //MARK: - Table Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: K.segueIdentifiers.goToItems, sender: self)
    }
   
}

extension FieldListViewController: UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fieldsController?.groups!.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        
        let title = UILabel(frame: CGRect(x: 0, y: 0, width: myCell.bounds.size.width, height: myCell.bounds.size.height))
        title.adjustsFontSizeToFitWidth = true
        if indexPath.row != fieldsController?.groups!.count {
            myCell.backgroundColor = UIColor(hexString: (fieldsController?.groups![indexPath.row].color)!)
            
            title.textColor = ContrastColorOf( UIColor(hexString: (fieldsController?.groups![indexPath.row].color)!)! , returnFlat: true)
    
            title.text = fieldsController?.groups![indexPath.row].title
        } else {
            myCell.backgroundColor = UIColor.flatWhiteDark()
            
            title.textColor = UIColor.flatBlack()
            
            title.text = NSLocalizedString("All Groups", comment: "")
        }
        
        title.textAlignment = .center
        
        for subview in myCell.contentView.subviews {
            if subview is UILabel {
                subview.removeFromSuperview()
            }
        }
        myCell.contentView.addSubview(title)
        return myCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row != fieldsController?.groups!.count {
            fieldsController!.loadFields(with: (fieldsController?.groups![indexPath.row].title)!)
            self.tableView.reloadData()
        } else {
            fieldsController!.loadFieldsAndGroups()
            self.tableView.reloadData()
        }
        hideFilterGroupCollection(hide: true)
    }
}
