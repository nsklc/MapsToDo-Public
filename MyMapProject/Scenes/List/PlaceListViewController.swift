//
//  PlaceViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 12.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework
import SwipeCellKit
import FirebaseAuth
import GoogleMaps

class PlaceListViewController: SwipeTableViewController, UINavigationControllerDelegate, UITextFieldDelegate {
    
    var placesController: PlacesController?
    
    var cameraPositionPath: GMSPath?
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        placesController!.loadPlaces()
        tableView.reloadData()
        
        title = NSLocalizedString("Places", comment: "")
        
        tableView.backgroundView = UIImageView(image: UIImage(named: K.imagesFromXCAssets.place8))
        tableView.backgroundView?.alpha = 0.3
        
        tableView.separatorStyle = .singleLine
        
    }
    //MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    //MARK: - editActionsForRowAt
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        placesController?.selectedPlace = (placesController?.places![indexPath.row])!
        
        let deleteAction = SwipeAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [self] action, indexPath in
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Delete%@", comment: ""), placesController!.selectedPlace.title), message: NSLocalizedString("Place's overlay and to-do items will be deleted.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [self] (uiAlertAction) in
              
                //self.placesController?.selectedGroundOverlay = (self.placesController?.groundOverlays[indexPath.row])!
                placesController?.deletePlaceFromCloud(place: placesController!.selectedPlace)
                placesController?.deletePlaceFromDB(place: placesController!.selectedPlace)
                tableView.reloadData()
                
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
        }
        
        let path = GMSMutablePath()
        path.add(CLLocationCoordinate2D(latitude: (self.placesController!.places?[indexPath.row].markerPosition?.latitude)!, longitude: (self.placesController!.places?[indexPath.row].markerPosition?.longitude)!))
        cameraPositionPath = path

        // customize the action appearance
        //deleteAction.image = UIImage(named: "delete-icon")
        deleteAction.image = UIImage(systemName: K.systemImages.trashFill)
        
        let findInTheMap = SwipeAction(style: .default, title: NSLocalizedString("Location", comment: "")) { action, indexPath in
            // handle action by updating model with go to map
            
            //_ = self.navigationController?.popViewController(animated: true)
            self.temp()
             
        }
        
        // customize the action appearance
        findInTheMap.image = UIImage(systemName: K.systemImages.locationFill)
        findInTheMap.backgroundColor = #colorLiteral(red: 0.03921568627, green: 0.5176470588, blue: 1, alpha: 1)

        let changeTitle = SwipeAction(style: .default, title: NSLocalizedString("Title", comment: "")) { action, indexPath in
            var textField = UITextField()
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Change %@'s Title", comment: ""), self.placesController!.places![indexPath.row].title), message: "", preferredStyle: .alert)
           
            let action = UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: .default) { [self] (action) in
                if let text = textField.text {
                    if text.count != 0 {
                        placesController!.changeTitle(for: placesController!.places![indexPath.row], title: text)
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
        if placesController!.places![indexPath.row].color != UIColor.flatYellow().hexValue() {
            changeTitle.backgroundColor = UIColor.flatYellow()
        } else {
            changeTitle.backgroundColor = UIColor.flatBlue()
        }
        
        return [deleteAction, findInTheMap, changeTitle]
       
    }
    //MARK: - temp
    func temp() {
        performSegue(withIdentifier: K.segueIdentifiers.placeListToMapView, sender: self)
    }
    //MARK: - back
    @objc func back(sender: UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
        //performSegue(withIdentifier: "placeListToMapView", sender: self)
    }
    //MARK: - prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.segueIdentifiers.goToItems {
            let destinationVC = segue.destination as! ToDoListViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.selectedPlace = placesController?.places?[indexPath.row]
            }
        } else if segue.identifier == K.segueIdentifiers.placeListToMapView {
            
            let destinationVC = segue.destination as! MapViewController
            
            if let cameraPositionPath = cameraPositionPath {
                destinationVC.cameraPositionPath = cameraPositionPath
            }
            
        }
        
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
    
    //MARK: - TableView DataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placesController!.places?.count ?? 1
       }
    
    // Provide a cell object for each row.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
          
        if let place = placesController!.places?[indexPath.row]{
            
            //cell.textLabel!.text = place.title
                
            guard let placeColor =  UIColor(hexString: place.color) else {fatalError()}
                
            //cell.backgroundColor = placeColor
            
            //cell.textLabel?.textColor = ContrastColorOf(placeColor, returnFlat: true)
            
            cell.backgroundColor = UIColor.clear
        
            let label = UILabel()
            label.text = place.title
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            
            label.textColor = ContrastColorOf(placeColor, returnFlat: true)
            label.backgroundColor = placeColor
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)
            label.heightAnchor.constraint(equalTo: cell.heightAnchor, constant: 0).isActive = true
            label.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 0.4).isActive = true
            label.leftAnchor.constraint(equalTo: cell.leftAnchor, constant: 0).isActive = true
        }
        
        
        return cell
    }
    
    //MARK: - Table Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: K.segueIdentifiers.goToItems, sender: self)
    }
   
}

