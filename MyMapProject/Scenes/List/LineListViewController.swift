//
//  LineViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 12.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import ChameleonFramework
import SwipeCellKit
import GoogleMaps

class LineListViewController: SwipeTableViewController, UITextFieldDelegate {
    
    var linesController: LinesController?
    var cameraPositionPath: GMSPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        linesController!.loadLines()
        self.tableView.reloadData()
        
        title = NSLocalizedString("Lines", comment: "")
        
        tableView.backgroundView = UIImageView(image: UIImage(named: K.ImagesFromXCAssets.line3))
        
        tableView.backgroundView?.alpha = 0.3
        
        tableView.separatorStyle = .singleLine
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
       
    }
    
    override func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        return options
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right,
              let linesController = linesController, let lines = linesController.lines else { return nil }
        
        linesController.selectedLine = lines[indexPath.row]
        
        let deleteAction = SwipeAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [self] _, _ in
            
            AlertsHelper.deleteAlert(on: self,
                                     with: .line,
                                     overlayTitle: linesController.selectedLine.title) { [weak self] in
                guard let self = self,
                        let linesController = self.linesController else { return }
                linesController.deleteLineFromCloud(line: linesController.selectedLine)
                linesController.deleteSelectedLineFromDB(line: linesController.selectedLine)
                self.tableView.reloadData()
            }
        }
        if let polyline = linesController.polylines.first(where: {$0.title == lines[indexPath.row].id}) {
            cameraPositionPath = polyline.path
        }
        
        // customize the action appearance
        // deleteAction.image = UIImage(named: "delete-icon")
        deleteAction.image = UIImage(systemName: K.SystemImages.trashFill)
        
        let findInTheMap = SwipeAction(style: .default, title: NSLocalizedString("Location", comment: "")) { _, _ in
            self.goBackToMapView()
        }

        // customize the action appearance
        findInTheMap.image = UIImage(systemName: K.SystemImages.locationFill)
        findInTheMap.backgroundColor = #colorLiteral(red: 0.03921568627, green: 0.5176470588, blue: 1, alpha: 1)
        
        let changeTitle = SwipeAction(style: .default, title: NSLocalizedString("Title", comment: "")) { _, indexPath in
            guard let linesController = self.linesController,
                    let lines = linesController.lines else { return }
            AlertsHelper.changeTitleAlert(on: self,
                                          title: lines[indexPath.row].title,
                                          overlayType: .line) { newTitle in
                linesController.changeTitle(for: (lines[indexPath.row]), title: newTitle)
                tableView.reloadData()
            }
        }

        // customize the action appearance
        changeTitle.image = UIImage(systemName: K.SystemImages.rectangleAndPencilAndEllipsisrtl)
        if lines[indexPath.row].color != UIColor.flatYellow().hexValue() {
            changeTitle.backgroundColor = UIColor.flatYellow()
        } else {
            changeTitle.backgroundColor = UIColor.flatBlue()
        }

        return [deleteAction, findInTheMap, changeTitle]
    }
    
    func goBackToMapView() {
        performSegue(withIdentifier: K.SegueIdentifiers.lineListToMapView, sender: self)
    }
    
    @objc func back(sender: UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
        // performSegue(withIdentifier: "lineListToMapView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.SegueIdentifiers.goToItems {
            let destinationVC = segue.destination as? ToDoListViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC?.selectedLine = linesController?.lines?[indexPath.row]
            }
        } else if segue.identifier == K.SegueIdentifiers.lineListToMapView {
            
            let destinationVC = segue.destination as? MapViewController
            if let cameraPositionPath = cameraPositionPath {
                destinationVC?.cameraPositionPath = cameraPositionPath
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
    
    // MARK: - TableView DataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        linesController?.lines!.count ?? 1
       }

    /*override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! SwipeTableViewCell
        cell.delegate = self
        return cell
    }*/
    
       // Provide a cell object for each row.
       override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
          
        if let line = linesController?.lines![indexPath.row] {
        
            // cell.textLabel!.text = line.title
        
            guard let lineColor =  UIColor(hexString: line.color) else {fatalError()}
            
            // cell.backgroundColor = lineColor
        
            let length = Measurement(value: line.length, unit: UnitLength.meters)
            
            let formatter = MeasurementFormatter()
            formatter.numberFormatter.maximumFractionDigits = 4
            formatter.unitOptions = .providedUnit
            
            if linesController!.userDefaults!.first!.isMeasureSystemMetric {
                switch linesController!.userDefaults!.first!.distanceUnit {
                case 0:
                    cell.detailTextLabel?.text = "\( formatter.string(from: length.converted(to: UnitLength.centimeters))) "
                case 1:
                    cell.detailTextLabel?.text = "\( formatter.string(from: length.converted(to: UnitLength.meters))) "
                case 2:
                    cell.detailTextLabel?.text = "\( formatter.string(from: length.converted(to: UnitLength.kilometers))) "
                default:
                    break
                }
            } else {
                switch linesController!.userDefaults!.first!.distanceUnit {
                case 0:
                    cell.detailTextLabel?.text = "\( formatter.string(from: length.converted(to: UnitLength.inches))) "
                case 1:
                    cell.detailTextLabel?.text = "\( formatter.string(from: length.converted(to: UnitLength.feet))) "
                case 2:
                    cell.detailTextLabel?.text = "\( formatter.string(from: length.converted(to: UnitLength.yards))) "
                case 3:
                    cell.detailTextLabel?.text = "\( formatter.string(from: length.converted(to: UnitLength.miles))) "
                default:
                    break
                }
            }
            // cell.textLabel?.textColor = ContrastColorOf(lineColor, returnFlat: true)
            
            cell.detailTextLabel?.textColor = UIColor.flatBlack()
            
            let label = UILabel()
            label.text = line.title
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            
            label.textColor = ContrastColorOf(lineColor, returnFlat: true)
            label.backgroundColor = lineColor
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)
            label.heightAnchor.constraint(equalTo: cell.heightAnchor, constant: 0).isActive = true
            label.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 0.4).isActive = true
            label.leftAnchor.constraint(equalTo: cell.leftAnchor, constant: 0).isActive = true
            
            cell.backgroundColor = UIColor.clear
            
        }
            return cell
       }
    
    // MARK: - Table Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: K.SegueIdentifiers.goToItems, sender: self)
    }
}
