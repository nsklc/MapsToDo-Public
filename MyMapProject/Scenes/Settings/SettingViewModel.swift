//
//  SettingViewModel.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 11.10.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift
import Firebase

protocol SettingsViewModelProtocol: AnyObject {
    var viewController: SettingsViewControllerProtocol? { get set }
    func switchStateDidChange(_ settingsOption: SettingsOptions, value: Bool)
    func notifyViewDidLoad()
    func setIsMeasureSystemMetric(_ value: Bool)
    func setDistanceUnit(distanceUnit: Int)
    func setAreaUnit(areaUnit: Int)
}

class SettingsViewModel: SettingsViewModelProtocol {
    
    weak var viewController: SettingsViewControllerProtocol?
    
    let realm: Realm! = try? Realm()
    
    private var userDefaults: Results<UserDefaults>?
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        userDefaults = realm.objects(UserDefaults.self)
    }
    
    func notifyViewDidLoad() {
        getIsMeasureSystemMetric()
        getIsShowDistance()
        getDistanceUnit()
        getIsShowAllUnitsSelected()
        getAreaUnit()
        getIsGeodesicActive()
        getIsBatterySaveModeActive()
        getIsLowDataModeActive()
    }
    
    func getIsMeasureSystemMetric() {
        if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
            viewController?.setIsMeasureSystemMetric(isMeasureSystemMetric: userDefaultsFirst.isMeasureSystemMetric)
        }
    }
    
    func getIsShowDistance() {
        if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
            viewController?.setIsShowDistance(isShowDistance: userDefaultsFirst.showDistancesBetweenTwoCorners)
        }
    }
    
    func getDistanceUnit() {
        if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
            viewController?.setDistanceUnit(distanceUnit: userDefaultsFirst.distanceUnit)
        }
    }
    
    func getIsShowAllUnitsSelected() {
        if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
            viewController?.setIsShowAllUnitsSelected(isShowAllUnitsSelected: userDefaultsFirst.isShowAllUnitsSelected)
        }
    }
    
    func getAreaUnit() {
        if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
            viewController?.setAreaUnit(areaUnit: userDefaultsFirst.areaUnit)
        }
    }
    
    func getIsGeodesicActive() {
        if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
            viewController?.setIsGeodesicActive(isGeodesicActive: userDefaultsFirst.isGeodesicActive)
        }
    }
    
    func getIsBatterySaveModeActive() {
        if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
            viewController?.setIsBatterySaveModeActive(isBatterySaveModeActive: userDefaultsFirst.isBatterySaveModeActive)
        }
    }
    
    func getIsLowDataModeActive() {
        if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
            viewController?.setIsLowDataModeActive(isLowDataModeActive: userDefaultsFirst.isLowDataModeActive)
        }
    }
    
    func setIsMeasureSystemMetric(_ value: Bool) {
        do {
            try realm.write({
                userDefaults?.first?.isMeasureSystemMetric = value
            })
        } catch {
            print("Error saving context, \(error)")
        }
    }
    
    func setDistanceUnit(distanceUnit: Int) {
        do {
            try realm.write({
                userDefaults?.first?.distanceUnit = distanceUnit
            })
        } catch {
            print("Error saving context, \(error)")
        }
    }
    
    func setAreaUnit(areaUnit: Int) {
        do {
            try realm.write({
                userDefaults?.first?.areaUnit = areaUnit
            })
        } catch {
            print("Error saving context, \(error)")
        }
    }
    
    func switchStateDidChange(_ settingsOption: SettingsOptions, value: Bool) {
        do {
            try realm.write({
                switch settingsOption {
                case .showDistance:
                    userDefaults?.first?.showDistancesBetweenTwoCorners = value
                case .showAll:
                    userDefaults?.first?.isShowAllUnitsSelected = value
                case .geodesic:
                    userDefaults?.first?.isGeodesicActive = value
                case .battery:
                    userDefaults?.first?.isBatterySaveModeActive = value
                case .data:
                    userDefaults?.first?.isLowDataModeActive = value
                }
            })
        } catch {
            print("Error saving context, \(error)")
        }
    }
}

enum SettingsOptions {
    case showDistance
    case showAll
    case geodesic
    case battery
    case data
}
