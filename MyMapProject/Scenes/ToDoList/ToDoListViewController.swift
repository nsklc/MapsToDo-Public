//
//  File.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 13.09.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import ChameleonFramework
import SwipeCellKit

enum TodoItemType {
    case groupsItem
    case fieldsItem
    case linesItem
    case placesItem
}

protocol ToDoListViewControllerProtocol: AnyObject {
    func reloadTableViewData()
}

class ToDoListViewController: SwipeTableViewController, ToDoListViewControllerProtocol {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var viewModel: ToDoListViewModelProtocol = ToDoListViewModel()
    let addButton = UIButton.init(type: .system)
    var itemType = TodoItemType.fieldsItem
    var status = [NSLocalizedString("Waiting To Run", comment: ""), NSLocalizedString("In Progress", comment: ""), NSLocalizedString("Completed", comment: ""), NSLocalizedString("Canceled", comment: "")]
    
    //MARK: - selectedGroup
    var selectedGroup: Group? {
        didSet {
            viewModel.viewController = self
            title = String(format: NSLocalizedString("%@'s Items", comment: ""), selectedGroup!.title)
            itemType = TodoItemType.groupsItem
            if let selectedGroup = selectedGroup {
                viewModel.listenItemDocuments(parentID: selectedGroup.id, overlay: selectedGroup)
                viewModel.loadItemsWithGroup(selectedGroup: selectedGroup)
            }
            infoButton.isEnabled = false
            infoButton.image = UIImage()
        }
    }
    //MARK: - selectedField
    var selectedField: Field? {
        didSet {
            viewModel.viewController = self
            title = String(format: NSLocalizedString("%@'s Items", comment: ""), selectedField!.title)
            itemType = TodoItemType.fieldsItem
            if let selectedGroup = selectedGroup {
                viewModel.listenItemDocuments(parentID: selectedGroup.id, overlay: selectedGroup)
                viewModel.loadItemsWithGroup(selectedGroup: selectedGroup)
            }
            if let selectedField = selectedField {
                viewModel.listenItemDocuments(parentID: selectedField.id, overlay: selectedField)
                viewModel.loadItemsWithField(selectedField: selectedField)
            }
            infoButton.isEnabled = true
            infoButton.image = UIImage(systemName: K.systemImages.infoCircleFill)
        }
    }
    //MARK: - selectedLine
    var selectedLine: Line? {
        didSet {
            viewModel.viewController = self
            title = String(format: NSLocalizedString("%@'s Items", comment: ""), selectedLine!.title)
            itemType = TodoItemType.linesItem
            if let selectedLine = selectedLine {
                viewModel.listenItemDocuments(parentID: selectedLine.id, overlay: selectedLine)
                viewModel.loadItemsWithLine(selectedLine: selectedLine)
            }
            infoButton.isEnabled = true
            infoButton.image = UIImage(systemName: K.systemImages.infoCircleFill)
        }
    }
    //MARK: - selectedPlace
    var selectedPlace: Place? {
        didSet {
            viewModel.viewController = self
            title = String(format: NSLocalizedString("%@'s Items", comment: ""), selectedPlace!.title)
            itemType = TodoItemType.placesItem
            if let selectedPlace = selectedPlace {
                viewModel.listenItemDocuments(parentID: selectedPlace.id, overlay: selectedPlace)
                viewModel.loadItemsWithPlace(selectedPlace: selectedPlace)
            }
            infoButton.isEnabled = true
            infoButton.image = UIImage(systemName: K.systemImages.infoCircleFill)
        }
    }
    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    //MARK: - setupUI
    func setupUI() {
        addButton.setImage(UIImage(systemName: K.systemImages.plus), for: .normal)
        addButton.tintColor = UIColor(hexString: K.colors.secondaryColor)
        addButton.backgroundColor = UIColor(hexString: K.colors.thirdColor)
        addButton.layer.borderWidth = 0.25
        addButton.layer.borderColor = UIColor.systemBlue.cgColor
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
        addButton.addTarget(self, action: #selector(showAddItemAlert) ,
                           for: .touchUpInside)
        
        tableView.separatorStyle = .singleLine
        tableView.backgroundView = UIImageView(image: UIImage(named: K.imagesFromXCAssets.picture7))
        tableView.backgroundView?.alpha = 0.3
  
        if let selectedGroup = selectedGroup {
            viewModel.loadItemsWithGroup(selectedGroup: selectedGroup)
        }
        if let selectedField = selectedField {
            viewModel.loadItemsWithField(selectedField: selectedField)
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
        
        if viewModel.checkIsToDoItemsCountAtLimit() {
            AlertsHelper.addingExtraToDoItemAlert(on: self)
            return
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
                    switch self.itemType {
                    case .groupsItem:
                        if let currentGroup = self.selectedGroup {
                            self.viewModel.addNewToDoItemsToOverlay(title: text, overlay: currentGroup)
                        }
                    case .fieldsItem:
                        if let currentField = self.selectedField {
                            self.viewModel.addNewToDoItemsToOverlay(title: text, overlay: currentField)
                        }
                    case .linesItem:
                        if let currentLine = self.selectedLine {
                            self.viewModel.addNewToDoItemsToOverlay(title: text, overlay: currentLine)
                        }
                    case .placesItem:
                        if let currentPlace = self.selectedPlace {
                            self.viewModel.addNewToDoItemsToOverlay(title: text, overlay: currentPlace)
                        }
                    }
                    
                }
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = NSLocalizedString("Create new item", comment: "")
            textField = alertTextField
            alertTextField.delegate = self
        }
        
        alert.addAction(action)
        
        if itemType == TodoItemType.groupsItem {
            let action1 = UIAlertAction(title: NSLocalizedString("Add Items as Individual Field Item", comment: ""), style: .default) { [self] (action) in
                if let currentGroup = self.selectedGroup, let text = textField.text {
                    viewModel.addToDoItemsForAllGroup(group: currentGroup, title: text)
                }
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
                viewModel.deleteItem(at: indexPath, itemType: itemType)
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
        return viewModel.getToDoItemsCount(itemType: itemType)
    }

    //MARK: - cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let df = DateFormatter()
        df.dateFormat = "MM.dd.YYYY"
        var statusIndex = 0
        
        switch itemType {
        case .fieldsItem:
            if indexPath.row < viewModel.getToDoItemsCount(itemType: .groupsItem) {
                if let item = viewModel.getItem(for: itemType, with: indexPath.row) {
                    cell.textLabel?.text = String(format: NSLocalizedString("%@ - Group Task", comment: ""), item.title)
                    cell.detailTextLabel?.text = df.string(from: item.startDate) + " - " + df.string(from: item.endDate)
                    statusIndex = item.status
                } else {
                    cell.textLabel?.text = NSLocalizedString("No Items Added", comment: "")
                }
            } else {
                if let item = viewModel.getItem(for: .fieldsItem, with: indexPath.row - viewModel.getToDoItemsCount(itemType: .groupsItem)) {
                    cell.textLabel?.text = item.title
                    cell.detailTextLabel?.text = df.string(from: item.startDate) + " - " + df.string(from: item.endDate)
                    statusIndex = item.status
                
                } else {
                    cell.textLabel?.text = NSLocalizedString("No Items Added", comment: "")
                }
            }
        default:
            if let item = viewModel.getItem(for: itemType, with: indexPath.row) {
                cell.textLabel?.text = item.title
                
                cell.detailTextLabel?.text = df.string(from: item.startDate) + " - " + df.string(from: item.endDate)
                statusIndex = item.status
            } else {
                cell.textLabel?.text = NSLocalizedString("No Items Added", comment: "")
            }
        }
        
        let label = UILabel()
        label.text = String(format: NSLocalizedString("%@", comment: ""), status[statusIndex])
        
        switch statusIndex {
        case 0:
            label.backgroundColor = UIColor.flatYellow()
        case 1:
            label.backgroundColor = UIColor.flatBlue()
        case 2:
            label.backgroundColor = UIColor.flatGreen()
        case 3:
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
                destinationVC.selectedItem = viewModel.getItem(for: itemType, with: indexPath.row)
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
    //MARK: - reloadTableViewData
    func reloadTableViewData() {
        self.tableView.reloadData()
    }
    //MARK: - deleteItem
    override func deleteItem(at indexPath: IndexPath) {}
}

//MARK: - UISearchBarDelegate

extension ToDoListViewController: UISearchBarDelegate {
    //MARK: - searchBarSearchButtonClicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            viewModel.filterToDoItems(filterText: text)
        }
        searchBar.resignFirstResponder()
    }
    //MARK: - searchBar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        switch itemType {
        case .groupsItem:
            if let selectedGroup = selectedGroup {
                viewModel.loadItemsWithGroup(selectedGroup: selectedGroup)
            }
        case .fieldsItem:
            if let selectedField = selectedField {
                viewModel.loadItemsWithField(selectedField: selectedField)
            }
        case .linesItem:
            if let selectedLine = selectedLine {
                viewModel.loadItemsWithLine(selectedLine: selectedLine)
            }
        case .placesItem:
            if let selectedPlace = selectedPlace {
                viewModel.loadItemsWithPlace(selectedPlace: selectedPlace)
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
        // make sure the result is under 20 characters
        return updatedText.count <= 20
    }
}
