//
//  AuthViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 4.01.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import RealmSwift

class AuthViewController: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
        
    let realm: Realm! = try? Realm()
    
    private var userDefaults: Results<UserDefaults>?
    var fieldsController: FieldsController?
    var linesController: LinesController?
    var placesController: PlacesController?
    
    private let firestoreDB = Firestore.firestore()
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let user = Auth.auth().currentUser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userDefaults = realm.objects(UserDefaults.self)
        
        view.backgroundColor = UIColor(hexString: K.Colors.thirdColor)
        
        self.displayNameTextField.delegate = self
        
        handle = Auth.auth().addStateDidChangeListener { [self] (_, user) in
            if let userID = user?.uid {
                if userDefaults?.first?.accountType == "deActiveMember" || userDefaults?.first?.accountType == "premium" {
                    do {
                        try realm.write({
                            userDefaults?.first?.bossID = userID
                            userDefaults?.first?.bossEmail = user?.email ?? ""
                        })
                    } catch {
                        print("Error saving context, \(error)")
                    }
                }
            }
            if let userName = user?.displayName {
                if !userName.isEmpty {
                    displayNameTextField.text = userName
                } else {
                    displayNameTextField.placeholder = NSLocalizedString("Enter a display name.", comment: "")
                }
            }
            if let url = user?.photoURL {
                userImageView.downloaded(from: url)
            } else {
                userImageView.image = UIImage(systemName: "\( user?.displayName?.first?.lowercased() ?? "a").square.fill")
                userImageView.tintColor = UIColor(hexString: K.Colors.primaryColor) ?? UIColor.flatTeal()
                userImageView.backgroundColor = UIColor(hexString: K.Colors.fifthColor) ?? UIColor.flatTeal()
            }
            if let email = user?.email {
                emailTextField.text = email
            }
            
            changePasswordButton.isHidden = true
        }
        setAutoLayout()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    // MARK: - textFieldShouldReturn
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == displayNameTextField {
            textField.resignFirstResponder()
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = textField.text
            changeRequest?.commitChanges { (error) in
                if let error = error {
                    print(error)
                }
            }
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

        // make sure the result is under 20 characters
        return updatedText.count <= 20
    }
    
    // MARK: - changePasswordButtonTapped
    @IBAction func changePasswordButtonTapped(_ sender: UIButton) {
        AuthAlertsHelper.changePasswordAlert(on: self) {
            AuthAlertsHelper.enterPasswordAlert(on: self) { [weak self] password, newPassword, newPassword1 in
                guard let self = self else { return }
                let isCurrentPasswordTrue = self.reAuth(password: password)
                if isCurrentPasswordTrue {
                    if newPassword == newPassword1 {
                        self.changePassword(newPassword: newPassword)
                    } else {
                        AuthAlertsHelper.samePasswordAlert(on: self)
                    }
                }
            }
        } sendEmailAction: {
            if let email = Auth.auth().currentUser?.email {
                Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
                    guard let self = self else { return }
                    AuthAlertsHelper.passwordResetEmailAlert(on: self, error: error)
                }
            }
        }
    }
    // MARK: - reAuth
    func reAuth(password: String) -> Bool {
        var isCurrentPasswordTrue = true
        let user = Auth.auth().currentUser
        var credential: AuthCredential
        credential = EmailAuthProvider.credential(withEmail: (user?.email)!, password: password)
        // Prompt the user to re-provide their sign-in credentials
        user?.reauthenticate(with: credential) { (_, error)  in
            isCurrentPasswordTrue = AuthAlertsHelper.reAuthAlert(on: self, error: error)
        }
        return isCurrentPasswordTrue
    }
    // MARK: - changePassword
    func changePassword(newPassword: String) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { (error) in
            AuthAlertsHelper.passwordChangedAlert(on: self, error: error)
        }
    }
    
    // MARK: - signOutButtonTapped
    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
        navigationController?.popToRootViewController(animated: true)
    }
    // MARK: - deleteDB
    func deleteDB() {
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
    }
    
    // MARK: - setAutoLayout()
    func setAutoLayout() {
        
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        if UIDevice.current.userInterfaceIdiom == .phone {
            userImageView.widthAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.35).isActive = true
            userImageView.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.35).isActive = true
            
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            userImageView.widthAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.25).isActive = true
            userImageView.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.25).isActive = true
        }
        
        userImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        userImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = userImageView.bounds.height*0.3
        userImageView.layer.borderWidth = 1
        
        displayNameTextField.translatesAutoresizingMaskIntoConstraints = false
        displayNameTextField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        displayNameTextField.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
        displayNameTextField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        displayNameTextField.topAnchor.constraint(equalTo: userImageView.safeAreaLayoutGuide.bottomAnchor, constant: 50).isActive = true
        displayNameTextField.clipsToBounds = true
        displayNameTextField.layer.cornerRadius = displayNameTextField.bounds.height*0.3
        displayNameTextField.layer.borderWidth = 1
        displayNameTextField.font = .systemFont(ofSize: 20)
        
        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        displayNameLabel.widthAnchor.constraint(equalTo: displayNameTextField.safeAreaLayoutGuide.widthAnchor, multiplier: 0.4).isActive = true
        displayNameLabel.heightAnchor.constraint(equalTo: displayNameTextField.safeAreaLayoutGuide.heightAnchor, multiplier: 0.4).isActive = true
        displayNameLabel.leftAnchor.constraint(equalTo: displayNameTextField.safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
        displayNameLabel.centerYAnchor.constraint(equalTo: displayNameTextField.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        displayNameLabel.clipsToBounds = true
        displayNameLabel.layer.cornerRadius = displayNameLabel.bounds.height*0.3
        // displayNameLabel.layer.borderWidth = 1
        displayNameLabel.text = NSLocalizedString("Display Name", comment: "")
        displayNameLabel.backgroundColor = view.backgroundColor
        displayNameLabel.textAlignment = .center
        
        displayNameLabel.minimumScaleFactor = 0.1    // you need
        displayNameLabel.adjustsFontSizeToFitWidth = true
        displayNameLabel.lineBreakMode = .byClipping
        displayNameLabel.numberOfLines = 0
        
        self.view.bringSubviewToFront(displayNameLabel)
        
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        emailTextField.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
        emailTextField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        emailTextField.topAnchor.constraint(equalTo: displayNameTextField.safeAreaLayoutGuide.bottomAnchor, constant: 50).isActive = true
        emailTextField.clipsToBounds = true
        emailTextField.layer.cornerRadius = emailTextField.bounds.height*0.3
        emailTextField.layer.borderWidth = 1
        emailTextField.isEnabled = false
        emailTextField.font = .systemFont(ofSize: 20)
        
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.widthAnchor.constraint(equalTo: emailTextField.widthAnchor, multiplier: 0.2).isActive = true
        emailLabel.heightAnchor.constraint(equalTo: emailTextField.heightAnchor, multiplier: 0.4).isActive = true
        emailLabel.leftAnchor.constraint(equalTo: emailTextField.leftAnchor, constant: 10).isActive = true
        emailLabel.centerYAnchor.constraint(equalTo: emailTextField.topAnchor, constant: 0).isActive = true
        emailLabel.clipsToBounds = true
        emailLabel.layer.cornerRadius = displayNameLabel.bounds.height*0.3
        // displayNameLabel.layer.borderWidth = 1
        emailLabel.text = NSLocalizedString("E-Mail", comment: "")
        emailLabel.backgroundColor = view.backgroundColor
        emailLabel.textAlignment = .center
 
        emailLabel.minimumScaleFactor = 0.1    // you need
        emailLabel.adjustsFontSizeToFitWidth = true
        emailLabel.lineBreakMode = .byClipping
        emailLabel.numberOfLines = 0
        
        self.view.bringSubviewToFront(emailLabel)
        
        changePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        changePasswordButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        changePasswordButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
        changePasswordButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        changePasswordButton.bottomAnchor.constraint(equalTo: signOutButton.safeAreaLayoutGuide.topAnchor, constant: -20).isActive = true
        changePasswordButton.clipsToBounds = true
        changePasswordButton.layer.cornerRadius = emailTextField.bounds.height*0.3
        // changePasswordButton.layer.borderWidth = 1
        changePasswordButton.setTitle(NSLocalizedString("Change Password", comment: ""), for: .normal)
        changePasswordButton.backgroundColor = UIColor.flatGreenDark()
        changePasswordButton.setTitleColor(UIColor.flatWhite(), for: .normal)
        changePasswordButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        signOutButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
        signOutButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        signOutButton.clipsToBounds = true
        signOutButton.layer.cornerRadius = emailTextField.bounds.height*0.3
        // signOutButton.layer.borderWidth = 1
        signOutButton.setTitle(NSLocalizedString("Sign Out", comment: ""), for: .normal)
        signOutButton.backgroundColor = UIColor.flatRedDark()
        signOutButton.setTitleColor(UIColor.flatWhite(), for: .normal)
        signOutButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
    }
    
}
