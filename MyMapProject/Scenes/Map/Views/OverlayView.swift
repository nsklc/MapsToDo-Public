//
//  OverlayView.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 4.04.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit
import GoogleMaps
import RealmSwift

class OverlayView: UIViewController {
    
    let realm: Realm! = try? Realm()
    
    private var userDefaults: Results<UserDefaults>?
    
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?
    
    @IBOutlet weak var slideIdicator: UIView!
    
    @IBOutlet weak var slidersStackView: UIStackView!
    
    @IBOutlet weak var roadsHorizontalSlider: UISlider!
    @IBOutlet weak var landmarksHorizontalSliders: UISlider!
    @IBOutlet weak var labelsHorizontalSlider: UISlider!
    
    @IBOutlet weak var roadsLabel: UILabel!
    @IBOutlet weak var landmarksLabel: UILabel!
    @IBOutlet weak var labelsLabel: UILabel!

    @IBOutlet weak var styleButtonsStackView: UIStackView!
  
    public var mapView: GMSMapView?
    
    private var currentMapStyle = MapStylesHelper.standard
    
    private var finalMapStyle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userDefaults = realm.objects(UserDefaults.self)
        
        roadsLabel.text = NSLocalizedString("Roads", comment: "")
        landmarksLabel.text = NSLocalizedString("Landmarks", comment: "")
        labelsLabel.text = NSLocalizedString("Labels", comment: "")
        
        slidersStackView.translatesAutoresizingMaskIntoConstraints = false
        slidersStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        slidersStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        slidersStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        slidersStackView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.4).isActive = true
        
        styleButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        styleButtonsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30).isActive = true
        styleButtonsStackView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.4).isActive = true
        if UIDevice.current.userInterfaceIdiom == .phone {
            styleButtonsStackView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8).isActive = true
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            styleButtonsStackView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        }
        
        styleButtonsStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
        
        slideIdicator.roundCorners(.allCorners, radius: 10)
        // subscribeButton.roundCorners(.allCorners, radius: 10)
        
        if let userDefaults = userDefaults?.first {
            if userDefaults.mapType != K.MapTypes.custom {
                currentMapStyle = MapStylesHelper.standard
                setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }
    // MARK: - panGestureRecognizerAction
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        // Not allowing the user to drag the view upward
        guard let pointOrigin = pointOrigin,
              translation.y >= 0 else { return }
        
        // setting x as 0 because we don't want users to move the frame side ways!! Only want straight up or down
        view.frame.origin = CGPoint(x: 0, y: pointOrigin.y + translation.y)
        
        if sender.state == .ended {
            let dragVelocity = sender.velocity(in: view)
            if dragVelocity.y >= 1300 {
                self.dismiss(animated: true, completion: nil)
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: 0, y: 400)
                }
            }
        }
    }
    // MARK: - setMapStyle
    func setMapStyle(to json: String) {
        print(json)
        if let mapView = mapView {
            do {
                mapView.mapType = .normal
                // Set the map style by passing a valid JSON string.
                mapView.mapStyle = try GMSMapStyle(jsonString: json)
                finalMapStyle = json
                
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
            
            self.mapView = mapView
        }
        
    }
    
    @IBAction func standardButtonTapped(_ sender: UIButton) {
        currentMapStyle = MapStylesHelper.standard
        setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
        
    }
    
    // MARK: - darkButtonTapped
    @IBAction func darkButtonTapped(_ sender: UIButton) {
        currentMapStyle = MapStylesHelper.dark
        setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
        
    }
    
    // MARK: - retroButtonTapped
    @IBAction func retroButtonTapped(_ sender: UIButton) {
        currentMapStyle = MapStylesHelper.retro
        setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
        
    }
    
    // MARK: - nightButtonTapped
    @IBAction func nightButtonTapped(_ sender: UIButton) {
        currentMapStyle = MapStylesHelper.night
        setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
        
    }
    
    // MARK: - silverButtonTapped
    @IBAction func silverButtonTapped(_ sender: UIButton) {
        currentMapStyle = MapStylesHelper.silver
        setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
        
    }
    
    // MARK: - aubergineButtonTapped
    @IBAction func aubergineButtonTapped(_ sender: UIButton) {
        currentMapStyle = MapStylesHelper.aubergine
        setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
        
    }
    // MARK: - makeJson
    func makeJson(theme: String, features: String) -> String {
    
        print(theme)
        
        print(features)
        
        var retro = theme
        if let index = retro.lastIndex(of: "]") {
            retro.remove(at: index)
        }
        
        // var road = features
        // road.remove(at: road.firstIndex(of: "[")!)
        if theme != MapStylesHelper.standard {
            retro.append(",")
        }
        
        retro.append(makeFeaturesJson())
        retro.append("\n]")
       
        // print("---")
        print(retro)
        
        return retro
    }
    // MARK: - makeFeaturesJson
    func makeFeaturesJson() -> String {
        
        var features = ""
        
        switch roadsHorizontalSlider.value {
        case 0...0.25:
            features.append(MapStylesHelper.road)
            features.append(",")
            break
        case 0.25...0.50:
            features.append(MapStylesHelper.road1)
            features.append(",")
            break
        case 0.50...0.75:
            features.append(MapStylesHelper.road2)
            features.append(",")
            break
        default:
            break
        }
        
        switch landmarksHorizontalSliders.value {
        case 0...0.25:
            features.append(MapStylesHelper.landmarks)
            features.append(",")
            break
        case 0.25...0.50:
            features.append(MapStylesHelper.landmarks1)
            features.append(",")
            break
        case 0.50...0.75:
            features.append(MapStylesHelper.landmarks2)
            features.append(",")
            break
        default:
            break
        }
        
        switch labelsHorizontalSlider.value {
        case 0...0.25:
            features.append(MapStylesHelper.labels)
            break
        case 0.25...0.50:
            features.append(MapStylesHelper.labels1)
            break
        case 0.50...0.75:
            features.append(MapStylesHelper.labels2)
            break
        default:
            break
        }
        
        if features.last == "," {
            features.remove(at: features.lastIndex(of: ",")!)
        }
       
        return features
    }
    
    // MARK: - roadsSliderValueChanged
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        switch sender.value {
        case 0:
            setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
        
            break
        case 0...0.33:
            setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
            
            break
        case 0.33...0.66:
           setMapStyle(to: makeJson(theme: currentMapStyle, features: makeFeaturesJson()))
            
            break
        case 0.66...1:
            break
        default:
            break
        }
    }
    
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let userDefaults = userDefaults?.first {
            currentMapStyle = userDefaults.customMapDefaultStyle
            roadsHorizontalSlider.value = userDefaults.roads
            labelsHorizontalSlider.value = userDefaults.labels
            landmarksHorizontalSliders.value = userDefaults.landmarks
        }
    }
    
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        if let userDefaults = userDefaults?.first {
            do {
                try realm.write({
                    userDefaults.mapType = K.MapTypes.custom
                    if let finalMapStyle = finalMapStyle {
                        userDefaults.customMapStyle = finalMapStyle
                    }
                    userDefaults.roads = roadsHorizontalSlider.value
                    userDefaults.labels = labelsHorizontalSlider.value
                    userDefaults.landmarks = landmarksHorizontalSliders.value
                    userDefaults.customMapDefaultStyle = currentMapStyle
                    
                })
            } catch {
                print()
            }
        }
        
    }
    
}
