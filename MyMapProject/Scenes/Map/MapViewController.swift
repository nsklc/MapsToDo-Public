//
//  ViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 21.08.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMaps
import Firebase
import GoogleSignIn
import Purchases
import GoogleMobileAds

import MobileCoreServices
import UniformTypeIdentifiers

protocol MapViewControllerProtocol: AnyObject {
    func setUserDefaultSettings(latitude: Double?, longitude: Double?, zoom: Float?, mapType: String?, customMapStyle: String?, isBatterySaveModeActive: Bool)
    func arrangeUI(isProAccount: Bool)
}

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    private let realm = try! Realm()
    
    private var fieldsController: FieldsController?
    private var linesController: LinesController?
    private var placesController: PlacesController?
    
    private var userDefaults: Results<UserDefaults>?
    
    @IBOutlet weak var navBar: UINavigationItem! 
    @IBOutlet weak var authenticationNavBarButton: UIBarButtonItem!
    
    @IBOutlet weak var arrowButton: UIButton!
    
    @IBOutlet weak var addStackView: UIStackView!
    @IBOutlet weak var addFormStackView: UIStackView!
    private enum overlayTypeOptions {
        case field
        case line
        case place
    }
    private var addType : overlayTypeOptions = .field
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var groupTitleTextField: UITextField!
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var minusButton: UIBarButtonItem!
    @IBOutlet weak var plusButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var trashButton: UIBarButtonItem!
    
    private var editingOverlayType: overlayTypeOptions = .place
    @IBOutlet weak var selectAllButton: UIBarButtonItem!
    @IBOutlet weak var colorBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var colorsCollectionView: UICollectionView!
    @IBOutlet weak var colorsCollectionView1: UICollectionView!
    
    private let transition = SlideInTransition()
    
    @IBOutlet weak var colorButton: UIButton!
    private let colors = [UIColor.flatRed(), UIColor.flatOrange(), UIColor.flatYellow(), UIColor.flatSand(), UIColor.flatNavyBlue(), UIColor.flatBlack(), UIColor.flatMagenta(), UIColor.flatTeal(), UIColor.flatSkyBlue(), UIColor.flatGreen(), UIColor.flatMint(), UIColor.flatWhite(), UIColor.flatGray(), UIColor.flatForestGreen(), UIColor.flatPurple(), UIColor.flatBrown(), UIColor.flatPlum(), UIColor.flatWatermelon(), UIColor.flatLime(), UIColor.flatPink(), UIColor.flatMaroon(), UIColor.flatCoffee(), UIColor.flatPowderBlue(), UIColor.flatBlue()]
    
    @IBOutlet weak var mapTypeSelectButton: UIButton!
    @IBOutlet weak var mapTypeStackView: UIStackView!
    
    let locationManager = CLLocationManager()
    @IBOutlet weak var myLocationButton: UIButton!
    var cameraPositionPath: GMSPath?
    
    @IBOutlet weak var areaLabel: UILabel!
    
    private var mapView: GMSMapView!
    private var markerFirstPosition: [Double] = [0.0, 0.0]
    private var draggingMarker: GMSMarker!
    
    private var isInitialState = false
    private var initialMarkers = [GMSMarker]()
    
    private let nc = NotificationCenter.default
    
    private var positionMarker: GMSMarker?
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let user = Auth.auth().currentUser
    
    var centerYConstraint: NSLayoutConstraint!
    
    @IBOutlet var bannerView: GADBannerView!
    private var interstitial: GADInterstitialAd?
    weak var timer: Timer?
    private var showAd = false
    
    @objc func fireTimer() {
        showAd = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.navigationController?.navigationBar.barStyle = .default
        
        navBar.title = K.appName
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager.startUpdatingLocation()
            }
        }
        
        
        // Get userDefaults in the realm
        userDefaults = realm.objects(UserDefaults.self)
        
        if userDefaults?.count == 0 {
            let userDefault = UserDefaults()
            userDefault.title = ""
            userDefault.mapType = K.mapTypes.satellite
            userDefault.cameraPosition = CameraPosition()
            if let latitude = locationManager.location?.coordinate.latitude, let longitude = locationManager.location?.coordinate.longitude {
                userDefault.cameraPosition?.latitude = latitude
                userDefault.cameraPosition?.longitude = longitude
            } else {
                userDefault.cameraPosition?.latitude = 37.3348
                userDefault.cameraPosition?.longitude = -122.0091
            }
            userDefault.cameraPosition?.zoom = 16.5
        
            do {
                try realm.write({
                    realm.add(userDefault)
                })
            } catch {
                print("Error saving context, \(error)")
            }
            userDefaults = realm.objects(UserDefaults.self)
        }
        
        // Create a GMSCameraPosition that tells the map to display the coordinate.
        let camera = GMSCameraPosition.camera(withLatitude: 39.738185, longitude: 37.088220, zoom: 16)
        
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        mapView.mapType = .normal
    
        if let userDefault = userDefaults?.first {
            if let latitude = userDefault.cameraPosition?.latitude, let longitude = userDefault.cameraPosition?.longitude, let zoom = userDefault.cameraPosition?.zoom {
                let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: zoom)
                mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            }
            
            switch userDefault.mapType {
            case K.mapTypes.normal:
                mapView.mapType = .normal
            case K.mapTypes.satellite:
                mapView.mapType = .satellite
            case K.mapTypes.terrain:
                mapView.mapType = .terrain
            case K.mapTypes.custom:
                mapView.mapType = .normal
                let overlayView = OverlayView()
                overlayView.mapView = mapView
                overlayView.setMapStyle(to: userDefault.customMapStyle)
            default:
                mapView.mapType = .normal
            }
        
            arrowButton.layer.borderWidth = 2
            myLocationButton.layer.borderWidth = 2
            mapTypeSelectButton.layer.borderWidth = 2
        
            let tintColor = UIColor(hexString: K.colors.secondaryColor)
            let backgroundColor = UIColor(hexString: K.colors.thirdColor)
            
            arrowButton.layer.borderColor = tintColor?.cgColor
            myLocationButton.layer.borderColor = tintColor?.cgColor
            mapTypeSelectButton.layer.borderColor = tintColor?.cgColor
            
            arrowButton.tintColor = tintColor
            myLocationButton.tintColor = tintColor
            mapTypeSelectButton.tintColor = tintColor
            
            arrowButton.backgroundColor = backgroundColor
            myLocationButton.backgroundColor = backgroundColor
            mapTypeSelectButton.backgroundColor = backgroundColor
            
            toolBar.barTintColor = UIColor(hexString: K.colors.primaryColor)
            saveButton.tintColor = UIColor.flatGreen()
            toolBar.tintColor = UIColor(hexString: K.colors.fifthColor)
            selectAllButton.tintColor = UIColor.flatBlue()
            
            if let navBar = navigationController?.navigationBar {
                navBar.tintColor = UIColor(hexString: K.colors.secondaryColor)
                navBar.barTintColor = UIColor(hexString: K.colors.primaryColor)//f9e0ae ffd460
            }
            if userDefault.isBatterySaveModeActive {
                mapView.preferredFrameRate = .conservative
            } else {
                mapView.preferredFrameRate = .maximum
            }
            
        }
        
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        titleTextField.isUserInteractionEnabled = true
        titleTextField.adjustsFontSizeToFitWidth = true
        groupTitleTextField.adjustsFontSizeToFitWidth = true
        
        self.view.addSubview(toolBar)
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        
        addToolBarConstraints()
        
        toolBar.isHidden = true
        
        self.mapView.delegate = self
        
        self.navigationItem.hidesBackButton = true
        
        addSubViewsConstraints()
        if  cameraPositionPath != nil {
            changeCameraPosition()
        }
        
        titleTextField.delegate = self
        groupTitleTextField.delegate = self
        
        if let userID = user?.uid {
            
            do {
                try realm.write({
                    userDefaults?.first?.bossID = userID
                    userDefaults?.first?.bossEmail = user?.email ?? ""
                })
            } catch {
                print("Error saving context, \(error)")
            }
            
        }
        
        // Get groups and fields in the realm
        fieldsController = FieldsController(mapView: mapView)
        
        // Get lines in the realm
        linesController = LinesController(mapView: mapView)
        
        // Get Places in the realm
        placesController = PlacesController(mapView: mapView)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(deleteDB), name: NSNotification.Name("deleteDB"), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name("hasNoSubscription"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(professionalSubscriptionStarted), name: NSNotification.Name("professionalSubscriptionStarted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openPremiumViewController), name: NSNotification.Name("openPremiumViewController"), object: nil)
        
        //Handle Banner
        //Production adUnitID
        bannerView.adUnitID = APIConstants.ProductionAdUnitID
        //Test adUnitID
//        bannerView.adUnitID = Constants.TestAdUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        bannerView.delegate = self
        
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: APIConstants.GADInterstitialAdUnitID1,
                               request: request,
                               completionHandler: { [self] ad, error in
                                if let error = error {
                                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                                    return
                                }
                                interstitial = ad
                                interstitial?.fullScreenContentDelegate = self
                               }
        )
        
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
    }
    
    //MARK: - hasNoSubscription
    @objc func hasNoSubscription() {
        print("hasNoSubscription")
    }
    //MARK: - professionalSubscriptionStarted
    @objc func professionalSubscriptionStarted() {
        print("professionalSubscriptionStarted")
    }
    
    //MARK: - keyboardWillShow
    @objc func keyboardWillShow(notification:NSNotification) {
        /*guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
              // if keyboard size is not available for some reason, dont do anything
              return
           }*/
         
         // move the root view up by the distance of keyboard height
        //self.addFormStackView.frame.origin.y = 0 - keyboardSize.height
        if !UIDevice.current.orientation.isPortrait {
            NSLayoutConstraint.deactivate([self.centerYConstraint])
            centerYConstraint = addFormStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -150)
            NSLayoutConstraint.activate([self.centerYConstraint])
            UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        }
      
    }
    //MARK: - openPremiumViewController
    @objc func openPremiumViewController() {
        performSegue(withIdentifier: K.segueIdentifiers.mapViewToPremiumView, sender: self)
    }
    
    //MARK: - keyboardWillHide
    @objc func keyboardWillHide(notification:NSNotification) {
        
        NSLayoutConstraint.deactivate([self.centerYConstraint])
        centerYConstraint = addFormStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: 0)
        NSLayoutConstraint.activate([self.centerYConstraint])
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        
        //addFormStackView.translatesAutoresizingMaskIntoConstraints = false
        print("keyboardWillHide")
     
    }
    //MARK: - viewWillTransition
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if !UIDevice.current.orientation.isPortrait {
            print("Device is in landscape mode")
            //addFormStackView.translatesAutoresizingMaskIntoConstraints = false
            //self.addFormStackView.frame.origin.y =  addFormStackView.frame.origin.y - 150
        } else {
            print("Device is in portrait mode")
            //addFormStackView.translatesAutoresizingMaskIntoConstraints = false
            //self.addFormStackView.frame.origin.y = addFormStackView.frame.origin.y + 150
        }
    }
    //MARK: - deleteDB
    @objc func deleteDB() {
        placesController?.placeMarkers.forEach({ (marker) in
            marker.map = nil
        })
        linesController?.polylines.forEach({ (GMSPolyline) in
            GMSPolyline.map = nil
        })
        fieldsController?.polygons.forEach({ (GMSPolygon) in
            GMSPolygon.map = nil
        })
        placesController?.placeMarkers.removeAll()
        linesController?.polylines.removeAll()
        fieldsController?.polygons.removeAll()
        
        do {
            try realm.write({
                self.realm.delete(fieldsController!.fields!)
                self.realm.delete(fieldsController!.groups!)
                self.realm.delete(linesController!.lines!)
                self.realm.delete(placesController!.places!)
            })
        } catch {
            print("Error saving context, \(error)")
        }
        
        // Get groups and fields in the realm
        fieldsController = nil
        fieldsController = FieldsController(mapView: mapView)
        
        // Get lines in the realm
        linesController = nil
        linesController = LinesController(mapView: mapView)
        
        // Get Places in the realm
        placesController = nil
        placesController = PlacesController(mapView: mapView)
        
    }
    //MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        SubscriptionsHelper.app.checkUserSubscription()
        
        if userDefaults?.first?.accountType != K.invites.accountTypes.proAccount {
            
            authenticationNavBarButton.image = UIImage(systemName: "star.circle")
            
            self.authenticationNavBarButton.tintColor = UIColor.flatYellowDark()
            
            title = K.appName
        } else {
            self.authenticationNavBarButton.image = UIImage(systemName: K.systemImages.personFillCheckmark)
            self.authenticationNavBarButton.tintColor = UIColor.flatGreenDark()
            
            title = "\(K.appName) Pro"
        }
        bannerView.isHidden = true
        if userDefaults?.first?.accountType == K.invites.accountTypes.proAccount {
            bannerView.isHidden = false
        }
        
    }
    //MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        
        _ = Auth.auth().addStateDidChangeListener { [self] (auth, user) in
            if user != nil {
                if self.userDefaults?.first?.accountType != "activeMember" {
                    
                }
            } else {
                if userDefaults?.first?.accountType == K.invites.accountTypes.proAccount {
                    
                    let alert = UIAlertController(title:NSLocalizedString("Auth info not found.", comment: "") , message: "For the usage of cloud synchronization, you need to sign in.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) {_ in
                        self.performSegue(withIdentifier: K.segueIdentifiers.goToLoginViewController, sender: self)
                    }
                    alert.addAction(okAction)
                    present(alert, animated: true)
                    
                }
            }
        }
        //self.navigationController!.navigationBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
    }
    
    //MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK: - Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        self.mapView.isMyLocationEnabled = true
    }
    //MARK: - myLocationButtonTapped
    @IBAction func myLocationButtonTapped(_ sender: UIButton) {
        let location = locationManager.location
        
        if let latitude = mapView.myLocation?.coordinate.latitude, let longitude = mapView.myLocation?.coordinate.longitude {
            let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: mapView.camera.zoom)
            self.mapView?.animate(to: camera)
        } else {
            if let latitude = location?.coordinate.latitude, let longitude = location?.coordinate.longitude{
                let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: mapView.camera.zoom)
                self.mapView?.animate(to: camera)
            }
        }
    }
    //MARK: - changeCameraPosition
    func changeCameraPosition() {
        guard let cameraPositionPath = cameraPositionPath else { return }
        mapView.animate(with: GMSCameraUpdate.fit(GMSCoordinateBounds(path: cameraPositionPath)))
        //mapView.animate(with: GMSCameraUpdate.zoomOut())
    }
    //MARK: - Marker didEndDragging
    func mapView(_ mapView: GMSMapView, didEndDragging selectedMarker: GMSMarker) {
        switch editingOverlayType {
        case .field:
            if let markers = fieldsController?.selectedFieldMarkers {
                for marker in markers {
                    marker.map = mapView
                }
                if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                    for marker in fieldsController!.selectedFieldLengthMarkers {
                        marker.map = mapView
                    }
                }
            }
        case .line:
            if let markers = linesController?.selectedLineMarkers {
                for marker in markers {
                    marker.map = mapView
                }
            }
            if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                for marker in linesController!.selectedLineLengthMarkers {
                    marker.map = mapView
                }
            }
        case .place:
            placesController?.selectedPlaceMarker.position = selectedMarker.position
            //placesController?.savePlaceToDB(place: placesController!.selectedPlace, groundOverlay: placesController!.selectedGroundOverlay)
        }
        if editingOverlayType != .place {
            positionMarker?.map = nil
            positionMarker = nil
        }
    }
    
    //MARK: - Marker didBeginDragging
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        draggingMarker = marker
        markerFirstPosition[0] = marker.position.latitude
        markerFirstPosition[1] = marker.position.longitude
        
        if editingOverlayType != .place {
            positionMarker = GMSMarker(position: marker.position)
            positionMarker?.position = marker.position
            positionMarker?.iconView = UIImage.makeIconView(iconSize: 50, lat: marker.position.latitude, lon: marker.position.longitude)
            positionMarker?.groundAnchor = .init(x: 0.5, y: 1.6)
            positionMarker?.map = mapView
        }
    }
    //MARK: - Marker didTap
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        switch editingOverlayType {
        case .field:
            var unitLength = UnitLength.centimeters
            if marker.title != "lengthMarker" {
                if let markers = fieldsController?.selectedFieldMarkers {
                    selectDeleteMarker(selectedMarker: marker, markers: markers)
                }
            } else {
                let ac = UIAlertController(title: NSLocalizedString("Enter Length", comment: ""), message: NSLocalizedString("The selected point will stay fixed and the edge will be extended.", comment: ""), preferredStyle: .alert)
                ac.addTextField()
                ac.textFields![0].keyboardType = .decimalPad
                
                let temp = UnitsHelper.app.getPlaceholderAndUnitLengthType(isMeasureSystemMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                
                ac.textFields![0].placeholder = temp.first!.key
                unitLength = temp.first!.value
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive)
                let submitAction = UIAlertAction(title: NSLocalizedString("Submit", comment: ""), style: .default) { [self, unowned ac] _ in
                    if let length = Double(ac.textFields![0].text!) {
                        var dragedMarker: GMSMarker?
                        if userDefaults!.first!.isMeasureSystemMetric {
                            let lengthWithUnit = Measurement.init(value: length, unit: unitLength)
                            dragedMarker = fieldsController!.setEdgeLength(lengthMarkerIndex: fieldsController!.selectedFieldLengthMarkers.firstIndex(of: marker)!, edgeLength: lengthWithUnit.converted(to: UnitLength.meters).value)
                        } else {
                            let lengthWithUnit = Measurement.init(value: length, unit: unitLength)
                            dragedMarker = fieldsController!.setEdgeLength(lengthMarkerIndex: fieldsController!.selectedFieldLengthMarkers.firstIndex(of: marker)!, edgeLength: lengthWithUnit.converted(to: UnitLength.meters).value)
                        }
                        if let draggedMarker = dragedMarker {
                            markerDidDrag(didDrag: draggedMarker, isDraggedByCalculation: true)
                        }
                    }
                }
                ac.addAction(cancelAction)
                ac.addAction(submitAction)
                present(ac, animated: true)
            }
        case .line:
            if marker.title != "lengthMarker" {
                if let markers = linesController?.selectedLineMarkers {
                    selectDeleteMarker(selectedMarker: marker, markers: markers)
                }
            } else {
                var unitLength = UnitLength.centimeters
                let ac = UIAlertController(title: NSLocalizedString("Enter Length", comment: ""), message: NSLocalizedString("The selected point will be kept fixed and the edge will be extended", comment: ""), preferredStyle: .alert)
                ac.addTextField()
                ac.textFields![0].keyboardType = .decimalPad
                
                let temp = UnitsHelper.app.getPlaceholderAndUnitLengthType(isMeasureSystemMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                
                ac.textFields![0].placeholder = temp.first!.key
                unitLength = temp.first!.value
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive)
                let submitAction = UIAlertAction(title: NSLocalizedString("Submit", comment: ""), style: .default) { [self, unowned ac] _ in
                    if let length = Double(ac.textFields![0].text!) {
                        var dragedMarker: GMSMarker?
                        if userDefaults!.first!.isMeasureSystemMetric {
                            let lengthWithUnit = Measurement.init(value: length, unit: unitLength)
                            dragedMarker = linesController!.setEdgeLength(lengthMarkerIndex: linesController!.selectedLineLengthMarkers.firstIndex(of: marker)!, edgeLength: lengthWithUnit.converted(to: UnitLength.meters).value)
                        } else {
                            let lengthWithUnit = Measurement.init(value: length, unit: unitLength)
                            dragedMarker = linesController!.setEdgeLength(lengthMarkerIndex: linesController!.selectedLineLengthMarkers.firstIndex(of: marker)!, edgeLength: lengthWithUnit.converted(to: UnitLength.meters).value)
                        }
                        if let draggedMarker = dragedMarker {
                            markerDidDrag(didDrag: draggedMarker, isDraggedByCalculation: true)
                        }
                    }
                }
                ac.addAction(cancelAction)
                ac.addAction(submitAction)
                present(ac, animated: true)
            }
        case .place:
            editingOverlayType = .place
            editPlace(placeMarker: marker)
        }
        return true
    }
    //MARK: - selectDeleteMarker
    func selectDeleteMarker(selectedMarker: GMSMarker, markers: [GMSMarker]){
        
        if selectedMarker.title == "delete" {
            let alert = UIAlertController(title: NSLocalizedString("Enter Coordinates", comment: ""), message: "", preferredStyle: .alert)
            alert.addTextField()
            alert.textFields![0].keyboardType = .decimalPad
            alert.textFields![0].text = String(format: "%.4f", selectedMarker.position.latitude)
            alert.textFields![0].clearButtonMode = .always
            alert.textFields![0].borderStyle = .roundedRect
            
            //let iconView = UIImageView(frame: CGRect(x: 10, y: 5, width: 20, height: 20))
            //iconView.image = image
            //let iconContainerView: UIView = UIView(frame: CGRect(x: 20, y: 0, width: 30, height: 30))
            //iconContainerView.addSubview(iconView)
            //leftView = iconContainerView
            //leftViewMode = .always
            
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            label.text = NSLocalizedString("Lat", comment: "")
            
            alert.textFields![0].leftView = label
            //alert.textFields![0].leftView?.addSubview(label)
            alert.textFields![0].leftViewMode = .always
            alert.textFields![0].leftViewRect(forBounds: CGRect(x: alert.textFields![0].bounds.midX, y: alert.textFields![0].bounds.midY, width: 0, height: 0))
            
            
            alert.addTextField()
            alert.textFields![1].keyboardType = .decimalPad
            alert.textFields![1].text = String(format: "%.4f",selectedMarker.position.longitude)
            alert.textFields![1].clearButtonMode = .always
            alert.textFields![1].borderStyle = .roundedRect
            
            let label1 = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            
            label1.text = NSLocalizedString("Lon", comment: "")
            alert.textFields![1].leftView = label1
            //alert.textFields![0].leftView?.addSubview(label)
            alert.textFields![1].leftViewMode = .always
            alert.textFields![1].leftViewRect(forBounds: CGRect(x: alert.textFields![1].bounds.midX, y: alert.textFields![1].bounds.midY, width: 0, height: 0))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Submit", comment: ""), style: .default, handler: { (uiAlertAction) in
                if let latText = alert.textFields![0].text, let lonText = alert.textFields![1].text {
                    
                    if let lat = Double(latText) {
                        print(lat)
                        selectedMarker.position.latitude = lat
                        
                    }
                    
                    if let lon = Double(lonText) {
                        print(lon)
                        selectedMarker.position.longitude = lon
                    }
                    
                }
                self.markerDidDrag(didDrag: selectedMarker, isDraggedByCalculation: true)
                print(selectedMarker.position.latitude)
                print(selectedMarker.position.longitude)
            }))
            present(alert, animated: true, completion: nil)
        }
        
        if editingOverlayType != .place {
            for marker in markers {
                marker.icon = UIImage(systemName: K.systemImages.dotCircle)?.imageScaled(to: CGSize(width: 30, height: 30))
             
                marker.title = "notDelete"
            }
            selectedMarker.icon = UIImage(systemName: K.systemImages.circleFill)?.imageScaled(to: CGSize(width: 30, height: 30))

            selectedMarker.title = "delete"
        }
        
        switch editingOverlayType {
        case .field:
            if let marker = markers.firstIndex(of: selectedMarker) {
                fieldsController!.setEditableSelectedFieldLengthMarker(index: marker)
            }
        case .line:
            if let marker = markers.firstIndex(of: selectedMarker) {
                linesController!.setEditableSelectedLineLengthMarker(index: marker)
            }
        case .place:
            break
        }
    }
    //MARK: - Marker didDrag
    func mapView(_ mapView: GMSMapView, didDrag selectedMarker: GMSMarker) {
        markerDidDrag(didDrag: selectedMarker, isDraggedByCalculation: false)
    }
    //MARK: - markerDidDrag
    func markerDidDrag( didDrag selectedMarker: GMSMarker,isDraggedByCalculation: Bool) {
        
        if editingOverlayType != .place {
            positionMarker?.position = selectedMarker.position
            positionMarker?.iconView = UIImage.makeIconView(iconSize: 50, lat: selectedMarker.position.latitude, lon: selectedMarker.position.longitude)
            positionMarker?.groundAnchor = .init(x: 0.5, y: 1.6)
            positionMarker?.map = mapView
        }
        
        let rect = GMSMutablePath()
        
        var markers = [GMSMarker]()
        
        switch editingOverlayType {
        case .field:
            markers = fieldsController!.selectedFieldMarkers
        case .line:
            markers = linesController!.selectedLineMarkers
        case .place:
            break
        }
        
        for marker in markers {
            rect.add(marker.position)
        }
       
        if editingOverlayType == .place {
            
            placesController?.selectedPlaceMarker.position = CLLocationCoordinate2D(latitude: selectedMarker.position.latitude, longitude: selectedMarker.position.longitude)
            
        } else if selectAllButton.image == UIImage(systemName: K.systemImages.circleGrid3x3Fill) || isDraggedByCalculation {
            
            rect.replaceCoordinate(at: UInt(markers.firstIndex(of: selectedMarker) ?? 0), with: CLLocationCoordinate2D(latitude: selectedMarker.position.latitude, longitude: selectedMarker.position.longitude))
            if editingOverlayType == .field {
                if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                    fieldsController!.arrangeSelectedFieldLengthMarker(i: fieldsController!.selectedFieldMarkers.firstIndex(of: selectedMarker)!, inside: true, add: false, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                }
            } else if editingOverlayType == .line {
                if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                    if (linesController!.selectedLineMarkers.firstIndex(of: selectedMarker)! != 0) && (linesController!.selectedLineMarkers.firstIndex(of: selectedMarker)! != linesController!.selectedLineMarkers.count - 1) {
                        linesController!.arrangeSelectedLineLengthMarker(i: linesController!.selectedLineMarkers.firstIndex(of: selectedMarker)!, inside: true, add: false, mapView: mapView, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                    } else {
                        linesController!.arrangeSelectedLineLengthMarker(i: linesController!.selectedLineMarkers.firstIndex(of: selectedMarker)!, inside: false, add: false, mapView: mapView, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                    }
                }
            }
        } else {
            
            let latitudeDifference = selectedMarker.position.latitude - markerFirstPosition[0]
            let longitudeDifference = selectedMarker.position.longitude - markerFirstPosition[1]
            
            for marker in markers {
                if marker != selectedMarker {
                    marker.map = nil
                    marker.position.latitude += latitudeDifference
                    marker.position.longitude += longitudeDifference
                    
                    rect.replaceCoordinate(at: UInt(markers.firstIndex(of: marker) ?? 0), with: CLLocationCoordinate2D(latitude: marker.position.latitude, longitude: marker.position.longitude))
                }
            }
            if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                if editingOverlayType == .field {
                    for marker in fieldsController!.selectedFieldLengthMarkers {
                        marker.map = nil
                        marker.position.latitude += latitudeDifference
                        marker.position.longitude += longitudeDifference
                        
                    }
                } else if editingOverlayType == .line {
                    for marker in linesController!.selectedLineLengthMarkers {
                        marker.map = nil
                        marker.position.latitude += latitudeDifference
                        marker.position.longitude += longitudeDifference
                        
                    }
                }
            }
            markerFirstPosition[0] = selectedMarker.position.latitude
            markerFirstPosition[1] = selectedMarker.position.longitude
        }
        switch editingOverlayType {
        case .field:
            fieldsController?.selectedPolygon.path = rect
            fieldsController?.selectedPolygon.map = mapView
            areaLabelSet()
        case .line:
            linesController?.selectedPolyline.path = rect
            linesController?.selectedPolyline.map = mapView
            areaLabelSet()
        case .place:
            areaLabelSet()
        }
    }
   
    //MARK: - Overlay didTap
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        nc.addObserver(self, selector: #selector(endEditing), name: Notification.Name("EndEditing"), object: nil)
        
        if overlay.isKind(of: GMSPolygon.self) {
            editField(polygon: overlay as! GMSPolygon)
        } else if overlay.isKind(of: GMSPolyline.self) {
            editLine(polyline: overlay as! GMSPolyline)
        }
    }
    //MARK: - editField
    func editField(polygon: GMSPolygon) {
        //overlay as! GMSPolygon
        editingOverlayType = .field
        plusButton.isEnabled = false
        plusButton.image = UIImage()
        minusButton.image = UIImage(systemName: K.systemImages.pipRemove)
        selectAllButton.isEnabled = true
        selectAllButton.image = UIImage(systemName: K.systemImages.circleGrid3x3Fill)
        
        fieldsController?.selectedField = realm.object(ofType: Field.self, forPrimaryKey: polygon.title)!
        fieldsController?.selectedPolygon = polygon
        
        if let color = fieldsController?.selectedField.color {
            self.colorBarButtonItem.tintColor = UIColor(hexString: color)
        }
        
        if !isInitialState {
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("For  %@", comment: ""), fieldsController!.selectedField.title), message: "", preferredStyle: .actionSheet)
            
            
       
            let titleAttributes = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 25)!, NSAttributedString.Key.foregroundColor: UIColor.black]
            let titleString = NSAttributedString(string: String(format: NSLocalizedString("For %@", comment: ""), fieldsController!.selectedField.title), attributes: titleAttributes)
            //let messageAttributes = [NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 17)!, NSAttributedString.Key.foregroundColor: UIColor.red]
            //let messageString = NSAttributedString(string: "Company name", attributes: messageAttributes)
            alert.setValue(titleString, forKey: "attributedTitle")
            //alert.setValue(messageString, forKey: "attributedMessage")
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Edit field overlay", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.editFieldMapActions()
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Edit items", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.performSegue(withIdentifier: K.segueIdentifiers.goToItemsFromMapView, sender: self)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Open info page", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.performSegue(withIdentifier: K.segueIdentifiers.mapViewToInfoView, sender: self)
            }))
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive, handler: nil))
                
                if let popoverController = alert.popoverPresentationController {
                    popoverController.sourceView = self.view //to set the source of your alert
                    popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
                }
                
            }
            
            present(alert, animated: true, completion: nil)
        } else {
            editFieldMapActions()
        }
    }
    //MARK: - editMapActions
    func editFieldMapActions() {
        hideView(view: bannerView, hidden: true)
        //self.navBar.title = self.selectedFieldTitle
        self.hideView(view: toolBar, hidden: false)
        hideView(view: areaLabel, hidden: false)
        
        tappableSettings(to: false)
        
        for marker in fieldsController!.selectedFieldMarkers {
            marker.title = "notDelete"
            
            marker.map = mapView
        }
        
        self.hideView(view: self.arrowButton, hidden: true)
        
        areaLabelSet()
        
        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
            fieldsController!.setSelectedFieldLengthMarkers(isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
            fieldsController!.setHideSelectedFieldLengthMarkers(mapView: mapView, remove: true)
        }
        
        timer = Timer.scheduledTimer(timeInterval: K.freeAccountLimitations.toolBarTimer, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
    }
    
    //MARK: - editLine
    func editLine(polyline: GMSPolyline) {
        editingOverlayType = .line
        //overlay as! GMSPolyline
        plusButton.isEnabled = false
        plusButton.image = UIImage()
        minusButton.image = UIImage(systemName: K.systemImages.pipRemove)
        selectAllButton.isEnabled = true
        selectAllButton.image = UIImage(systemName: K.systemImages.circleGrid3x3Fill)
        
        //self.selectedLineTitle = overlay.title ?? "1"
        if let line = linesController?.lines?.first(where: {$0.id == polyline.title}) {
            linesController?.selectedLine = line
        }
        
        if !isInitialState {
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("For %@", comment: ""), linesController!.selectedLine.title), message: "", preferredStyle: .actionSheet)
       
            let titleAttributes = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 25)!, NSAttributedString.Key.foregroundColor: UIColor.black]
            let titleString = NSAttributedString(string: String(format: NSLocalizedString("For %@", comment: ""), linesController!.selectedLine.title), attributes: titleAttributes)
            //let messageAttributes = [NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 17)!, NSAttributedString.Key.foregroundColor: UIColor.red]
            //let messageString = NSAttributedString(string: "Company name", attributes: messageAttributes)
            alert.setValue(titleString, forKey: "attributedTitle")
            //alert.setValue(messageString, forKey: "attributedMessage")
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Edit line overlay", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.editLineMapActions()
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Edit items", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.performSegue(withIdentifier: K.segueIdentifiers.goToItemsFromMapView, sender: self)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Open info page", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.performSegue(withIdentifier: K.segueIdentifiers.mapViewToInfoView, sender: self)
            }))
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive, handler: nil))
                
                if let popoverController = alert.popoverPresentationController {
                    popoverController.sourceView = self.view //to set the source of your alert
                    popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
                }
                
            }
            
            present(alert, animated: true, completion: nil)
        } else {
            editLineMapActions()
        }
    }
    //MARK: - editLineMapActions
    func editLineMapActions() {
        
        if let color = linesController?.selectedLine.color {
            self.colorBarButtonItem.tintColor = UIColor(hexString: color)
        }
        
        //self.navBar.title = self.selectedLineTitle
        hideView(view: bannerView, hidden: true)
        self.hideView(view: toolBar, hidden: false)
        hideView(view: areaLabel, hidden: false)
        
        
        tappableSettings(to: false)
        
        for marker in linesController!.selectedLineMarkers {
            marker.title = "notDelete"
            marker.map = mapView
        }
        
        self.hideView(view: self.arrowButton, hidden: true)
        
        areaLabelSet()
        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
            linesController!.setSelectedLineLengthMarkers(isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
            linesController!.setHideSelectedLineLengthMarkers(mapView: mapView, remove: true)
        }
        
        timer = Timer.scheduledTimer(timeInterval: K.freeAccountLimitations.toolBarTimer, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
    }
    //MARK: - editPlace
    func editPlace(placeMarker: GMSMarker) {
        editingOverlayType = .place
        minusButton.image = UIImage()
        //minusButton.image = UIImage(systemName: K.systemImages.minusCircleFill)
        plusButton.isEnabled = true
        plusButton.image = UIImage()
        //plusButton.image = UIImage(systemName: K.systemImages.plusCircleFill)
        selectAllButton.isEnabled = false
        selectAllButton.image = UIImage()
        
        placeMarker.isDraggable = true
        
        
        if let place = placesController!.places!.first(where: {$0.id == placeMarker.title}) {
            placesController?.selectedPlace = place
        }
        
        if !isInitialState {
            
            
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("For %@", comment: ""), linesController!.selectedLine.title) , message: "", preferredStyle: .actionSheet)
       
            let titleAttributes = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 25)!, NSAttributedString.Key.foregroundColor: UIColor.black]
            let titleString = NSAttributedString(string: String(format: NSLocalizedString("For %@", comment: ""), placesController!.selectedPlace.title), attributes: titleAttributes)
            //let messageAttributes = [NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 17)!, NSAttributedString.Key.foregroundColor: UIColor.red]
            //let messageString = NSAttributedString(string: "Company name", attributes: messageAttributes)
            alert.setValue(titleString, forKey: "attributedTitle")
            //alert.setValue(messageString, forKey: "attributedMessage")
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Edit place overlay", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.editPlaceMapActions()
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Edit items", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.performSegue(withIdentifier: K.segueIdentifiers.goToItemsFromMapView, sender: self)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Open info page", comment: ""), style: .default, handler: { (uiAlertAction) in
                self.performSegue(withIdentifier: K.segueIdentifiers.mapViewToInfoView, sender: self)
            }))
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive, handler: nil))
                
                if let popoverController = alert.popoverPresentationController {
                    popoverController.sourceView = self.view //to set the source of your alert
                    popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
                }
                
            }
            
            present(alert, animated: true, completion: nil)
        } else {
            editPlaceMapActions()
        }
    }
    //MARK: - editPlaceMapActions
    func editPlaceMapActions() {
        hideView(view: bannerView, hidden: true)
        self.hideView(view: self.arrowButton, hidden: true)
        self.hideView(view: toolBar, hidden: false)
        
        tappableSettings(to: false)
        
        areaLabelSet()
        hideView(view: areaLabel, hidden: false)
        
        if let color = placesController?.selectedPlace.color {
            self.colorBarButtonItem.tintColor = UIColor(hexString: color)
        }
        
        let moveMarker = GMSMarker(position: (placesController?.selectedPlaceMarker.position)!)
        moveMarker.isDraggable = true
        moveMarker.isTappable = true
        moveMarker.icon = UIImage.init(systemName: K.systemImages.circleFill)!.imageScaled(to: CGSize(width: 100, height: 100))
        moveMarker.groundAnchor = CGPoint(x: 0.5, y: 0)
        moveMarker.opacity = 0
        draggingMarker = moveMarker
        draggingMarker.map = mapView
        
        timer = Timer.scheduledTimer(timeInterval: K.freeAccountLimitations.toolBarTimer, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
    }
    
    //MARK: - areaLabelSet
    func areaLabelSet() {
        
        switch editingOverlayType {
        case .field:
            
            // Field area calculation
            fieldsController?.setAreaAndCircumference()
            areaLabel.text = String(format: NSLocalizedString(" Field: %@ ", comment: ""), fieldsController!.selectedField.title) + "\n"
            let area = Measurement(value: fieldsController!.updatedArea, unit: UnitArea.squareMeters)
            let circumference = Measurement(value: fieldsController!.updatedCircumference, unit: UnitLength.meters)
            
            areaLabel.text! += UnitsHelper.app.getUnitForField(isShowAllUnitsSelected: userDefaults!.first!.isShowAllUnitsSelected, isMeasureSystemMetric: userDefaults!.first!.isMeasureSystemMetric, area: area, circumference: circumference, distanceUnit: userDefaults!.first!.distanceUnit, areaUnit: userDefaults!.first!.areaUnit)
            
        case .line:
            // line length calculation
            areaLabel.text = String(format: NSLocalizedString(" Line: %@ ", comment: ""), linesController!.selectedLine.title) + "\n"
            let length = Measurement(value: GMSGeometryLength((linesController!.selectedPolyline.path)!), unit: UnitLength.meters)
            
            areaLabel.text! += UnitsHelper.app.getUnitForLine(isShowAllUnitsSelected: userDefaults!.first!.isShowAllUnitsSelected, isMeasureSystemMetric: userDefaults!.first!.isMeasureSystemMetric, length: length, distanceUnit: userDefaults!.first!.distanceUnit)
            
            linesController?.setSelectedLineLength(length: GMSGeometryLength((linesController?.selectedPolyline.path)!))
        case .place:
            // Place Location
            
            areaLabel.text = String(format: NSLocalizedString(" Place: %@", comment: ""), placesController!.selectedPlace.title) + "\n" +
                NSLocalizedString(" Lat:", comment: "") + " \(String(format: "%.5f", placesController!.selectedPlaceMarker.position.latitude))" + "\n" +
                NSLocalizedString(" Lon:", comment: "") + " \(String(format: "%.5f", placesController!.selectedPlaceMarker.position.longitude))"
        }
    }
    //MARK: - tapableSettings
    func tappableSettings(to tapable: Bool) {
        fieldsController?.changePolygonsTappableBoolean(to: tapable)
        linesController?.changePolylinesTappableBoolean(to: tapable)
        placesController?.changeGroundOverlayTappableBoolean(to: tapable)
    }
    
    //MARK: - Prepare for seque
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case K.segueIdentifiers.goToItemsFromMapView:
            
            let destinationVC = segue.destination as! ToDoListViewController
            
            switch editingOverlayType {
            case .field:
                destinationVC.selectedGroup = fieldsController?.selectedField.parentGroup.first
                destinationVC.selectedField = fieldsController?.selectedField
            case .line:
                destinationVC.selectedLine = linesController?.selectedLine
            case .place:
                destinationVC.selectedPlace = placesController?.selectedPlace
            }
            
        case K.segueIdentifiers.infoView:
            let destinationVC = segue.destination as! FieldListViewController
            destinationVC.selectedGroup = fieldsController?.selectedField.parentGroup.first
            destinationVC.fieldsController = fieldsController
            destinationVC.isMetric = userDefaults?.first?.isMeasureSystemMetric
            
        case K.segueIdentifiers.goToGroups:
            let destinationVC = segue.destination as! GroupListViewController
            destinationVC.fieldsController = fieldsController
            
        case K.segueIdentifiers.goToLines:
            let destinationVC = segue.destination as! LineListViewController
            destinationVC.linesController = linesController
            
        case K.segueIdentifiers.goToPlaces:
            let destinationVC = segue.destination as! PlaceListViewController
            destinationVC.placesController = placesController
            
        case K.segueIdentifiers.goToAuthViewController:
            let destinationVC = segue.destination as! AuthViewController
            destinationVC.fieldsController = fieldsController
            destinationVC.linesController = linesController
            destinationVC.placesController = placesController
            
        case K.segueIdentifiers.mapViewToInfoView:
            let destinationVC = segue.destination as! InfoViewController
            
            switch editingOverlayType {
            case .field:
                destinationVC.selectedField = fieldsController?.selectedField
            case .line:
                destinationVC.selectedLine = linesController?.selectedLine
            case .place:
                destinationVC.selectedPlace = placesController?.selectedPlace
            }
            
        default:
            break
        }
        
    }
    
    //MARK: - addButtonTapped
    @IBAction func addButtonTapped(_ sender: UIButton?) {
        titleTextField.resignFirstResponder()
        groupTitleTextField.resignFirstResponder()
        var errorMessage = ""
        if let title = titleTextField.text {
            switch addType {
            case .field:
                addType = .field
                if let groupTitle = groupTitleTextField.text {
                    errorMessage = (fieldsController?.checkTitleAvailable(title: title, groupTitle: groupTitle))!
                }
            case .line:
                errorMessage = (linesController?.checkTitleAvailable(title: title))!
                addType = .line
            case .place:
                errorMessage = (placesController?.checkTitleAvailable(title: title))!
                addType = .place
            }
        }
        if errorMessage != "done" {
            errorAlert(errorMessage: errorMessage)
            isInitialState = false
            hideView(view: arrowButton, hidden: false)
            self.navigationController?.navigationBar.isHidden = false
        } else {
            hideView(view: arrowButton, hidden: true)
            isInitialState = true
            initialMarkers.removeAll()
            self.navigationController?.navigationBar.isHidden = true
            switch addType {
            case .field:
                hideView(view: areaLabel, hidden: false)
                areaLabel.text = NSLocalizedString("Please select 3 points on the map.", comment: "")
            case .line:
                hideView(view: areaLabel, hidden: false)
                areaLabel.text = NSLocalizedString("Please select 2 points on the map.", comment: "")
            case .place:
                hideView(view: areaLabel, hidden: false)
                areaLabel.text = NSLocalizedString("Please select place's point on the map.", comment: "")
            }
        }
        addFormStackView.isHidden = true
    }
    //MARK: - errorAlert
    func errorAlert(errorMessage: String) {
        let alert = UIAlertController(title: errorMessage, message: "", preferredStyle: .alert)
        let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel)
        alert.addAction(editItemsAction)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - arrowButtonTapped
    @IBAction func arrowButtonTapped(_ sender: UIButton) {
        hideView(view: arrowButton, hidden: true, transitionOption: .transitionFlipFromRight)
        hideView(view: addStackView, hidden: false, transitionOption: .transitionFlipFromRight)
        tappableSettings(to: false)
    }
    //MARK: - addFieldButtonTapped
    @IBAction func addFieldButtonTapped(_ sender: UIButton) {
        
        if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
            if let fieldCount = fieldsController?.fields?.count {
                
                if fieldCount >= K.freeAccountLimitations.overlayLimit {
                    AlertsHelper.addingExtraFieldAlert(on: self)
                    return
                }
            }
        }
        
        hideView(view: addStackView, hidden: true)
        hideView(view: addFormStackView, hidden: false)
        hideView(view: groupTitleTextField, hidden: false)
        addType = .field
    }
    //MARK: - addLineButtonTapped
    @IBAction func addLineButtonTapped(_ sender: UIButton) {
        
        if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
            if let lineCount = linesController?.lines?.count {
                
                if lineCount >= K.freeAccountLimitations.overlayLimit {
                    AlertsHelper.addingExtraLineAlert(on: self)
                    return
                }
            }
        }
        
        hideView(view: addStackView, hidden: true)
        colorButton.setTitle(NSLocalizedString("Color", comment: ""), for: .normal)
        hideView(view: addFormStackView, hidden: false)
        hideView(view: groupTitleTextField, hidden: true)
        addType = .line
    }
    //MARK: - addPlaceButtonTapped
    @IBAction func addPlaceButtonTapped(_ sender: UIButton) {
        
        if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
            if let placeCount = placesController?.places?.count {
                
                if placeCount >= K.freeAccountLimitations.overlayLimit {
                    AlertsHelper.addingExtraPlaceAlert(on: self)
                    return
                }
            }
        }
        
        hideView(view: addStackView, hidden: true)
        colorButton.setTitle(NSLocalizedString("Color", comment: ""), for: .normal)
        hideView(view: addFormStackView, hidden: false)
        hideView(view: groupTitleTextField, hidden: true)
        addType = .place
    }
    
    //MARK: - cancelButtonTapped
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        titleTextField.resignFirstResponder()
        groupTitleTextField.resignFirstResponder()
        hideView(view: arrowButton, hidden: false)
        hideView(view: addFormStackView, hidden: true)
        hideView(view: colorsCollectionView, hidden: true)
        tappableSettings(to: true)
        hideView(view: colorsCollectionView, hidden: true)
    }
    //MARK: - hideView
    func hideView(view: UIView, hidden: Bool, transitionOption: UIView.AnimationOptions = .transitionCrossDissolve) {
        UIView.transition(with: view, duration: 0.5, options: transitionOption, animations: {
            view.isHidden = hidden
        })
    }
    
    //MARK: - mapTypeSelectButtonTapped
    @IBAction func mapTypeSelectButtonTapped(_ sender: UIButton) {
        hideView(view: mapTypeSelectButton, hidden: true)
        hideView(view: mapTypeStackView, hidden: false)
    }
    @IBAction func mapTypeNormalButtonTapped(_ sender: UIButton) {
        
        let asd = OverlayView()
        asd.mapView = mapView
        asd.setMapStyle(to: MapStylesHelper.standard)
        
        mapView.mapType = .normal
        writeUserDefaultsToRealm(mapType: K.mapTypes.normal)
        hideView(view: mapTypeSelectButton, hidden: false)
        hideView(view: mapTypeStackView, hidden: true)
    }
    @IBAction func mapTypeSataliteButtonTapped(_ sender: UIButton) {
        mapView.mapType = .satellite
        writeUserDefaultsToRealm(mapType: K.mapTypes.satellite)
        hideView(view: mapTypeSelectButton, hidden: false)
        hideView(view: mapTypeStackView, hidden: true)
    }
    @IBAction func mapTypeTerrainButtonTapped(_ sender: UIButton) {
        mapView.mapType = .terrain
        writeUserDefaultsToRealm(mapType: K.mapTypes.terrain)
        hideView(view: mapTypeSelectButton, hidden: false)
        hideView(view: mapTypeStackView, hidden: true)
    }
    @IBAction func customButtonTapped(_ sender: UIButton) {
        writeUserDefaultsToRealm(mapType: K.mapTypes.custom)
        hideView(view: mapTypeSelectButton, hidden: false)
        hideView(view: mapTypeStackView, hidden: true)
        writeUserDefaultsToRealm(mapType: K.mapTypes.custom)
        showMiracle()
    }
    
    
    @objc func showMiracle() {
        let slideVC = OverlayView()
        slideVC.modalPresentationStyle = .custom
        slideVC.transitioningDelegate = self
        slideVC.mapView = mapView
        self.present(slideVC, animated: true, completion: nil)
        
    }
    
    //MARK: - writeUserDefaultsToRealm
    func writeUserDefaultsToRealm(mapType: String) {
        if let userDefault = userDefaults?.first {
            do {
                try realm.write({
                    userDefault.mapType = mapType
                    realm.add(userDefault)
                })
            } catch {
                print(K.errorSavingContext + "\(error)")
            }
        }
    }
    //MARK: - colorButtonTapped
    @IBAction func colorButtonTapped(_ sender: UIButton) {
        
        colorsCollectionView.rightAnchor.constraint(equalTo: addFormStackView.leftAnchor , constant: -5).isActive = true
        colorsCollectionView.centerYAnchor.constraint(equalTo: addFormStackView.centerYAnchor , constant: 0).isActive = true
        colorsCollectionView.widthAnchor.constraint(equalToConstant: 135).isActive = true
        colorsCollectionView.heightAnchor.constraint(equalToConstant: 175).isActive = true
        colorsCollectionView.backgroundColor = UIColor.flatWhiteDark()
        view.bringSubviewToFront(colorsCollectionView)
        
        hideView(view: colorsCollectionView, hidden: false)
    }
    
    @IBAction func authenticationButtonTapped(_ sender: UIBarButtonItem) {
       
        _ = Auth.auth().addStateDidChangeListener { [self] (auth, user) in
            if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
                performSegue(withIdentifier: K.segueIdentifiers.mapViewToPremiumView, sender: self)
            } else {
                if user != nil {
                    performSegue(withIdentifier: K.segueIdentifiers.goToAuthViewController, sender: self)
                } else {
                    performSegue(withIdentifier: K.segueIdentifiers.goToLoginViewController, sender: self)
                }
            }
        }
        
    }
    
    //MARK: - didTapMenu
    @IBAction func didTapMenu(_ sender: UIBarButtonItem) {

        guard let menuViewController = storyboard?.instantiateViewController(withIdentifier: "MenuViewController") as? MenuViewController else { return }
        menuViewController.didTapMenuType = { MenuType in
            switch MenuType {
            case .fields:
                self.selectSegue(segueIdentifier: K.segueIdentifiers.infoView)
            case .groups:
                self.selectSegue(segueIdentifier: K.segueIdentifiers.goToGroups)
            case .lines:
                self.selectSegue(segueIdentifier: K.segueIdentifiers.goToLines)
            case .places:
                self.selectSegue(segueIdentifier: K.segueIdentifiers.goToPlaces)
            case .settings:
                self.selectSegue(segueIdentifier: K.segueIdentifiers.goToSettings)
            case .importFile:
                let alert = UIAlertController(title: NSLocalizedString("Import/Export File", comment: ""), message: NSLocalizedString("Do you want to import file or export file?", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Import", comment: ""), style: .default, handler: { (action) in
                    self.importFile()
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Export", comment: ""), style: .default, handler: { (action) in
                    self.exportFileType()
                }))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            default:
                break
            }
        }
        menuViewController.modalPresentationStyle = .overCurrentContext
        menuViewController.transitioningDelegate = self
        present(menuViewController, animated: true)
    }
    
    func selectSegue(segueIdentifier: String) {
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
}
//MARK: - UIViewControllerTransitioningDelegate
extension MapViewController: UIViewControllerTransitioningDelegate {
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     segue.destination.transitioningDelegate = self
     }*/
    //menu
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = true
        return transition
    }
    //menu
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = false
        return transition
    }
    //ovarlayView
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
}

//MARK: - UICollectionViewDataSource
extension MapViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 24 // How many cells to display
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.backgroundColor = colors[indexPath[1]]
        myCell.layer.cornerRadius = 10.0
        //print(indexPath[1])
        return myCell
    }
}
//MARK: - UICollectionViewDelegate
extension MapViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print("User tapped on item \(indexPath.row)")
        colorButton.backgroundColor = colors[indexPath.row]
        colorBarButtonItem.tintColor = colors[indexPath.row]
        hideView(view: colorsCollectionView, hidden: true)
        hideView(view: colorsCollectionView1, hidden: true)
        if toolBar.isHidden == false {
            switch editingOverlayType {
            case .field:
                if fieldsController?.selectedField.parentGroup.first?.id == fieldsController?.grouplessGroupID {
                    fieldsController?.setColor(color: colors[indexPath.row].hexValue(), field: fieldsController!.selectedField)
                } else {
                    if let tempGroup = fieldsController!.selectedField.parentGroup.first {
                        if let color = colorButton.backgroundColor?.hexValue() {
                            if tempGroup.color != color {
                                fieldsController?.changeGroupColor(group: tempGroup, color: color)
                                fieldsController?.changeGroupColorAtCloud(group: tempGroup, color: color)
                            }
                        }
                    }
                }
            case .line:
                linesController?.setColor(color: colors[indexPath.row].hexValue(), line: linesController!.selectedLine, mapView: mapView)
            case .place:
                placesController!.setColor(color: colors[indexPath.row].hexValue(), place: placesController!.selectedPlace, mapView: mapView)
            }
        }
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension MapViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 25, height: 25)
    }
}

extension MapViewController{
    
    //MARK: - trashButtonTapped
    @IBAction func trashButtonTapped(_ sender: UIBarButtonItem) {
        switch editingOverlayType {
        case .field:
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Delete %@", comment: ""), fieldsController!.selectedField.title), message: NSLocalizedString("Field's overlay, to-do items and photos will be deleted.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { [self] (uiAlertAction) in
                if userDefaults?.first?.accountType == K.invites.accountTypes.proAccount {
                    fieldsController?.deleteFieldFromCloud(field: fieldsController!.selectedField)
                }
                fieldsController?.deleteFieldFromDB(field: fieldsController!.selectedField)
                endEditing()
                if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
                    hideView(view: bannerView, hidden: false)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
        case .line:
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Delete %@", comment: ""), linesController!.selectedLine.title), message: NSLocalizedString("Line's overlay, to-do items and photos will be deleted.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { [self] (uiAlertAction) in
                linesController?.deleteLineFromCloud(line: linesController!.selectedLine)
                linesController?.deleteSelectedLineFromDB(line: linesController!.selectedLine)
                endEditing()
                if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
                    hideView(view: bannerView, hidden: false)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
        case .place:
            
            let alert = UIAlertController(title: String(format: NSLocalizedString("Delete %@", comment: ""), placesController!.selectedPlace.title), message: NSLocalizedString("Place's overlay, to-do items and photos will be deleted.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { [self] (uiAlertAction) in
                placesController!.deletePlaceFromCloud(place: placesController!.selectedPlace)
                placesController!.deletePlaceFromDB(place: placesController!.selectedPlace)
                endEditing()
                if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
                    hideView(view: bannerView, hidden: false)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
        }
    }
    //MARK: - colorBarButtonItemTapped
    @IBAction func colorBarButtonItemTapped(_ sender: UIBarButtonItem) {
        colorsCollectionView1.centerYAnchor.constraint(equalTo: view.bottomAnchor , constant: -155).isActive = true
        colorsCollectionView1.centerXAnchor.constraint(equalTo: view.centerXAnchor , constant: 0).isActive = true
        colorsCollectionView1.widthAnchor.constraint(equalToConstant: 135).isActive = true
        colorsCollectionView1.heightAnchor.constraint(equalToConstant: 175).isActive = true
        view.bringSubviewToFront(colorsCollectionView1)
        
        hideView(view: colorsCollectionView1, hidden: false)
    }
    //MARK: - selectAllButtonTapped
    @IBAction func selectAllButtonTapped(_ sender: UIBarButtonItem) {
        if selectAllButton.image == UIImage(systemName: K.systemImages.circleGrid3x3Fill) {
            selectAllButton.image = UIImage(systemName: K.systemImages.circleFill)
        } else {
            selectAllButton.image = UIImage(systemName: K.systemImages.circleGrid3x3Fill)
        }
    }
    //MARK: - plusButtonTapped
    @IBAction func plusButtonTapped(_ sender: UIBarButtonItem) {
        
        let marker = GMSMarker()
        //marker.title = "Marker"
        //marker.snippet = "Australia"
        marker.map = mapView
        marker.isDraggable = true
        marker.icon = UIImage(systemName: K.systemImages.dotCircle)?.imageScaled(to: CGSize(width: 30, height: 30))
        //marker.iconView =  UIImageView(image: UIImage(systemName: K.systemImages.dotCircle))
        //marker.iconView?.tintColor = UIColor.flatBlackDark()
        marker.groundAnchor = .init(x: 0.5, y: 0.5)
        
        switch editingOverlayType {
        case .field:
            break
        case .line:
            break
        case .place:
            placesController!.increaseIconSize(place: placesController!.selectedPlace, mapView: mapView)
        }
        
    }
    //MARK: - didTapAt coordinate
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        //print("You tapped at \(coordinate.latitude), \(coordinate.longitude)")
        if !toolBar.isHidden {
            let newMarker = GMSMarker()
            if editingOverlayType != .place {
                newMarker.map = mapView
                newMarker.isDraggable = true
                newMarker.icon = UIImage(systemName: K.systemImages.dotCircle)?.imageScaled(to: CGSize(width: 30, height: 30))
                newMarker.groundAnchor = .init(x: 0.5, y: 0.5)
                newMarker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
            var closestMarkerIndex = 0
            var secondClosestMarkerIndex = 0
            var closestDistance = Double.greatestFiniteMagnitude
            var secondClosestDistance = Double.greatestFiniteMagnitude
            switch editingOverlayType {
            case .field:
                if let markers = fieldsController?.selectedFieldMarkers {
                    for i in 0...markers.count-1 {
                        let distance = GMSGeometryDistance(newMarker.position,markers[i].position)
                        if distance < closestDistance {
                            closestDistance = distance
                            closestMarkerIndex = i
                        }
                    }
                    for i in 0...markers.count-1 {
                        let distance = GMSGeometryDistance(newMarker.position,markers[i].position)
                        if distance < secondClosestDistance && distance > closestDistance {
                            secondClosestDistance = distance
                            secondClosestMarkerIndex = i
                        }
                    }
                    
                    if (closestMarkerIndex == 0 && secondClosestMarkerIndex == (markers.count-1)) || (closestMarkerIndex == (markers.count-1)) && secondClosestMarkerIndex == 0 {
                        if closestMarkerIndex == 0 {
                            fieldsController?.selectedFieldMarkers.insert(newMarker, at: closestMarkerIndex)
                            if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                                fieldsController!.arrangeSelectedFieldLengthMarker(i: 0, inside: true, add: true, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                            }
                        } else {
                            fieldsController?.selectedFieldMarkers.append(newMarker)
                            //fieldsController!.arrangeSelectedFieldLengthMarker(i: markers.count-1, inside: true, add: true, mapView: mapView)
                            if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                                fieldsController?.setHideSelectedFieldLengthMarkers(mapView: nil, remove: true)
                                fieldsController?.setSelectedFieldLengthMarkers(isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                                fieldsController?.setHideSelectedFieldLengthMarkers(mapView: mapView, remove: true)
                            }
                        }
                    } else if closestMarkerIndex < secondClosestMarkerIndex {
                        fieldsController?.selectedFieldMarkers.insert(newMarker, at: secondClosestMarkerIndex)
                        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                            fieldsController!.arrangeSelectedFieldLengthMarker(i: secondClosestMarkerIndex, inside: true, add: true, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                        }
                    } else {
                        fieldsController?.selectedFieldMarkers.insert(newMarker, at: closestMarkerIndex)
                        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                            fieldsController!.arrangeSelectedFieldLengthMarker(i: closestMarkerIndex, inside: true, add: true, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                        }
                    }
                }
                
                let rect = GMSMutablePath()
                if let markers = fieldsController?.selectedFieldMarkers {
                    for marker in markers {
                        rect.add(marker.position)
                    }
                }
                fieldsController?.selectedPolygon.path = rect
                fieldsController?.selectedPolygon.map = mapView
                areaLabelSet()
            case .line:
                closestMarkerIndex = 0
                closestDistance = Double.greatestFiniteMagnitude
                secondClosestMarkerIndex = 0
                secondClosestDistance = Double.greatestFiniteMagnitude
                if let markers = linesController?.selectedLineMarkers {
                    for i in 0...markers.count-1 {
                        let distance = GMSGeometryDistance(newMarker.position,markers[i].position)
                        if distance < closestDistance {
                            closestDistance = distance
                            closestMarkerIndex = i
                        }
                    }
                    for i in 0...markers.count-1 {
                        let distance = GMSGeometryDistance(newMarker.position,markers[i].position)
                        if distance < secondClosestDistance && distance > closestDistance {
                            secondClosestDistance = distance
                            secondClosestMarkerIndex = i
                        }
                    }
                    if closestMarkerIndex == 0 {
                        linesController?.selectedLineMarkers.removeAll()
                        linesController?.selectedLineMarkers.append(newMarker)
                        for marker in markers {
                            linesController?.selectedLineMarkers.append(marker)
                        }
                        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                            linesController!.arrangeSelectedLineLengthMarker(i: closestMarkerIndex, inside: false, add: true, mapView: mapView, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                        }
                    } else if closestMarkerIndex == (markers.count-1) {
                        linesController?.selectedLineMarkers.append(newMarker)
                        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                            linesController!.arrangeSelectedLineLengthMarker(i: linesController!.selectedLineMarkers.count-2, inside: false, add: true, mapView: mapView, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                        }
                    } else if closestMarkerIndex < secondClosestMarkerIndex {
                        linesController?.selectedLineMarkers.insert(newMarker, at: secondClosestMarkerIndex)
                        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                            linesController!.arrangeSelectedLineLengthMarker(i: secondClosestMarkerIndex, inside: true, add: true, mapView: mapView, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                        }
                    } else {
                        linesController?.selectedLineMarkers.insert(newMarker, at: closestMarkerIndex)
                        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                            linesController!.arrangeSelectedLineLengthMarker(i: closestMarkerIndex, inside: true, add: true, mapView: mapView, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                        }
                    }
                }
                
                let rect = GMSMutablePath()
                if let markers = linesController?.selectedLineMarkers {
                    for marker in markers {
                        rect.add(marker.position)
                    }
                }
                linesController?.selectedPolyline.path = rect
                linesController?.selectedPolyline.map = mapView
                areaLabelSet()
            case .place:
                break
            }
        } else if isInitialState {
            
            let newMarker = GMSMarker()
            //marker.title = "Marker"
            //marker.snippet = "Australia"
            newMarker.map = mapView
            newMarker.isDraggable = false
            newMarker.isTappable = false
            newMarker.icon = UIImage(systemName: K.systemImages.dotCircle)?.imageScaled(to: CGSize(width: 30, height: 30))
            //newMarker.iconView =  UIImageView(image: UIImage(systemName: K.systemImages.dotCircle))
            //newMarker.iconView?.tintColor = UIColor.flatBlackDark()
            newMarker.groundAnchor = .init(x: 0.5, y: 0.5)
            newMarker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            initialMarkers.append(newMarker)
            var isComplete = false
            if addType == .field && initialMarkers.count == 3 {
                if let groupTitle = groupTitleTextField.text {
                    if let title = titleTextField.text {
                        if let color = colorButton.backgroundColor?.hexValue() {
                            fieldsController!.addField(title: title, groupTitle: groupTitle, color: color, initialMarkers: initialMarkers, id: nil, isGeodesic: userDefaults!.first!.isGeodesicActive)
                        }
                    }
                }
                isComplete = true
                editField(polygon: (fieldsController?.polygons.last)!)
            } else if addType == .line && initialMarkers.count == 2 {
                if let title = titleTextField.text {
                    if let color = colorButton.backgroundColor?.hexValue() {
                        linesController!.addLine(title: title, color: color, initialMarkers: initialMarkers, mapView: mapView, isGeodesic: userDefaults!.first!.isGeodesicActive, id: nil)
                    }
                }
                isComplete = true
                editLine(polyline: (linesController?.polylines.last)!)
            } else if addType == .place && initialMarkers.count == 1 {
                if let title = titleTextField.text {
                    if let color = colorButton.backgroundColor?.hexValue() {
                        placesController!.addPlace(title: title, color: color, mapView: mapView, initialMarker: initialMarkers[0], id: nil, iconSize: nil)
                    }
                }
                isComplete = true
                editPlace(placeMarker: (placesController?.placeMarkers.last)!)
            }
            if isComplete {
                for marker in initialMarkers {
                    marker.map = nil
                }
                initialMarkers.removeAll()
                isInitialState = false
                self.navigationController?.navigationBar.isHidden = false
            }
        } else {
            hideView(view: arrowButton, hidden: false)
            hideView(view: addStackView, hidden: true)
            hideView(view: addFormStackView, hidden: true)
            hideView(view: colorsCollectionView, hidden: true)
            hideView(view: colorsCollectionView1, hidden: true)
            tappableSettings(to: true)
            if mapTypeStackView.isHidden == false {
                hideView(view: mapTypeStackView, hidden: true)
                hideView(view: mapTypeSelectButton, hidden: false)
            } 
        }
    }
    //MARK: - minusButtonTapped
    @IBAction func minusButtonTapped(_ sender: UIBarButtonItem) {
        switch editingOverlayType {
        case .field:
            if let markers = fieldsController?.selectedFieldMarkers {
                if markers.count > 3 {
                    //var deleteThisMarker = GMSMarker()
                    let markersCount = fieldsController?.selectedFieldMarkers.count
                    
                    var deletedMarkerIndex = 0;
                    for marker in markers {
                        if marker.title == "delete" {
                            deletedMarkerIndex = (fieldsController?.selectedFieldMarkers.firstIndex(of: marker))!
                            fieldsController?.selectedFieldMarkers[deletedMarkerIndex].map = nil
                            fieldsController?.selectedFieldMarkers.remove(at: deletedMarkerIndex)
                            fieldsController?.selectedPolygon.map = nil
                            fieldsController?.selectedPolygon.map = mapView
                        }
                    }
                    
                    if markersCount == fieldsController?.selectedFieldMarkers.count {
                        let alert = UIAlertController(title: NSLocalizedString("Oops!", comment: "") , message: K.errorMessages.deletingCornerErrorMessage, preferredStyle: .alert)
                        let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (action) in
                            
                        }
                        alert.addAction(editItemsAction)
                        present(alert, animated: true, completion: nil)
                        
                    } else {
                        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                            fieldsController?.deleteSelectedFieldLengthMarker(index: deletedMarkerIndex, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                        }
                        let rect = GMSMutablePath()
                        if let markers = fieldsController?.selectedFieldMarkers {
                            for marker in markers {
                                rect.add(marker.position)
                            }
                        }
                        fieldsController?.selectedPolygon.path = rect
                        fieldsController?.selectedPolygon.map = mapView
                        areaLabelSet()
                    }
                } else {
                    let alert = UIAlertController(title: (fieldsController?.selectedField.title)! + K.errorMessages.tooFewCornerCountForFieldErrorMessage, message: "", preferredStyle: .alert)
                    
                    let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (action) in
                        
                    }
                    
                    alert.addAction(editItemsAction)
                    
                    present(alert, animated: true, completion: nil)
                }
            }
        case .line:
            if let markers = linesController?.selectedLineMarkers {
                if markers.count > 2 {
                    //var deleteThisMarker = GMSMarker()
                    let markersCount = linesController?.selectedLineMarkers.count
                    
                    var deletedMarkerIndex = 0;
                    for marker in markers {
                        if marker.title == "delete" {
                            markers[markers.firstIndex(of: marker)!].map = nil
                            deletedMarkerIndex = (linesController?.selectedLineMarkers.firstIndex(of: marker))!
                            linesController?.selectedLineMarkers.remove(at: (deletedMarkerIndex))
                            linesController?.selectedPolyline.map = nil
                            linesController?.selectedPolyline.map = mapView
                        }
                    }
                    
                    if markersCount == linesController?.selectedLineMarkers.count {
                        let alert = UIAlertController(title: NSLocalizedString("Oops!", comment: "") , message: K.errorMessages.deletingCornerErrorMessage, preferredStyle: .alert)
                        let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (action) in
                            
                        }
                        alert.addAction(editItemsAction)
                        present(alert, animated: true, completion: nil)
                        
                    } else {
                        if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                            linesController?.deleteSelectedLineLengthMarker(index: deletedMarkerIndex, isMetric: userDefaults!.first!.isMeasureSystemMetric, distanceUnit: userDefaults!.first!.distanceUnit)
                        }
                    }
                    
                    let rect = GMSMutablePath()
                    if let markers = linesController?.selectedLineMarkers {
                        for marker in markers {
                            rect.add(marker.position)
                        }
                    }
                    linesController?.selectedPolyline.path = rect
                    linesController?.selectedPolyline.map = mapView
                    areaLabelSet()
                } else {
                    let alert = UIAlertController(title: (fieldsController?.selectedField.title)! + K.errorMessages.tooFewCornerCountForLineErrorMessage, message: "", preferredStyle: .alert)
                    
                    let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (action) in
                        
                    }
                    
                    alert.addAction(editItemsAction)
                    
                    present(alert, animated: true, completion: nil)
                }
            }
        case .place:
            placesController!.decreaseIconSize(place: placesController!.selectedPlace, mapView: mapView)
        }
    }
    //MARK: - saveButtonTapped
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        if userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
            hideView(view: bannerView, hidden: false)
        }
        switch editingOverlayType {
        case .field:
            fieldsController?.saveFieldToDB()
            fieldsController?.saveFieldToCloud(field: fieldsController!.selectedField)
            
        case .line:
            linesController?.saveLineToDB(line: linesController!.selectedLine)
        
        case .place:
            placesController?.savePlaceToDB(place: placesController!.selectedPlace, placeMarker: placesController!.selectedPlaceMarker)
            placesController?.selectedPlaceMarker.isDraggable = false
        }
        endEditing()
        
        if interstitial != nil && showAd && userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
            
            interstitial?.present(fromRootViewController: self)
            
        } else {
            //print("Ad wasn't ready")
        }
        timer?.invalidate()
        showAd = false
    }
    
    //MARK: - endEditing
    @objc func endEditing(){
        hideView(view: toolBar, hidden: true)
        tappableSettings(to: true)
        switch editingOverlayType {
        case .field:
            if let markers = fieldsController?.selectedFieldMarkers {
                for marker in markers {
                    marker.map = nil
                }
            }
            fieldsController?.selectedFieldMarkers.removeAll()
            if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                fieldsController?.setHideSelectedFieldLengthMarkers(mapView: nil, remove: true)
            }
            
        case .line:
            if let markers = linesController?.selectedLineMarkers {
                for marker in markers {
                    marker.map = nil
                }
            }
            linesController?.selectedLineMarkers.removeAll()
            if ((userDefaults!.first!.showDistancesBetweenTwoCorners)) {
                linesController?.setHideSelectedLineLengthMarkers(mapView: nil, remove: true)
            }
        
        case .place:
            //draggingMarker.map = nil
            //draggingMarker = nil
            break
        }
        
        editingOverlayType = .place
        hideView(view: arrowButton, hidden: false)
        hideView(view: colorsCollectionView1, hidden: true)
        hideView(view: areaLabel, hidden: true)
        nc.removeObserver(self, name: Notification.Name("EndEditing"), object: nil)
    }
    
    //MARK: - viewDidDisappear
    override func viewDidDisappear(_ animated: Bool) {
        if !toolBar.isHidden {
            saveButtonTapped(saveButton)
        }
        if let userDefault = userDefaults?.first {
            do {
                try realm.write({
                    userDefault.cameraPosition?.latitude = mapView.camera.target.latitude
                    userDefault.cameraPosition?.longitude = mapView.camera.target.longitude
                    userDefault.cameraPosition?.zoom = mapView.camera.zoom
                    
                    realm.add(userDefault)
                })
            } catch {
                print(K.errorSavingContext + " \(error)")
            }
        }
        userDefaults = realm.objects(UserDefaults.self)
    }
}

extension MapViewController: UITextFieldDelegate {
    //MARK: - textFieldDidEndEditing
    func textFieldDidEndEditing(_ textField: UITextField) {
        colorButton.setTitle(NSLocalizedString("Group Color", comment: "") , for: .normal)
        if textField == groupTitleTextField {
            groupTitleTextField.resignFirstResponder()
            if let groups = fieldsController!.groups {
                for group in groups {
                    if group.title == textField.text {
                        colorButton.backgroundColor = UIColor(hexString: group.color)
                    }
                }
            }
        }
    }
    //MARK: - textFieldShouldReturn
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == groupTitleTextField {
            groupTitleTextField.resignFirstResponder()
            titleTextField.becomeFirstResponder()
        }
        if textField == titleTextField {
            titleTextField.resignFirstResponder()
            addButtonTapped(nil)
        }
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

extension MapViewController {
    //MARK: - addToolBarConstraints
    func addToolBarConstraints() {
        
        toolBar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        // Home button is avaible or not
        if #available(iOS 11.0, *), let keyWindow = UIApplication.shared.windows.filter({$0.isKeyWindow}).first, keyWindow.safeAreaInsets.bottom > 0 {
            toolBar.bottomAnchor.constraint(equalTo: view.bottomAnchor , constant: -20).isActive = true
        }else {
            toolBar.bottomAnchor.constraint(equalTo: view.bottomAnchor , constant: 0).isActive = true
        }
        toolBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        toolBar.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
    }
    //MARK: - addSubViewsConstraints
    func addSubViewsConstraints() {
        self.view.addSubview(addStackView)
        
        addStackView.translatesAutoresizingMaskIntoConstraints = false
        
        addStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        addStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        addStackView.isHidden = true
        
        addStackView.layer.borderWidth = 0.75
        addStackView.layer.borderColor = UIColor.systemBlue.cgColor
        
        addStackView.clipsToBounds = true
        addStackView.layer.cornerRadius = 10
        addStackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        self.view.addSubview(addFormStackView)
        
        addFormStackView.translatesAutoresizingMaskIntoConstraints = false
        addFormStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        
        centerYConstraint = addFormStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        NSLayoutConstraint.activate([
                    centerYConstraint
                ])
        //addFormStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true

        if UIDevice.current.userInterfaceIdiom == .phone {
            addFormStackView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.4).isActive = true
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            addFormStackView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.25).isActive = true
        }
        
        addFormStackView.layer.borderWidth = 0.75
        addFormStackView.layer.borderColor = UIColor.systemBlue.cgColor
        
        addFormStackView.isHidden = true
        
        addFormStackView.clipsToBounds = true
        addFormStackView.layer.cornerRadius = 15
        addFormStackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        self.view.addSubview(arrowButton)
        
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        
        arrowButton.contentHorizontalAlignment = .left
        arrowButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        arrowButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        
        arrowButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        arrowButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        //arrowButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.15).isActive = true
        //arrowButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.175).isActive = true
        
        arrowButton.layer.cornerRadius = arrowButton.frame.size.height
        arrowButton.clipsToBounds = true
        
        arrowButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: arrowButton.frame.width/4, bottom: 0, right: 0);
        
        selectAllButton.image = UIImage(systemName: K.systemImages.circleGrid3x3Fill)
        
        view.addSubview(colorsCollectionView)
        colorsCollectionView.isHidden = true
        
        colorsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        colorsCollectionView.backgroundColor = UIColor.flatGray()
        
        colorsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        self.colorsCollectionView.dataSource = self
        self.colorsCollectionView.delegate = self
        
        view.addSubview(colorsCollectionView1)
        colorsCollectionView1.isHidden = true
        
        colorsCollectionView1.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        colorsCollectionView1.backgroundColor = UIColor.flatWhiteDark()
        view.bringSubviewToFront(colorsCollectionView1)
        
        colorsCollectionView1.translatesAutoresizingMaskIntoConstraints = false
        
        self.colorsCollectionView1.dataSource = self
        self.colorsCollectionView1.delegate = self
        
        self.view.addSubview(mapTypeSelectButton)
        
        mapTypeSelectButton.translatesAutoresizingMaskIntoConstraints = false
        
        mapTypeSelectButton.contentHorizontalAlignment = .left
        mapTypeSelectButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        mapTypeSelectButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor , constant: 20).isActive = true
        
        mapTypeSelectButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        mapTypeSelectButton.heightAnchor.constraint(equalToConstant: 65).isActive = true
        //mapTypeSelectButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.15).isActive = true
        //mapTypeSelectButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.15).isActive = true
        
        mapTypeSelectButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: arrowButton.frame.width/4, bottom: 0, right: 0);
        
        //mapTypeSelectButton.contentVerticalAlignment = .center
        //mapTypeSelectButton.contentHorizontalAlignment = .left
        
        mapTypeSelectButton.layer.cornerRadius = mapTypeSelectButton.frame.size.height
        mapTypeSelectButton.clipsToBounds = true
        
        self.view.addSubview(mapTypeStackView)
        
        mapTypeStackView.translatesAutoresizingMaskIntoConstraints = false
        
        mapTypeStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        mapTypeStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor , constant: 20).isActive = true
        mapTypeStackView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.25).isActive = true
        mapTypeStackView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.40).isActive = true
        mapTypeStackView.distribution = .fillEqually
        
        mapTypeStackView.isHidden = true
        
        mapTypeStackView.clipsToBounds = true
        mapTypeStackView.layer.cornerRadius = 10
        mapTypeStackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        self.view.addSubview(areaLabel)
        
        areaLabel.translatesAutoresizingMaskIntoConstraints = false
        
        areaLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor , constant: 5).isActive = true
        areaLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor , constant: 10).isActive = true
        //areaLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        areaLabel.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.7).isActive = true
        areaLabel.backgroundColor = UIColor(hexString: K.colors.fourthColor)
        //areaLabel.textColor = UIColor(hexString: K.colors.primaryColor)
        areaLabel.numberOfLines = 0
        areaLabel.adjustsFontSizeToFitWidth = true
        areaLabel.isHidden = true
        
        self.view.addSubview(myLocationButton)
        
        myLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        myLocationButton.contentHorizontalAlignment = .left
        myLocationButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        myLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor , constant: -100).isActive = true
        
        myLocationButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        myLocationButton.heightAnchor.constraint(equalToConstant: 65).isActive = true
        //myLocationButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.15).isActive = true
        //myLocationButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.15).isActive = true
        
        myLocationButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: arrowButton.frame.width/4, bottom: 0, right: 0);
        //myLocationButton.contentVerticalAlignment = .center
        //myLocationButton.contentHorizontalAlignment = .left
        
        myLocationButton.layer.cornerRadius = mapTypeSelectButton.frame.size.height
        myLocationButton.clipsToBounds = true
        
        //bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        //view.addSubview(bannerView)
        //let adSize = GADAdSizeFromCGSize(CGSize(width: 300, height: 50))
        
        // In this case, we instantiate the banner with desired ad size.
        bannerView! = GADBannerView(adSize: kGADAdSizeBanner)

        if let bannerView = bannerView {
            addBannerViewToView(bannerView)
        }
    }
}
//MARK: - GADBannerViewDelegate
extension MapViewController: GADBannerViewDelegate {
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bottomLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
        // Add banner to view and add constraints as above.
        addBannerViewToView(bannerView)
    }
    
    /// Tells the delegate an ad request failed.
    /*func adView(_ bannerView: GADBannerView,
     didFailToReceiveAdWithError error: GADRequestError) {
     print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
     }*/
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}
//MARK: - GADFullScreenContentDelegate
extension MapViewController: GADFullScreenContentDelegate {
    
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }
    
    /// Tells the delegate that the ad presented full screen content.
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        
        AlertsHelper.adsAlert(on: self)
        
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: APIConstants.GADInterstitialAdUnitID,
                               request: request,
                               completionHandler: { [self] ad, error in
                                if let error = error {
                                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                                    return
                                }
                                interstitial = ad
                                interstitial?.fullScreenContentDelegate = self
                               }
        )
    }
    
}

extension MapViewController: UIDocumentPickerDelegate,UINavigationControllerDelegate {
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    
        guard let myURL = urls.first else {
            return
        }
        
//        print("import result : \(myURL)")
//
//        print(myURL.pathExtension)
        
        let geo = GeoJSON(mapView: mapView)
        
        if myURL.pathExtension == "kml" {
            geo.renderKml(url: myURL, fieldsController: fieldsController!, linesController: linesController!, placesController: placesController!, mapView: mapView) {
                
                AlertsHelper.importFileTaskCompletedAlert(on: self)
            }
        } else if myURL.pathExtension == "geojson" {
            geo.renderGeoJSON(url: myURL, fieldsController: fieldsController!, linesController: linesController!, placesController: placesController!, mapView: mapView) {
                AlertsHelper.importFileTaskCompletedAlert(on: self)
            }
        }
    }
          

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
    //MARK: - exportFile
    func exportFileType() {
        
        let alert = UIAlertController(title: NSLocalizedString("Export File", comment: ""), message: NSLocalizedString("Which type of file do you want to export? For better results choose GeoJSON file type.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "GeoJSON", style: .default, handler: { [self] (action) in
            
            exportFileContent(isGeoJson: true)
            
        }))
        alert.addAction(UIAlertAction(title: "KML (BETA)", style: .default, handler: { [self] (action) in
            
            exportFileContent(isGeoJson: false)
            
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    //MARK: - exportFiles
    func exportFileContent(isGeoJson: Bool) {
        let alert = UIAlertController(title: "Export File", message: "Export", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("All Fields", comment: ""), style: .default, handler: { [self] (action) in
            exportFileFinal(isGeoJson: isGeoJson, exportType: "fields")
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("All Lines", comment: ""), style: .default, handler: { [self] (action) in
            exportFileFinal(isGeoJson: isGeoJson, exportType: "lines")
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("All Places", comment: ""), style: .default, handler: { [self] (action) in
            exportFileFinal(isGeoJson: isGeoJson, exportType: "places")
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("All Overlays", comment: ""), style: .default, handler: { [self] (action) in
            exportFileFinal(isGeoJson: isGeoJson, exportType: "all")
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    //MARK: - exportFileFinal
    func exportFileFinal(isGeoJson: Bool, exportType: String) {
        let geo = GeoJsonAndKmlTemplates()
        
        if isGeoJson {
            geo.makeGeojsonFile(exportType: exportType, fieldsController: fieldsController!, linesController: linesController!, placesController: placesController!, completion: {
                AlertsHelper.exportFileTaskCompletedAlert(on: self, isGeoJson: isGeoJson)
            })
        } else {
            geo.makeKMLFile(exportType: exportType, fieldsController: fieldsController!, linesController: linesController!, placesController: placesController!, completion: {
                AlertsHelper.exportFileTaskCompletedAlert(on: self, isGeoJson: isGeoJson)
                
            })
        }
    }
    
    //MARK: - importFileAlert
    func importFile() {
        
        let alert1 = UIAlertController(title: NSLocalizedString("Import File", comment: ""), message: NSLocalizedString("Which type of file do you want to import? For better results choose GeoJSON file type.", comment: ""), preferredStyle: .alert)
        alert1.addAction(UIAlertAction(title: "GeoJSON", style: .default, handler: { (action) in
            self.importGeoJSON()
        }))
        alert1.addAction(UIAlertAction(title: "KML (BETA)", style: .default, handler: { (action) in
            self.importKML()
        }))
        alert1.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive, handler: nil))
        DispatchQueue.main.async {
            self.present(alert1, animated: true, completion: nil)
        }
    }
    //MARK: - importGeoJSON
    func importGeoJSON() {
        selectFiles(isGeoJSON: true)
    }
    //MARK: - importKML
    func importKML() {
        selectFiles(isGeoJSON: false)
    }
    //MARK: - selectFiles
    func selectFiles(isGeoJSON: Bool) {
        
        var type = "nsklc.geojsonExtension"
        
        if !isGeoJSON {
            type = "nsklc.kmlExtension"
        }
        
        let types = [UTType.init(exportedAs: type)]
     
        let documentPickerController = UIDocumentPickerViewController(
                forOpeningContentTypes: types, asCopy: true)
    
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
    }
    
}
    
    
    
  

