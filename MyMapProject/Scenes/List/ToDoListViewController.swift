//
//  File.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 13.09.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework
import SwipeCellKit
import Firebase
import FirebaseFirestore

class ToDoListViewController: SwipeTableViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    let addButton = UIButton.init(type: .system)
    
    var todoItems: Results<Item>?
    var groupTodoItems: Results<Item>?
    let realm = try! Realm()
    
    private var userDefaults: Results<UserDefaults>?
    
    private let db = Firestore.firestore()
    private let user = Auth.auth().currentUser
    
    enum type {
        case groupsItem
        case fieldsItem
        case linesItem
        case placesItem
    }
    var itemType = type.fieldsItem
    
    var status = [NSLocalizedString("Waiting To Run", comment: ""), NSLocalizedString("In Progress", comment: ""), NSLocalizedString("Completed", comment: ""), NSLocalizedString("Canceled", comment: "")]
    
    //MARK: - selectedGroup
    var selectedGroup: Group? {
        didSet {
            userDefaults = realm.objects(UserDefaults.self)
            
            title = String(format: NSLocalizedString("%@'s Items", comment: ""), selectedGroup!.title)
            itemType = type.groupsItem
            
            listenItemDocuments(parentID: selectedGroup!.id)
            loadItemsWithGroup()
            
            infoButton.isEnabled = false
            infoButton.image = UIImage()
        }
    }
    //MARK: - selectedField
    var selectedField: Field? {
        didSet {
            userDefaults = realm.objects(UserDefaults.self)
            title = String(format: NSLocalizedString("%@'s Items", comment: ""), selectedField!.title)
            itemType = type.fieldsItem
            
            listenItemDocuments(parentID: selectedField!.parentGroup.first!.id)
            loadItemsWithGroup()
            listenItemDocuments(parentID: selectedField!.id)
            loadItemsWithField()
            
            infoButton.isEnabled = true
            infoButton.image = UIImage(systemName: K.systemImages.infoCircleFill)
        }
    }
    //MARK: - selectedLine
    var selectedLine: Line? {
        didSet {
            userDefaults = realm.objects(UserDefaults.self)
            
            title = String(format: NSLocalizedString("%@'s Items", comment: ""), selectedLine!.title)
            itemType = type.linesItem
            
            listenItemDocuments(parentID: selectedLine!.id)
            loadItemsWithLine()
           
            infoButton.isEnabled = true
            infoButton.image = UIImage(systemName: K.systemImages.infoCircleFill)
        }
    }
    //MARK: - selectedPlace
    var selectedPlace: Place? {
        didSet {
            userDefaults = realm.objects(UserDefaults.self)
            
            title = String(format: NSLocalizedString("%@'s Items", comment: ""), selectedPlace!.title)
            itemType = type.placesItem
            
            listenItemDocuments(parentID: selectedPlace!.id)
            loadItemsWithPlace()
           
            infoButton.isEnabled = true
            infoButton.image = UIImage(systemName: K.systemImages.infoCircleFill)
        }
    }
    
    private var handle: AuthStateDidChangeListenerHandle?
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton.setImage(UIImage(systemName: K.systemImages.plus), for: .normal)
        addButton.tintColor = UIColor(hexString: K.colors.secondaryColor)
        addButton.backgroundColor = UIColor(hexString: K.colors.thirdColor)
    
        addButton.layer.borderWidth = 0.25
        addButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        //button.frame.size = CGSize(width: 250, height: 250)
        self.view.addSubview(addButton)

        //set constrains
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        addButton.contentHorizontalAlignment = .left
        addButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        addButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        
        addButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        addButton.layer.cornerRadius = 32.5
        addButton.clipsToBounds = true
        
        tableView.separatorStyle = .singleLine
        
        tableView.backgroundView = UIImageView(image: UIImage(named: K.imagesFromXCAssets.picture7))
        tableView.backgroundView?.alpha = 0.3
        
        addButton.addTarget(self, action: #selector(showAddItemAlert) ,
                           for: .touchUpInside)
        
        loadItemsWithGroup()
        if selectedField != nil {
            loadItemsWithField()
        }
        
        if let colorHex = selectedField?.color {
            
            guard let navBar = navigationController?.navigationBar else {
                fatalError("Navigation controller does not exist.")
            }
            
            if let navBarColor = UIColor(hexString: colorHex) {
                navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColor, returnFlat: true)]
            }
        }
        
    }
    //MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        NotificationCenter.default.addObserver(self, selector: #selector(addShowed), name: NSNotification.Name("addShowed"), object: nil)
    }
    //MARK: - myAction
    @objc func addShowed() {
        print("addShowed")
        AlertsHelper.adsAlert(on: self)
    }
    
    //MARK: - myAction
    @objc func showAddItemAlert() {
        
        if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
            if let itemCount = todoItems?.count {
                
                if itemCount >= K.freeAccountLimitations.todoItemLimit {
                    AlertsHelper.addingExtraToDoItemAlert(on: self)
                    return
                }
            }
        }
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: NSLocalizedString("Add New Item", comment: ""), message: "", preferredStyle: .alert)
        
        var actionTitle = ""
        
        switch itemType {
        case .groupsItem:
            actionTitle = NSLocalizedString("Add Items as Shared Group Item", comment: "")
        case .fieldsItem:
            actionTitle = NSLocalizedString("Add Field Item", comment: "")
        case .linesItem:
            actionTitle = NSLocalizedString("Add Line Item", comment: "")
        case .placesItem:
            actionTitle = NSLocalizedString("Add Place Item", comment: "")
        }
        
        let action = UIAlertAction(title: actionTitle, style: .default) { (action) in
            
            if let text = textField.text {
                if text.isEmpty {
                    let alert1 = UIAlertController(title: NSLocalizedString("Item needs a title.", comment: ""), message: "", preferredStyle: .alert)
                    let action1 = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (action) in
                        
                    }
                    alert1.addAction(action1)
                    alert1.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                    self.present(alert1, animated: true, completion: nil)
                } else {
                    do {
                        try self.realm.write({
                            let newItem = Item()
                            newItem.title = text
                            newItem.lastUpdateTime = Date()
                            
                            switch self.itemType {
                            case .groupsItem:
                                if let currentGroup = self.selectedGroup {
                                    currentGroup.items.append(newItem)
                                    newItem.parentID = currentGroup.id
                                }
                            case .fieldsItem:
                                if let currentField = self.selectedField {
                                    currentField.items.append(newItem)
                                    newItem.parentID = currentField.id
                                }
                            case .linesItem:
                                if let currentLine = self.selectedLine {
                                    currentLine.items.append(newItem)
                                    newItem.parentID = currentLine.id
                                }
                            case .placesItem:
                                if let currentPlace = self.selectedPlace {
                                    currentPlace.items.append(newItem)
                                    newItem.parentID = currentPlace.id
                                }
                            }
                            self.saveItemToCloud(item: newItem)
                        })
                        } catch {
                            print("Error saving new items, \(error)")
                        }
                    
                    self.tableView.reloadData()
                }
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = NSLocalizedString("Create new item", comment: "")
            textField = alertTextField
            alertTextField.delegate = self
        }
        
        alert.addAction(action)
        
        if itemType == type.groupsItem {
            let action1 = UIAlertAction(title: NSLocalizedString("Add Items as Individual Field Item", comment: ""), style: .default) { [self] (action) in
                if let currentGroup = self.selectedGroup {
                    for currentField in currentGroup.fields {
                        do {
                            try self.realm.write({
                                let newItem = Item()
                                newItem.title = textField.text!
                                newItem.lastUpdateTime = Date()
                                currentField.items.append(newItem)
                                saveItemToCloud(item: newItem)
                            })
                        } catch {
                            print("Error saving new items, \(error)")
                        }
                        
                    }
                }
               
                self.tableView.reloadData()
            }
            alert.addAction(action1)
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        let deleteAction = SwipeAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { action, indexPath in
           
            let alert = UIAlertController(title: NSLocalizedString("Delete Item", comment: ""), message: NSLocalizedString("Item will be deleted.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [self] (uiAlertAction) in
                
                self.deleteItem(at: indexPath)
                self.tableView.reloadData()
                
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
          
        }

        // customize the action appearance
        deleteAction.image = UIImage(named: "delete-icon")
        
        return [deleteAction]
    }

    //MARK: - numberOfRowsInSection
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch itemType {
        case .groupsItem:
            return groupTodoItems?.count ?? 1
        case .fieldsItem:
            return (groupTodoItems?.count ?? 0) + (todoItems?.count ?? 0)
        case .linesItem:
            return todoItems?.count ?? 1
        case .placesItem:
            return todoItems?.count ?? 1
        }
        
    }

    //MARK: - cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let df = DateFormatter()
        df.dateFormat = "MM.dd.YYYY"
        var statusIndex = 0
        
        switch itemType {
        case .groupsItem:
            if let item = groupTodoItems?[indexPath.row] {
                // Configure the cell’s contents.
                cell.textLabel?.text = item.title
                
                cell.detailTextLabel?.text = df.string(from: item.startDate) + " - " + df.string(from: item.endDate)
                statusIndex = item.status
            } else {
                cell.textLabel?.text = NSLocalizedString("No Items Added", comment: "")
            }
        case .fieldsItem:
            if indexPath.row < groupTodoItems!.count {
                if let item = groupTodoItems?[indexPath.row] {
                    // Configure the cell’s contents.
                    
                    cell.textLabel?.text = String(format: NSLocalizedString("%@ - Group Task", comment: ""), item.title)
                    
                    cell.detailTextLabel?.text = df.string(from: item.startDate) + " - " + df.string(from: item.endDate)
                    statusIndex = item.status
                    
                } else {
                    cell.textLabel?.text = NSLocalizedString("No Items Added", comment: "")
                }
            } else {
                if let item = todoItems?[(indexPath.row - groupTodoItems!.count)] {
                    // Configure the cell’s contents.
                    cell.textLabel?.text = item.title
                    //if let startDate =  item.startDate, let endDate = item.endDate, let itemStatus = item.status
                    
                    cell.detailTextLabel?.text = df.string(from: item.startDate) + " - " + df.string(from: item.endDate)
                    statusIndex = item.status
                
                } else {
                    cell.textLabel?.text = NSLocalizedString("No Items Added", comment: "")
                }
            }
        case .linesItem:
            if let item = todoItems?[indexPath.row] {
                // Configure the cell’s contents.
                cell.textLabel?.text = item.title
                
                cell.detailTextLabel?.text = df.string(from: item.startDate) + " - " + df.string(from: item.endDate)
                statusIndex = item.status
            } else {
                cell.textLabel?.text = NSLocalizedString("No Items Added", comment: "")
            }
        case .placesItem:
            if let item = todoItems?[indexPath.row] {
                // Configure the cell’s contents.
                cell.textLabel?.text = item.title
                
                cell.detailTextLabel?.text = df.string(from: item.startDate) + " - " + df.string(from: item.endDate)
                statusIndex = item.status
            } else {
                cell.textLabel?.text = NSLocalizedString("No Items Added", comment: "")
            }
        }
        
        //let statusArray = [NSLocalizedString("Waiting To Run", comment: ""), NSLocalizedString("In Progress", comment: ""), NSLocalizedString("Completed", comment: ""), NSLocalizedString("Canceled", comment: "")]
        
        let label = UILabel()
        label.text = String(format: NSLocalizedString("%@", comment: ""), status[statusIndex])
        
        switch statusIndex {
        case 0:
            //cell.backgroundColor = UIColor.flatYellow()
            label.backgroundColor = UIColor.flatYellow()
        case 1:
            //cell.backgroundColor = UIColor.flatBlue()
            label.backgroundColor = UIColor.flatBlue()
        case 2:
            //cell.backgroundColor = UIColor.flatGreen()
            label.backgroundColor = UIColor.flatGreen()
        case 3:
            //cell.backgroundColor = UIColor.flatRed()
            label.backgroundColor = UIColor.flatRed()
        default:
            label.isHidden = true
            cell.detailTextLabel?.text = ""
            cell.backgroundColor = UIColor.flatYellowDark()
        }
        cell.backgroundColor = UIColor.clear
        label.textAlignment = .center
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
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: K.segueIdentifiers.goToItemsForm, sender: self)
    }
    //MARK: - infoButtonTapped
    @IBAction func infoButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: K.segueIdentifiers.goToInfoViewController, sender: self)
        
    }
    //MARK: - prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.segueIdentifiers.goToItemsForm{
            let destinationVC = segue.destination as! ToDoFormViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                if itemType == type.fieldsItem || itemType == type.groupsItem {
                    if indexPath.row < groupTodoItems!.count {
                        destinationVC.selectedItem = groupTodoItems?[indexPath.row]
                    } else {
                        destinationVC.selectedItem = todoItems?[indexPath.row - groupTodoItems!.count]
                    }
                }else {
                    destinationVC.selectedItem = todoItems?[indexPath.row]
                }
                
            }
        } else if segue.identifier == K.segueIdentifiers.goToInfoViewController {
            let destinationVC = segue.destination as! InfoViewController
            switch itemType {
            case .fieldsItem:
                destinationVC.selectedField = selectedField
            case .linesItem:
                destinationVC.selectedLine = selectedLine
            case .placesItem:
                destinationVC.selectedPlace = selectedPlace
            default:
                break
            }
            
        }
    }
    
    //MARK: - Model Manupulation Methods
    
    func loadItemsWithGroup() {
        
        groupTodoItems = selectedGroup?.items.sorted(byKeyPath: "startDate",ascending: true)
        
        self.tableView.reloadData()
    }
    //MARK: - loadItemsWithField
    func loadItemsWithField() {
        
        todoItems = selectedField?.items.sorted(byKeyPath: "startDate",ascending: true)
        
        self.tableView.reloadData()
    }
    //MARK: - loadItemsWithLine
    func loadItemsWithLine() {
        
        todoItems = selectedLine?.items.sorted(byKeyPath: "startDate",ascending: true)
        
        self.tableView.reloadData()
    }
    //MARK: - loadItemsWithPlace
    func loadItemsWithPlace() {
        
        todoItems = selectedPlace?.items.sorted(byKeyPath: "startDate",ascending: true)
        
        self.tableView.reloadData()
    }
    //MARK: - deleteItem
    override func deleteItem(at indexPath: IndexPath) {
        if itemType == type.fieldsItem || itemType == type.groupsItem {
            if indexPath.row < groupTodoItems!.count {
                if let itemForDeletion = self.groupTodoItems?[indexPath.row] {
                    deleteItemFromCloud(item: itemForDeletion)
                    do {
                        try self.realm.write {
                            self.realm.delete(itemForDeletion)
                        }
                    } catch {
                        print("Error Deleting item, \(error)")
                    }
                }
            } else {
                if let itemForDeletion = self.todoItems?[indexPath.row - groupTodoItems!.count] {
                    deleteItemFromCloud(item: itemForDeletion)
                    do {
                        try self.realm.write {
                            self.realm.delete(itemForDeletion)
                        }
                    } catch {
                        print("Error Deleting item, \(error)")
                    }
                }
            }
        } else {
            if let itemForDeletion = self.todoItems?[indexPath.row] {
                deleteItemFromCloud(item: itemForDeletion)
                do {
                    try self.realm.write {
                        self.realm.delete(itemForDeletion)
                    }
                } catch {
                    print("Error Deleting item, \(error)")
                }
            }
        }
    }
    
    //MARK: - listenItemDocuments
    func listenItemDocuments(parentID: String) {
        if user != nil {
            self.db.collection(userDefaults!.first!.bossID).document("Items").collection("Items").whereField("parentID", isEqualTo: parentID).addSnapshotListener { [self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        print("New item: \(diff.document.data())")
                        //print(diff.document.documentID)
                        if realm.object(ofType: Item.self, forPrimaryKey: diff.document.documentID) != nil {
                        } else {
                            //if diff.document.data()["updatedBy"] as? String != user.uid {
                                let item = Item()
                                item.id = diff.document.documentID
                                let itemData = diff.document.data()
                                if let title = itemData["title"] as? String, let status = itemData["status"] as? Int, let startDate = itemData["startDate"] as? Timestamp, let endDate = itemData["endDate"] as? Timestamp, let note = itemData["note"] as? String {
                                    item.title = title
                                    item.status = status
                                    item.startDate = startDate.dateValue()
                                    item.endDate = endDate.dateValue()
                                    item.note = note
                                }
                                do {
                                    try realm.write({
                                        realm.add(item)
                                        switch self.itemType {
                                        case .groupsItem:
                                            if let currentGroup = self.selectedGroup {
                                                currentGroup.items.append(item)
                                            }
                                        case .fieldsItem:
                                            if let currentField = self.selectedField {
                                                currentField.items.append(item)
                                            }
                                        case .linesItem:
                                            if let currentLine = self.selectedLine {
                                                currentLine.items.append(item)
                                            }
                                        case .placesItem:
                                            if let currentPlace = self.selectedPlace {
                                                currentPlace.items.append(item)
                                            }
                                        }
                                    })
                                } catch {
                                    print("Error saving context, \(error)")
                                }
                            //}
                        }
                        tableView.reloadData()
                    }
                    if (diff.type == .modified) {
                        print("Modified item: \(diff.document.data())")
                        if let specificItem = realm.object(ofType: Item.self, forPrimaryKey: diff.document.documentID) {
                            //if diff.document.data()["updatedBy"] as? String != user.uid {
                                let itemData = diff.document.data()
                                
                                if let title = itemData["title"] as? String, let status = itemData["status"] as? Int, let startDate = itemData["startDate"] as? Timestamp, let endDate = itemData["endDate"] as? Timestamp, let note = itemData["note"] as? String {
                                    do {
                                        try realm.write({
                                            if specificItem.title != title {
                                                specificItem.title = title
                                            }
                                            if specificItem.status != status {
                                                specificItem.status = status
                                            }
                                            if specificItem.startDate != startDate.dateValue() {
                                                specificItem.startDate = startDate.dateValue()
                                            }
                                            if specificItem.endDate != endDate.dateValue() {
                                                specificItem.endDate = endDate.dateValue()
                                            }
                                            if specificItem.note != note {
                                                specificItem.note = note
                                            }
                                        })
                                    } catch {
                                        print("Error saving context, \(error)")
                                    }
                                }
                                tableView.reloadData()
                            //}
                        } else {
                            
                        }
                    }
                    if (diff.type == .removed) {
                        print("Removed item: \(diff.document.data())")
                        if let specificItem = realm.object(ofType: Item.self, forPrimaryKey: diff.document.documentID) {
                            do {
                                try self.realm.write {
                                    self.realm.delete(specificItem)
                                }
                            } catch {
                                print("Error Deleting item, \(error)")
                            }
                        }
                        tableView.reloadData()
                    }
                }
            }
        }
    }
    
    //MARK: - saveItemToCloud
    func saveItemToCloud(item: Item) {
        if user != nil {
            //db.collection(user.uid).document("Items").collection("Items").document(item.id).setData([item.id: item.dictionaryWithValues(forKeys: ["title", "startDate", "endDate", "note", "status"]), "parentID": item.parentID]) { err in
            db.collection(userDefaults!.first!.bossID).document("Items").collection("Items").document(item.id).setData(item.dictionaryWithValues(forKeys: ["title", "startDate", "endDate", "note", "status", "parentID"])) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    //print("Document successfully written!")
                    //db.collection(user.uid).document("Items").setData([item.id : self.updateTime], merge: true)
                }
            }
        }
    }
    //MARK: - deleteItemFromCloud
    func deleteItemFromCloud(item: Item) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Items").collection("Items").document(item.id).delete()
        }
    }
}

//MARK: - UISearchBarDelegate

extension ToDoListViewController: UISearchBarDelegate {
    //MARK: - searchBarSearchButtonClicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "startDate", ascending: true)
        
        tableView.reloadData()
        
        searchBar.resignFirstResponder()
    }
    //MARK: - searchBar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count != 0 {
            switch itemType {
            case .groupsItem:
                loadItemsWithGroup()
            case .fieldsItem:
                loadItemsWithField()
            case .linesItem:
                loadItemsWithLine()
            case .placesItem:
                loadItemsWithPlace()
            }
        }
    }
    
}

extension ToDoListViewController: UITextFieldDelegate {
    //MARK: - textFieldShouldReturn
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
}
