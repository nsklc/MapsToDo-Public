//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Enes Kılıç on 10.08.2020.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework
import SwipeCellKit
import FirebaseAuth

class FieldViewController: SwipeTableViewController {
    
    //let realm = try! Realm()
    
    var fieldsController: FieldsController?
    
    var cameraPositionForMapView = [0.0, 0.0]
    
    var selectedGroup: Group? {
        didSet {
            //print(selectedGroup?.title)
        }
    }
    
    var groupsCollectionView:UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()

        fieldsController!.loadFields()
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
        guard let navBar = navigationController?.navigationBar else {
            fatalError("Navigation controller does not exist.")
        }
        
        navBar.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        
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

    //MARK: - editActionsForRowAt
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        cameraPositionForMapView[0] =  (self.fieldsController!.fields?[indexPath.row].polygonMarkersPositions[0].latitude)!
        cameraPositionForMapView[1] = (self.fieldsController!.fields?[indexPath.row].polygonMarkersPositions[1].longitude)!
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // handle action by updating model with deletion
            self.fieldsController?.selectedField = (self.fieldsController?.fields![indexPath.row])!
            self.fieldsController?.deleteSelectedFieldFromDB()
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(systemName: K.systemImages.trashFill)
        
        let findInTheMap = SwipeAction(style: .default, title: "Location") { action, indexPath in
            // handle action by updating model with go to map
            
            //_ = self.navigationController?.popViewController(animated: true)
            self.temp()
             
        }

        // customize the action appearance
        findInTheMap.image = UIImage(systemName: K.systemImages.locationFill)
        findInTheMap.backgroundColor = #colorLiteral(red: 0.03921568627, green: 0.5176470588, blue: 1, alpha: 1)
        
        let changeTitle = SwipeAction(style: .default, title: "Title") { action, indexPath in
            var textField = UITextField()
            
            let alert = UIAlertController(title: "Change \(self.fieldsController!.fields![indexPath.row].title)'s Title", message: "", preferredStyle: .alert)
           
            let action = UIAlertAction(title: "Change", style: .default) { (action) in
                if let title = textField.text {
                    var isValidName = true
                    var errorMessage = "Field needs a title."
                    if title.count == 0 {
                        isValidName = false
                        errorMessage = "Field needs a title."
                    }
                    for field in self.fieldsController!.fields! {
                        if field.title == title {
                            isValidName = false
                            errorMessage = "Fields can not has a same title."
                        }
                    }
                    
                    if isValidName {
                        self.fieldsController?.changeFieldTitle(field: self.fieldsController!.fields![indexPath.row], title: title)
                        self.tableView.reloadData()
                    } else {
                        let alert = UIAlertController(title: errorMessage, message: "", preferredStyle: .alert)
                        
                        let editItemsAction = UIAlertAction(title: "Ok", style: .cancel) { (action) in
                            //self.arrowButton.isHidden = false
                        }
                        
                        alert.addAction(editItemsAction)
                        
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            }
            
            alert.addTextField { (alertTextField) in
                alertTextField.placeholder = "New Title"
                textField = alertTextField
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
        
        
        let changeGroup = SwipeAction(style: .default, title: "Group") { action, indexPath in
            var textField = UITextField()
            
            let alert = UIAlertController(title: "Change \(self.fieldsController!.fields![indexPath.row].title)'s Group", message: "", preferredStyle: .alert)
           
            let action = UIAlertAction(title: "Change", style: .default) { [self] (action) in
                var fieldsGroup: Group? = nil
                if let groupTitle = textField.text, let groups = self.fieldsController?.groups! {
                    for group in groups {
                        if groupTitle == group.title {
                            self.fieldsController?.changeFieldGroup(field: fieldsController!.fields![indexPath.row], oldGroup: (fieldsController!.fields![indexPath.row].parentGroup.first)!, newGroup: group, polygon: (fieldsController?.polygons [indexPath.row])!)
                            
                            /*do {
                                try self.realm.write({
                                    //fieldsController!.fields![indexPath.row].color = group.color
                                    //fieldsController?.polygons [indexPath.row].fillColor = UIColor(hexString: group.color)
                                    fieldsController!.fields![indexPath.row].parentGroup.first?.fields.remove(at: (fieldsController!.fields![indexPath.row].parentGroup.first?.fields.index(of: fieldsController!.fields![indexPath.row]))!)
                                    //self.realm.add(group)
                                    group.fields.append(fieldsController!.fields![indexPath.row])
                                })
                            } catch {
                                print("Error saving context, \(error)")
                            }*/
                            fieldsGroup = group
                        }
                    }
                    if fieldsGroup == nil  {
                        if groupTitle.count != 0 {
                            let newGroup = Group()
                            newGroup.title = groupTitle
                            newGroup.color = UIColor.flatBlueDark().hexValue()
                            fieldsGroup = newGroup
                            fieldsController!.addNewGroup(newGroup: newGroup)
                            fieldsController!.changeFieldGroup(field: fieldsController!.fields![indexPath.row], oldGroup: (fieldsController!.fields![indexPath.row].parentGroup.first)!, newGroup: newGroup, polygon: fieldsController!.polygons[indexPath.row])
                            self.fieldsController!.loadFields()
                        } else {
                            for group in groups {
                                if "grouplessGroup" == group.title {
                                    fieldsGroup = group
                                }
                            }
                        }
                    }
                }
                tableView.reloadData()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            }
            
            alert.addTextField { (alertTextField) in
                alertTextField.placeholder = "New Group Title"
                textField = alertTextField
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
    
    func temp() {
        performSegue(withIdentifier: "backToMapView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToItems" {
            let destinationVC = segue.destination as! ToDoListViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.selectedGroup = fieldsController!.fields?[indexPath.row].parentGroup.first
                destinationVC.selectedField = fieldsController!.fields?[indexPath.row]
            }
        } else if segue.identifier == "backToMapView" {
            
            let destinationVC = segue.destination as! ViewController
            
            destinationVC.cameraPosition[0] = cameraPositionForMapView[0]
            destinationVC.cameraPosition[1] = cameraPositionForMapView[1]
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
                print(field.id)
                
            
                guard let fieldColor =  UIColor(hexString: field.color) else {fatalError()}
                
                cell.backgroundColor = UIColor.flatWhite()
                
                cell.textLabel?.textColor = ContrastColorOf(cell.backgroundColor!, returnFlat: true)
                
                let label = UILabel()
                label.text = field.parentGroup.first?.title
                label.textAlignment = .center
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

extension FieldViewController: UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fieldsController?.groups!.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        
        let title = UILabel(frame: CGRect(x: 0, y: 0, width: myCell.bounds.size.width, height: myCell.bounds.size.height))
        if indexPath.row != fieldsController?.groups!.count {
            myCell.backgroundColor = UIColor(hexString: (fieldsController?.groups![indexPath.row].color)!)
            
            title.textColor = ContrastColorOf( UIColor(hexString: (fieldsController?.groups![indexPath.row].color)!)! , returnFlat: true)
    
            title.text = fieldsController?.groups![indexPath.row].title
        } else {
            myCell.backgroundColor = UIColor.flatWhiteDark()
            
            title.textColor = UIColor.flatBlack()
            
            title.text = "All Groups"
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
            fieldsController!.loadFields()
            self.tableView.reloadData()
        }
        hideFilterGroupCollection(hide: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        let handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            print(auth.currentUser?.displayName)
        }
    }
    
}
