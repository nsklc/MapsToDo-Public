//
//  InfoViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 16.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework
import FirebaseAuth
import FirebaseStorage
import GoogleMobileAds

class InfoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let realm: Realm! = try? Realm()
    
    @IBOutlet weak var infoStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rightTitleLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var rightGroupLabel: UILabel!
    @IBOutlet weak var leftAreaLabel: UILabel!
    @IBOutlet weak var rightAreaLabel: UILabel!
    @IBOutlet weak var leftCircumferenceLabel: UILabel!
    @IBOutlet weak var rightCircumferenceLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var shareBarButton: UIBarButtonItem!
    
    enum PageType {
        case fieldInfoPage
        case lineInfoPage
        case placeInfoPage
    }
    var infoPageType = PageType.fieldInfoPage
    
    var images = [UIImage]()
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    private var selectedOverlayID = ""
    
    var selectedField: Field? {
        didSet {
            infoPageType = .fieldInfoPage
            userDefaults = realm.objects(UserDefaults.self)
            selectedOverlayID = selectedField!.id
            if let photoIDs = selectedField?.photos {
                loadImages(photoIDs: photoIDs)
            }
        }
    }
    
    var selectedLine: Line? {
        didSet {
            infoPageType = .lineInfoPage
            userDefaults = realm.objects(UserDefaults.self)
            selectedOverlayID = selectedLine!.id
            if let photoIDs = selectedLine?.photos {
                loadImages(photoIDs: photoIDs)
            }
        }
    }
    
    var selectedPlace: Place? {
        didSet {
            infoPageType = .placeInfoPage
            userDefaults = realm.objects(UserDefaults.self)
            selectedOverlayID = selectedPlace!.id
            if let photoIDs = selectedPlace?.photos {
                loadImages(photoIDs: photoIDs)
            }
        }
    }
    
    private var userDefaults: Results<UserDefaults>?
    
    private let storage = Storage.storage().reference()
    private let user = Auth.auth().currentUser
    
    private var imageReferencesToDownload = [StorageReference]()
    
    weak var timer: Timer?
    private var interstitial: GADInterstitialAd?
    private var showAd = false
    
    @objc func fireTimer() {
        showAd = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get userDefaults in the realm
        
        timer = Timer.scheduledTimer(timeInterval: K.FreeAccountLimitations.infoPageTimer, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera // . photoLibrary
        
        imagePicker.allowsEditing = true
        
        setSubViewsConstraints()
        
        imageCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        
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
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !images.isEmpty {
            imageView.image = images.last
        } else {
            imageView.image = UIImage(named: K.ImagesFromXCAssets.appLogo)
        }
    }
    // MARK: - loadImages
    func loadImages(photoIDs: List<String>) {
        
        if !images.isEmpty {
            images.removeAll()
        }
        
        if userDefaults?.first?.accountType == K.Invites.AccountTypes.proAccount {
            imageReferencesToDownload = getImageReferences()
        }
        
        for photoID in photoIDs {
            if let image = getSavedImage(named: photoID) {
                images.append(image)
                image.accessibilityIdentifier = photoID
            } else {
                // download image and add images array
                if userDefaults?.first?.accountType == K.Invites.AccountTypes.proAccount {
                    guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
                        return
                    }
                    let imageURL = directory.appendingPathComponent("\(photoID).png")!
                    downloadImageFromFirebase(imageURL: imageURL, imageID: photoID)
                }
                
            }
        }
    }
    
    // MARK: - cameraButtonTapped
    @IBAction func cameraButtonTapped(_ sender: UIBarButtonItem) {
        
        if userDefaults?.first?.accountType == K.Invites.AccountTypes.freeAccount {
            // if let imageCount = images.count {
                
                if images.count >= K.FreeAccountLimitations.photoLimit {
                    AlertsHelper.addingExtraPhotoAlert(on: self)
                    return
                }
            // }
        }
        
        present(imagePicker, animated: true, completion: nil)
    }
    // MARK: - imagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            // imageView.image = userPickedImage
            
            // images.append(userPickedImage)
            
            if let id = saveImage(image: userPickedImage) {
                if let image = getSavedImage(named: id) {
                    imageView.image = image
                    
                    images.append(image)
                    
                    do {
                        switch infoPageType {
                        case .fieldInfoPage:
                            try self.realm.write {
                                selectedField?.photos.append(id)
                            }
                        case .lineInfoPage:
                            try self.realm.write {
                                selectedLine?.photos.append(id)
                            }
                        case .placeInfoPage:
                            try self.realm.write {
                                selectedPlace?.photos.append(id)
                            }
                        }
                    } catch {
                        print("Saving photo in field, \(error)")
                    }
                }
            }
        }
        switch infoPageType {
        case .fieldInfoPage:
            if let photoIDs = selectedField?.photos {
                loadImages(photoIDs: photoIDs)
            }
        case .lineInfoPage:
            if let photoIDs = selectedLine?.photos {
                loadImages(photoIDs: photoIDs)
            }
        case .placeInfoPage:
            if let photoIDs = selectedPlace?.photos {
                loadImages(photoIDs: photoIDs)
            }
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        imageCollectionView.reloadData()
    }
    // MARK: - deleteButtonTapped
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        
        AlertsHelper.deleteAlert(on: self,
                                 with: .image,
                                 overlayTitle: nil) { [weak self] in
            guard let self = self else { return }
            if !self.images.isEmpty {
                if let id = self.imageView.image?.accessibilityIdentifier {
                    if self.deleteImage(id: id) {
                        print("image deleted")
                        self.images.remove(at: self.images.firstIndex(of: self.imageView.image!)!)
                        do {
                            switch self.infoPageType {
                            case .fieldInfoPage:
                                try self.realm.write {
                                    self.selectedField?.photos.remove(at: (self.selectedField?.photos.index(of: id))!)
                                }
                            case .lineInfoPage:
                                try self.realm.write {
                                    self.selectedLine?.photos.remove(at: (self.selectedLine?.photos.index(of: id))!)
                                }
                            case .placeInfoPage:
                                try self.realm.write {
                                    self.selectedPlace?.photos.remove(at: (self.selectedPlace?.photos.index(of: id))!)
                                }
                            }
                        } catch {
                            AlertsHelper.savingPhotoAlert(on: self)
                            print("Saving photo in field, \(error)")
                        }
                        
                        if !self.images.isEmpty {
                            self.imageView.image = self.images[0]
                        } else {
                            self.imageView.image = UIImage(systemName: K.ImagesFromXCAssets.appLogo)
                        }
                    } else {
                        AlertsHelper.savingPhotoAlert(on: self)
                    }
                    self.imageCollectionView.reloadData()
                }
            } else {
                self.imageView.image = UIImage(named: K.ImagesFromXCAssets.appLogo)
                AlertsHelper.thereIsNoPhotoAlert(on: self)
                print("no image to delete")
            }
        }
    }
    // MARK: - saveImage
    func saveImage(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1) else {
            return nil
        }
        
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return nil
        }
        
        let imageID = UUID().uuidString
        do {
            try data.write(to: directory.appendingPathComponent("\(imageID).png")!)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        if userDefaults?.first?.accountType == K.Invites.AccountTypes.proAccount {
            uploadImageToFirebase(data: data, imageID: imageID)
        }
        
        return imageID
    }
    // MARK: - getSavedImage
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    // MARK: - deleteImage
    func deleteImage(id: String) -> Bool {
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            let fileManager = FileManager.default
            try fileManager.removeItem(at: directory.appendingPathComponent("\(id).png")!)
            let imageURL = directory.appendingPathComponent("\(id).png")!
            if userDefaults?.first?.accountType == K.Invites.AccountTypes.proAccount {
                deleteImageFromFirebase(imageURL: imageURL, imageID: id)
            }
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
        
    }
    // MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        // let handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        // print(auth.currentUser?.displayName)
        // }
    }
    
    // MARK: - Firebase Storage
    
    // MARK: - getImageReferences
    func getImageReferences() -> [StorageReference] {
        print("getImageReferences")
        var imageReferences = [StorageReference]()
        if let bossID = userDefaults?.first?.bossID {
            let storageReference = storage.child("\(bossID)/\(selectedOverlayID)/")
            storageReference.listAll { (result, error) in
                if let error = error {
                    print(error)
                    return
                }
                for prefix in result.prefixes {
                    // The prefixes under storageReference.
                    // You may call listAll(completion:) recursively on them.
                    print("prefix: \(prefix)")
                    
                }
                
                for item in result.items {
                    // The items under storageReference.
                    print("item: \(item.name)")
                    imageReferences.append(item)
                    // item.name
                }
            }
        }
        return imageReferences
    }
    // MARK: - uploadImageToFirebase
    func uploadImageToFirebase(data: Data, imageID: String) {
        print(imageID)
        if user != nil, let bossID = userDefaults?.first?.bossID {
            storage.child("\(bossID)/\(selectedOverlayID)/\(imageID).png").putData(data, metadata: nil) { (_, error) in
                guard error == nil else {
                    print("Failed to upload \(String(describing: error?.localizedDescription))")
                    return
                }
            }
        }
    }
    // MARK: - downloadImageFromFirebase
    func downloadImageFromFirebase(imageURL: URL, imageID: String) {
        
        if let bossID = userDefaults?.first?.bossID {
            // Create a reference to the file you want to download
            let islandRef = storage.child("\(bossID)/\(selectedOverlayID)/\(imageID).png")
            
            // Download to the local filesystem
            let downloadTask = islandRef.write(toFile: imageURL) { _, error in
                if let error = error {
                    // Uh-oh, an error occurred!
                    print(error)
                } else {
                    print("Image at firebase has been downloaded")
                }
            }
            
            downloadTask.observe(.success) { [self] _ in
                // Download completed successfully
                print("Download completed successfully")
                if let image = getSavedImage(named: imageID) {
                    images.append(image)
                    image.accessibilityIdentifier = imageID
                    imageCollectionView.reloadData()
                }
            }
        }
        
    }
    // MARK: - deleteImageFromFirebase
    func deleteImageFromFirebase(imageURL: URL, imageID: String) {
        
        if let bossID = userDefaults?.first?.bossID {
            // Create a reference to the file you want to download
            let imageRef = storage.child("\(bossID)/\(selectedOverlayID)/\(imageID).png")
            
            // Delete the file
            imageRef.delete { error in
                if let error = error {
                    // Uh-oh, an error occurred!
                    print(error)
                } else {
                    // File deleted successfully
                    print("Image deleted successfully")
                }
            }
            
        }
    }
    // MARK: - shareBarButtonTapped
    @IBAction func shareBarButtonTapped(_ sender: UIBarButtonItem) {
        print("shareBarButtonTapped")
        if let image = imageView.image {
            presentShareSheet(image: image)
        }
        
    }
    // MARK: - presentShareSheet
    func presentShareSheet(image: UIImage) {
        
        let shareSheetVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverController = shareSheetVC.popoverPresentationController {
                popoverController.sourceView = self.view // to set the source of your alert
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = [] // to hide the arrow of any particular direction
            }
        }
        present(shareSheetVC, animated: true)
    }
    
    // MARK: - addSubViewsConstraints
    func setSubViewsConstraints() {
        
        if infoPageType == .fieldInfoPage {
            titleLabel.text = NSLocalizedString("Title", comment: "")
            rightTitleLabel.text = selectedField?.title
            groupLabel.text = NSLocalizedString("Group", comment: "")
            rightGroupLabel.text = selectedField?.parentGroup.first?.title ?? "Field has no group."
        } else {
            groupLabel.isHidden = true
            rightGroupLabel.isHidden = true
        }
        
        if infoPageType == .fieldInfoPage {
            leftAreaLabel.text = NSLocalizedString("Area", comment: "")
            leftCircumferenceLabel.text = NSLocalizedString("Circumference", comment: "")
            
            let formatter = MeasurementFormatter()
            formatter.numberFormatter.maximumFractionDigits = 4
            formatter.unitOptions = .providedUnit
            
            let area = Measurement(value: selectedField!.area, unit: UnitArea.squareMeters)
            let circumference = Measurement(value: selectedField!.circumference, unit: UnitLength.meters)
            
            let content = UnitsHelper.app.getUnitForField(isShowAllUnitsSelected: false,
                                                          isMeasureSystemMetric: userDefaults!.first!.isMeasureSystemMetric,
                                                          area: area, circumference: circumference,
                                                          distanceUnit: userDefaults!.first!.distanceUnit,
                                                          areaUnit: userDefaults!.first!.areaUnit)
            
            let splitContentLines = content.split(separator: "\n")
            let line = splitContentLines[0]
            let line1 = splitContentLines[1]
            rightAreaLabel.text = String(line.split(separator: "=")[1].trimmingCharacters(in: .whitespaces))
            rightCircumferenceLabel.text = String(line1.split(separator: "=")[1].trimmingCharacters(in: .whitespaces))
            
        } else if infoPageType == .lineInfoPage {
            titleLabel.text = NSLocalizedString("Title", comment: "")
            rightTitleLabel.text = selectedLine?.title
            leftAreaLabel.text = NSLocalizedString("Length", comment: "")
            leftCircumferenceLabel.isHidden = true
            rightCircumferenceLabel.isHidden = true
            
            let length = Measurement(value: selectedLine!.length, unit: UnitLength.meters)
            
            let content = UnitsHelper.app.getUnitForLine(isShowAllUnitsSelected: false,
                                                         isMeasureSystemMetric: userDefaults!.first!.isMeasureSystemMetric,
                                                         length: length, distanceUnit: userDefaults!.first!.distanceUnit)
            
            rightAreaLabel.text = String(content.split(separator: "=")[1].trimmingCharacters(in: .whitespaces))
            
        } else {
            titleLabel.text = NSLocalizedString("Title", comment: "")
            rightTitleLabel.text = selectedPlace?.title
            leftAreaLabel.text = NSLocalizedString("Latitude", comment: "")
            leftCircumferenceLabel.text = NSLocalizedString("Longitude", comment: "")
            if let lat = selectedPlace?.markerPosition?.latitude, let lon = selectedPlace?.markerPosition?.longitude {
                rightAreaLabel.text = "\(lat)"
                rightCircumferenceLabel.text = "\(lon)"
            }
        }
        
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        infoStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        infoStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        // infoStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        infoStackView.bottomAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.topAnchor, constant: -10).isActive = true
        
        view.backgroundColor = UIColor(hexString: K.Colors.thirdColor)
        imageView.backgroundColor = UIColor(hexString: K.Colors.primaryColor)
        imageView.image = UIImage(named: K.ImagesFromXCAssets.picture)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5).isActive = true
        imageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5).isActive = true
        imageView.topAnchor.constraint(equalTo: infoStackView.bottomAnchor, constant: 10).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        // imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, constant: -100).isActive = true
        imageView.layer.borderWidth = 0.25
        imageView.layer.borderColor = UIColor.systemBlue.cgColor
        
        deleteButton.backgroundColor = UIColor(hexString: K.Colors.thirdColor)
        deleteButton.tintColor = UIColor(hexString: K.Colors.fifthColor)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.leftAnchor.constraint(equalTo: imageView.leftAnchor, constant: 0).isActive = true
        deleteButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor, constant: 0).isActive = true
        // deleteButton.heightAnchor.constraint(equalTo: imageView.heightAnchor, constant: ).isActive = true
        deleteButton.widthAnchor.constraint(equalTo: deleteButton.heightAnchor).isActive = true
        deleteButton.layer.borderWidth = 0.25
        deleteButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        imageCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5).isActive = true
        imageCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5).isActive = true
        imageCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        imageCollectionView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10).isActive = true
        imageCollectionView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        imageCollectionView.backgroundColor = UIColor(hexString: K.Colors.primaryColor)
        imageCollectionView.tintColor = UIColor.flatWhite()
        
        imageCollectionView.layer.borderWidth = 0.25
        imageCollectionView.layer.borderColor = UIColor.systemBlue.cgColor
    }
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        if showAd {
            if interstitial != nil {
                interstitial?.present(fromRootViewController: self)
            } else {
                print("Ad wasn't ready")
            }
        }
    }
    // MARK: - viewDidDisappear
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
    }
}

// MARK: - UICollectionViewDataSource
extension InfoViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count // How many cells to display
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.backgroundView = UIImageView(image: images[indexPath.row])
        myCell.layer.cornerRadius = 5
        // print(indexPath[1])
        return myCell
    }
}

// MARK: - UICollectionViewDelegate
extension InfoViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // print("User tapped on item \(indexPath.row)")
        imageView.image = images[indexPath.row]
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension InfoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let bounds = collectionView.bounds
        return CGSize(width: bounds.height, height: bounds.height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        CGFloat(collectionView.bounds.height/7)
    }
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
     return CGFloat(collectionView.bounds.height/7)
     }*/
    
}

extension InfoViewController: GADFullScreenContentDelegate {
    
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
