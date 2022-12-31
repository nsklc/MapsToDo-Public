//
//  ProfessionalViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 23.02.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit
import RealmSwift
import StoreKit
import Purchases
import Firebase

class PremiumViewController: UIViewController {
    
    private var sharedSecret = ""
    
    private let user = Auth.auth().currentUser
    
    let realm: Realm! = try? Realm()
    
    private var userDefaults: Results<UserDefaults>?
    
    @IBOutlet weak var mainStackView: UIStackView!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    
    let color = ["6EB5A5", "F9F4DB", "E7D6AC", "A13842"]
    let textColors = ["F9F4DB", "A13842", "A13842", "F9F4DB"]
    // Sandbox tester password: nt_x6dDmtQfUSbz
    
    private var packages = [Purchases.Package]()
    
    private var productBeingPurchased: SKProduct?
    
    private let professionalMapServicesProductID = "MapsToDoProfessional"
    private let professionalMapServicesYearlyProductID = "nsklc.MyMapProject.ProfessionalMapServicesYearly"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.fetchOfferings()
        }
        userDefaults = realm.objects(UserDefaults.self)
        setAutoLayout()
    }
    
    // MARK: - buyProButtonTapped
    @IBAction func buyProButtonTapped(_ sender: UIButton) {
        guard let professionalMapServicesYearlyPackage = packages.first(where: {$0.product.productIdentifier == professionalMapServicesYearlyProductID}) else {
            return
        }
        
        subscribe(to: professionalMapServicesYearlyPackage)
    }
    
    // MARK: - restoreButtonTapped
    @IBAction func restoreButtonTapped(_ sender: UIBarButtonItem) {
        Purchases.shared.restoreTransactions { [self] (purchaserInfo, _) in
            // ... check purchaserInfo to see if entitlement is now active
            if let purchaserInfo = purchaserInfo {
                if !purchaserInfo.entitlements.active.isEmpty {
                    
                    let nc = NotificationCenter.default
                
                    if purchaserInfo.entitlements.all[K.Entitlements.professional]?.isActive == true {
                        // Unlock that great "professional" content
                        nc.post(name: Notification.Name("checkUserSubscription"), object: nil)
                        navigationController?.popToRootViewController(animated: true)
                    }
                } else {
                    AlertsHelper.restoreSubscriptionAlert(on: self)
                }
            }
        }
    }
    
    // MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        
    }
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        
    }

    // MARK: - setAutoLayout
    func setAutoLayout() {
        
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mainStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        mainStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        
        bottomView.backgroundColor = UIColor(hexString: color[3])
        
        headerLabel.text = K.appName + " Professional"
        headerLabel.textColor = UIColor(hexString: textColors[3])
        // headerLabel1.font = UIFont(name: "System", size: 30)
        headerLabel.font = UIFont.boldSystemFont(ofSize: 30)
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.topAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.topAnchor, constant: 25).isActive = true
        headerLabel.centerXAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        buyButton.setTitle(NSLocalizedString("Subscribe", comment: ""), for: .normal)
        buyButton.setTitleColor(UIColor(hexString: K.Colors.secondaryColor), for: .normal)
        buyButton.titleLabel?.font = UIFont(name: "System", size: 30)
        buyButton.backgroundColor = UIColor(hexString: K.Colors.thirdColor)
        
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        buyButton.bottomAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.bottomAnchor, constant: -75).isActive = true
        buyButton.centerXAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.centerXAnchor).isActive = true
        buyButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        buyButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
       
        buyButton.clipsToBounds = true
        buyButton.layer.cornerRadius = buyButton.bounds.height*0.3
        
        contentLabel.textColor = UIColor(hexString: textColors[3])
        contentLabel.font = UIFont(name: "System", size: 25)
        contentLabel.numberOfLines = 0
        contentLabel.adjustsFontSizeToFitWidth = true
        // contentLabel1.adjustsFontForContentSizeCategory = true
        
        contentLabel.text = NSLocalizedString("• Ad Free", comment: "")
        
        contentLabel.text! += NSLocalizedString("\n\n• Cloud Storage - Save your measurements, to-do items and field photos to the cloud.", comment: "")
        
        contentLabel.text! += String(format: NSLocalizedString("\n\n• Storage Limits - With %@ Professional, you will have 5 GB of cloud storage and you can save hundreds of overlays and photos.", comment: ""), K.appName)
        
        contentLabel.text! += String(format: NSLocalizedString("\n\n• Realtime Updates - %@ Professional uses data synchronization to update data with cloud services.", comment: ""), K.appName)
        
        contentLabel.text! += String(format: NSLocalizedString("\n\n• Offline Support - If the device is offline, %@ Professional caches data that your app is actively using. When the device comes back online, %@ Professional synchronizes any local changes back to cloud.", comment: ""), K.appName, K.appName)
            
        contentLabel.text! += NSLocalizedString( "\n\n• Collaboration With Your Team - Import and export files without limits to collaborate with your team.", comment: "")
        
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.centerYAnchor.constraint(equalTo: bottomView.safeAreaLayoutGuide.centerYAnchor, constant: 0).isActive = true
        contentLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
        contentLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
        // contentLabel1.topAnchor.constraint(lessThanOrEqualTo: headerLabel1.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        contentLabel.bottomAnchor.constraint(lessThanOrEqualTo: buyButton.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        
    }
    
    func addButtons() {
        let emptyString: String = ""
        
        guard let professionalMapServicesPackage = packages.first(where: {$0.product.productIdentifier == professionalMapServicesProductID}) else {
            return
        }
        guard let professionalMapServicesYearlyPackage = packages.first(where: {$0.product.productIdentifier == professionalMapServicesYearlyProductID}) else {
            return
        }
        
        buyButton.setTitle(String(format: NSLocalizedString("%@ %@ / Year", comment: ""), professionalMapServicesYearlyPackage.product.price, professionalMapServicesYearlyPackage.product.priceLocale.currencySymbol ?? professionalMapServicesYearlyPackage.product.priceLocale.currencyCode ?? emptyString), for: .normal)
    
        let savePercent = String(format: "%.2f", 100 - (professionalMapServicesYearlyPackage.product.price.doubleValue  * 100 ) / (professionalMapServicesPackage.product.price.doubleValue * 12))
        
        let termsAndConditionsLabel = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        termsAndConditionsLabel.isEditable = false
        
        let buyButton2 = UIButton(primaryAction: UIAction(handler: { _ in
            self.subscribe(to: professionalMapServicesPackage)
        }))
        
        bottomView.addSubview(buyButton2)
        bottomView.bringSubviewToFront(buyButton2)
        
        buyButton2.setTitle(String(format: NSLocalizedString("%@ %@ / Month", comment: ""), professionalMapServicesPackage.product.price, professionalMapServicesPackage.product.priceLocale.currencySymbol ?? professionalMapServicesPackage.product.priceLocale.currencyCode ?? emptyString), for: .normal)
        buyButton2.tintColor = buyButton.tintColor
        buyButton2.backgroundColor = buyButton.backgroundColor
        buyButton2.titleLabel?.font = buyButton.titleLabel?.font
        
        buyButton2.translatesAutoresizingMaskIntoConstraints = false
        buyButton2.widthAnchor.constraint(equalTo: buyButton.widthAnchor).isActive = true
        buyButton2.heightAnchor.constraint(equalTo: buyButton.heightAnchor).isActive = true
        buyButton2.bottomAnchor.constraint(equalTo: buyButton.topAnchor, constant: -10).isActive = true
        buyButton2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        buyButton2.clipsToBounds = true
        buyButton2.layer.cornerRadius = buyButton.bounds.height*0.3
    
        bottomView.addSubview(termsAndConditionsLabel)
        bottomView.bringSubviewToFront(termsAndConditionsLabel)
        termsAndConditionsLabel.backgroundColor = UIColor.clear
        
//        let attributedString = NSMutableAttributedString(string:  "Terms of Use and Privacy Policy")
        let attributedString = NSMutableAttributedString(string: String(format: NSLocalizedString("You can save up to %@%% by subscribing annually. \n\nTerms of Use and Privacy Policy", comment: ""), savePercent))
        
//        let attributedString1 = NSMutableAttributedString(string: String(format: NSLocalizedString("You can save %% %@ by subscribing annually. \n\nTerms of Use and Privacy Policy", comment: ""), savePercent))
        
//        let langStr = Locale.current.languageCode
        let locale = NSLocale.current.languageCode ?? Locale.current.languageCode ?? "en"
        
//        print(locale)
        
        if locale == "tr" {
            attributedString.addAttribute(.link, value: "https://mapstodo.com/TRTerms.html", range: NSRange(location: 52, length: 18))
            attributedString.addAttribute(.link, value: "https://mapstodo.com/TRPolicy.html", range: NSRange(location: 74, length: 19))
            
            attributedString.addAttribute(.foregroundColor, value: UIColor.flatWhite(), range: NSRange(location: 0, length: 52))
        } else {
            attributedString.addAttribute(.link, value: "https://mapstodo.com/TermsAndConditions.html", range: NSRange(location: 51, length: 14))
            attributedString.addAttribute(.link, value: "https://mapstodo.com/Policy.html", range: NSRange(location: 70, length: 14))
            
            attributedString.addAttribute(.foregroundColor, value: UIColor.flatWhite(), range: NSRange(location: 0, length: 50))
        }
        
        termsAndConditionsLabel.isEditable = false
        
        termsAndConditionsLabel.attributedText = attributedString
        termsAndConditionsLabel.textAlignment = .center
        
        termsAndConditionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        termsAndConditionsLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        termsAndConditionsLabel.topAnchor.constraint(equalTo: buyButton.bottomAnchor, constant: 10).isActive = true
        termsAndConditionsLabel.widthAnchor.constraint(equalTo: buyButton.widthAnchor).isActive = true
        termsAndConditionsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func fetchOfferings() {
        Purchases.shared.offerings { (offerings, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            } else if let offerings = offerings {
<<<<<<< Updated upstream
=======
                // Display current offering with offerings.current
                // offerings.all.keys.forEach { (key) in
                    // print(key)
                // }
                
>>>>>>> Stashed changes
                offerings.current?.availablePackages.forEach({ package in
                    self.packages.append(package)
                })
                
                self.addButtons()
            }
        }
    }
    
    func subscribe(to package: Purchases.Package) {
        Purchases.shared.purchasePackage(package) { [self] (_, purchaserInfo, error, _) in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let user = user {
                Purchases.configure(withAPIKey: APIConstants.PurchasesAPIKey, appUserID: user.uid)
            }
            
            let nc = NotificationCenter.default
            if let purchaserInfo = purchaserInfo {
                if !purchaserInfo.entitlements.active.isEmpty {
                    if purchaserInfo.entitlements.all[K.Entitlements.professional]?.isActive == true {
                        // Unlock that great "professional" content
                        nc.post(name: Notification.Name("checkUserSubscription"), object: nil)
                        navigationController?.popToRootViewController(animated: true)
                        
                    }
                }
            }
        }
    }
    
}

extension PremiumViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
    
}
