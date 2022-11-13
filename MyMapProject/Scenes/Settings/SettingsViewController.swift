//
//  SettingsViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 2.11.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import RealmSwift
import Firebase

protocol SettingsViewControllerProtocol: AnyObject {
    func setIsMeasureSystemMetric(isMeasureSystemMetric: Bool)
    func setIsShowDistance(IsShowDistance: Bool)
    func setDistanceUnit(distanceUnit: Int)
    func setIsShowAllUnitsSelected(isShowAllUnitsSelected: Bool)
    func setAreaUnit(areaUnit: Int)
    func setIsGeodesicActive(isGeodesicActive: Bool)
    func setIsBatterySaveModeActive(isBatterySaveModeActive: Bool)
    func setIsLowDataModeActive(isLowDataModeActive: Bool)
}

final class SettingsViewController: UITableViewController {
    
    private var viewModel: SettingsViewModelProtocol?
    private var cellList = [UITableViewCell]()
    
    private weak var unitsSegmentedControl: UISegmentedControl!
    private weak var distanceUnitSegmentedControl: UISegmentedControl!
    private weak var areaUnitSegmentedControl: UISegmentedControl!
    private weak var showAllSwitchUI: UISwitch!
    private weak var showDistanceSwitchUI: UISwitch!
    private weak var geodesicSwitchUI: UISwitch!
    private weak var batterySwitchUI: UISwitch!
    private weak var dataSwitchUI: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = SettingsViewModel()
        viewModel?.viewController = self
        
        tableView.rowHeight = 80
        title = NSLocalizedString("Settings", comment: "")
        view.backgroundColor = UIColor(hexString: K.colors.thirdColor)
        
        addMeasurementUnitsCell()
        addShowDistanceBetweenCornersCell()
        addDistanceUnitCell()
        addShowAllCalculatedUnitsCell()
        addAreaUnitCell()
        addSeperator()
        addGeodesicCorrectionCell()
        addSeperator()
        addBatterySavingModeCell()
        addLowDataModeCell()
        viewModel?.notifyViewDidLoad()
    }
    
    func addSeperator() {
        let cell = UITableViewCell()
        cell.contentView.isUserInteractionEnabled = false
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        cellList.append(cell)
    }
    
    func addMeasurementUnitsCell() {
        let cell = SegmentedControlCell(labelText: NSLocalizedString("Measurement units", comment: ""))
        cell.segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        unitsSegmentedControl = cell.segmentedControl
        unitsSegmentedControl.insertSegment(withTitle: NSLocalizedString("Metric", comment: ""), at: 0, animated: true)
        unitsSegmentedControl.apportionsSegmentWidthsByContent = true
        unitsSegmentedControl.insertSegment(withTitle: NSLocalizedString("Imperial", comment: ""), at: 1, animated: true)
        cellList.append(cell)
    }
    
    func addShowDistanceBetweenCornersCell() {
        let cell = SwitchViewCell(labelText: NSLocalizedString("Show distance between corners", comment: ""), switchDefaultValue: true)
        cell.switchUI.addTarget(self, action: #selector(showDistanceSwitchStateDidChange(_:)), for: .valueChanged)
        showDistanceSwitchUI = cell.switchUI
        cellList.append(cell)
    }
    
    func addDistanceUnitCell() {
        let cell = SegmentedControlCell(labelText: NSLocalizedString("Distance unit between corners", comment: ""))
        cell.segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        distanceUnitSegmentedControl = cell.segmentedControl
        cellList.append(cell)
    }
    
    func addGeodesicCorrectionCell() {
        let cell = SwitchViewCell(labelText: NSLocalizedString("Render with geodesic correction", comment: ""), switchDefaultValue: true)
        cell.switchUI.addTarget(self, action: #selector(geodesicSwitchStateDidChange(_:)), for: .valueChanged)
        geodesicSwitchUI = cell.switchUI
        cellList.append(cell)
    }
    
    func addAreaUnitCell() {
        let cell = SegmentedControlCell(labelText: NSLocalizedString("Area unit", comment: ""))
        cell.segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        areaUnitSegmentedControl = cell.segmentedControl
        cellList.append(cell)
    }
    
    func addShowAllCalculatedUnitsCell() {
        let cell = SwitchViewCell(labelText: NSLocalizedString("Show all calculated units", comment: ""), switchDefaultValue: true)
        cell.switchUI.addTarget(self, action: #selector(showAllSwitchStateDidChange(_:)), for: .valueChanged)
        showAllSwitchUI = cell.switchUI
        cellList.append(cell)
    }
    
    func addBatterySavingModeCell() {
        let cell = SwitchViewCell(labelText: NSLocalizedString("Battery saving mode", comment: ""), switchDefaultValue: true)
        cell.switchUI.addTarget(self, action: #selector(batterySwitchStateDidChange(_:)), for: .valueChanged)
        batterySwitchUI = cell.switchUI
        cellList.append(cell)
    }
    
    func addLowDataModeCell() {
        let cell = SwitchViewCell(labelText: NSLocalizedString("Low data mode", comment: ""), switchDefaultValue: true)
        cell.switchUI.addTarget(self, action: #selector(dataSwitchStateDidChange(_:)), for: .valueChanged)
        dataSwitchUI = cell.switchUI
        cellList.append(cell)
    }
    
    //MARK: - heightForRowAt
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 5 || indexPath.row == 7 {
            return 10 // the height you want
        } else {
            return 80
        }
    }
    //MARK: - segmentedControlValueChanged
    @objc func segmentedControlValueChanged(_ segment: UISegmentedControl!) {
        
        switch segment {
        case unitsSegmentedControl:
            if segment.selectedSegmentIndex == 0 {
                viewModel?.setIsMeasureSystemMetric(true)
            }
            else {
                viewModel?.setIsMeasureSystemMetric(false)
            }
            
            setDistanceUnitSegments(isMetric: segment.selectedSegmentIndex == 0, selectedSegmentIndex: distanceUnitSegmentedControl.selectedSegmentIndex)
            
            setAreaUnitSegments(isMetric: segment.selectedSegmentIndex == 0, selectedSegmentIndex: areaUnitSegmentedControl.selectedSegmentIndex)
            
        case distanceUnitSegmentedControl:
            viewModel?.setDistanceUnit(distanceUnit: distanceUnitSegmentedControl.selectedSegmentIndex)
        case areaUnitSegmentedControl:
            viewModel?.setAreaUnit(areaUnit: areaUnitSegmentedControl.selectedSegmentIndex)
        default:
            break
        }
    }
    
    func setAreaUnitSegments(isMetric: Bool, selectedSegmentIndex: Int?) {
        areaUnitSegmentedControl.removeAllSegments()
        if isMetric {
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("cm\u{00B2}", comment: ""), at: 0, animated: true)
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("m\u{00B2}", comment: ""), at: 1, animated: true)
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("km\u{00B2}", comment: ""), at: 2, animated: true)
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("a", comment: ""), at: 3, animated: true)
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("ha", comment: ""), at: 4, animated: true)
        } else {
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("in\u{00B2}", comment: ""), at: 0, animated: true)
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("ft\u{00B2}", comment: ""), at: 1, animated: true)
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("yd\u{00B2}", comment: ""), at: 2, animated: true)
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("mi\u{00B2}", comment: ""), at: 3, animated: true)
            areaUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("ac", comment: ""), at: 4, animated: true)
        }
        if let selectedSegmentIndex = selectedSegmentIndex {
            areaUnitSegmentedControl.selectedSegmentIndex = selectedSegmentIndex
        }
    }
    
    func setDistanceUnitSegments(isMetric: Bool, selectedSegmentIndex: Int?) {
        distanceUnitSegmentedControl.removeAllSegments()
        if isMetric {
            distanceUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("cm", comment: ""), at: 0, animated: true)
            distanceUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("m", comment: ""), at: 1, animated: true)
            distanceUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("km", comment: ""), at: 2, animated: true)
            if let selectedSegmentIndex = selectedSegmentIndex {
                if selectedSegmentIndex == 3 {
                    viewModel?.setDistanceUnit(distanceUnit: 2)
                    distanceUnitSegmentedControl.selectedSegmentIndex = 2
                } else {
                    distanceUnitSegmentedControl.selectedSegmentIndex = selectedSegmentIndex
                }
            }
        } else {
            distanceUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("in", comment: ""), at: 0, animated: true)
            distanceUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("ft", comment: ""), at: 1, animated: true)
            distanceUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("yd", comment: ""), at: 2, animated: true)
            distanceUnitSegmentedControl.insertSegment(withTitle: NSLocalizedString("mi", comment: ""), at: 3, animated: true)
            if let selectedSegmentIndex = selectedSegmentIndex {
                distanceUnitSegmentedControl.selectedSegmentIndex = selectedSegmentIndex
            }
        }
    }
    
    @objc func showDistanceSwitchStateDidChange(_ sender:UISwitch!){
        viewModel?.switchStateDidChange(.showDistance, value: sender.isOn)
    }
    
    @objc func showAllSwitchStateDidChange(_ sender:UISwitch!){
        viewModel?.switchStateDidChange(.showAll, value: sender.isOn)
    }
    
    @objc func geodesicSwitchStateDidChange(_ sender:UISwitch!){
        viewModel?.switchStateDidChange(.geodesic, value: sender.isOn)
    }
    
    @objc func batterySwitchStateDidChange(_ sender:UISwitch!){
        viewModel?.switchStateDidChange(.battery, value: sender.isOn)
    }
    
    @objc func dataSwitchStateDidChange(_ sender:UISwitch!){
        viewModel?.switchStateDidChange(.data, value: sender.isOn)
    }

    //MARK: - cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return cellList[indexPath.row]
    }
    //MARK: - numberOfRowsInSection
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellList.count
    }
    //MARK: - didSelectRowAt
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print(indexPath.row)
    }

}

extension SettingsViewController: SettingsViewControllerProtocol {
    func setIsMeasureSystemMetric(isMeasureSystemMetric: Bool) {
        if isMeasureSystemMetric {
            unitsSegmentedControl.selectedSegmentIndex = 0
            setDistanceUnitSegments(isMetric: true, selectedSegmentIndex: nil)
            setAreaUnitSegments(isMetric: true, selectedSegmentIndex: nil)
        } else {
            unitsSegmentedControl.selectedSegmentIndex = 1
            setDistanceUnitSegments(isMetric: false, selectedSegmentIndex: nil)
            setAreaUnitSegments(isMetric: false, selectedSegmentIndex: nil)
        }
    }
    
    func setIsShowDistance(IsShowDistance: Bool) {
        showDistanceSwitchUI.setOn(IsShowDistance, animated: false)
    }
    
    func setDistanceUnit(distanceUnit: Int) {
        distanceUnitSegmentedControl.selectedSegmentIndex = distanceUnit
    }
    
    func setIsShowAllUnitsSelected(isShowAllUnitsSelected: Bool) {
        showAllSwitchUI.setOn(isShowAllUnitsSelected, animated: false)
    }
    
    func setAreaUnit(areaUnit: Int) {
        areaUnitSegmentedControl.selectedSegmentIndex = areaUnit
    }
    
    func setIsGeodesicActive(isGeodesicActive: Bool) {
        geodesicSwitchUI.setOn(isGeodesicActive, animated: false)
    }
    
    func setIsBatterySaveModeActive(isBatterySaveModeActive: Bool) {
        batterySwitchUI.setOn(isBatterySaveModeActive, animated: false)
    }
    
    func setIsLowDataModeActive(isLowDataModeActive: Bool) {
        dataSwitchUI.setOn(isLowDataModeActive, animated: false)
    }
}
