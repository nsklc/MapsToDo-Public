//
//  EmailLoginViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 22.12.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class EmailLoginViewController: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var eMailTextfield: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var PasswordForgottenButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(hexString: K.colors.thirdColor)
        setAutoLayout()
        
        eMailTextfield.delegate = self
        passwordTextfield.delegate = self
        
    }
    //MARK: - logInButtonTapped
    @IBAction func logInButtonTapped(_ sender: UIButton?) {
        if let email = eMailTextfield.text, let password = passwordTextfield.text, !email.isEmpty, !password.isEmpty {
            Auth.auth().signIn(withEmail: email, password: password) { [self] authResult, error in
                if let e = error {
                    //print(e)
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .userNotFound:
                            Auth.auth().createUser(withEmail: email, password: password) { [self] authResult, error in
                                if let e = error {
                                    
                                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                                        switch errCode {
                                            case .weakPassword:
                                            errorLabel.isHidden = false
                                                errorLabel.text = NSLocalizedString("Password must contain 6 or more characters.", comment: "")
                                            print(e.localizedDescription)
                                            default:
                                                errorLabel.isHidden = false
                                                errorLabel.text = e.localizedDescription
                                        }
                                    }
                                } else {
                                    navigationController?.popToRootViewController(animated: true)
                                }
                            }
                        case .invalidEmail:
                            errorLabel.isHidden = false
                            errorLabel.text = NSLocalizedString("Email address is badly formatted.", comment: "")
                        case .weakPassword:
                            errorLabel.isHidden = false
                            errorLabel.text = NSLocalizedString("Password must contain 6 or more characters.", comment: "")
                        case .wrongPassword:
                            errorLabel.isHidden = false
                            errorLabel.text = NSLocalizedString("Wrong password. Try again or click 'Forgot password' to get an email to reset your password.", comment: "")
                        default:
                            errorLabel.isHidden = false
                            errorLabel.text = e.localizedDescription
                        }
                    }
                } else {
                    //self.performSegue(withIdentifier: K.segueIdentifiers.loginToMapView, sender: self)
                    navigationController?.popToRootViewController(animated: true)
                }
                /*if let authResult = authResult {
                    print(authResult)
                    print(authResult.description)
                    } else {
                    self.performSegue(withIdentifier: "loginToMapView", sender: self)
                    }*/
            }
        } else {
            errorLabel.isHidden = false
            errorLabel.text = NSLocalizedString("You must enter an email address and password.", comment: "")
        }
    }
    //MARK: - PasswordForgottenButtonTapped
    @IBAction func PasswordForgottenButtonTapped(_ sender: UIButton) {
        AuthAlertsHelper.passwordForgottenAlert(on: self) { [weak self] text, isHidden in
            guard let self = self else { return }
            self.errorLabel.isHidden = false
            self.errorLabel.text = text
        }
    }
    
    //MARK: - textFieldShouldReturn
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == eMailTextfield {
            eMailTextfield.resignFirstResponder()
            passwordTextfield.becomeFirstResponder()
        }
        if textField == passwordTextfield {
            passwordTextfield.resignFirstResponder()
            logInButtonTapped(nil)
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
        
        if updatedText.count >= 30 {
            textField.layer.borderWidth = 0.50
            textField.layer.borderColor = UIColor.flatRed().cgColor
        } else {
            textField.layer.borderWidth = 0
        }

        // make sure the result is under 20 characters
        return updatedText.count <= 30
    }
    
    //MARK: - setAutoLayout
    func setAutoLayout() {
        eMailTextfield.translatesAutoresizingMaskIntoConstraints = false
        eMailTextfield.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        eMailTextfield.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.05).isActive = true
        eMailTextfield.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        eMailTextfield.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        eMailTextfield.clipsToBounds = true
        eMailTextfield.layer.cornerRadius = logInButton.bounds.height*0.3
        eMailTextfield.layer.borderWidth = 1
        
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.widthAnchor.constraint(equalTo: eMailTextfield.widthAnchor, multiplier: 0.4).isActive = true
        emailLabel.heightAnchor.constraint(equalTo: eMailTextfield.heightAnchor, multiplier: 0.4).isActive = true
        emailLabel.leftAnchor.constraint(equalTo: eMailTextfield.leftAnchor, constant: 10).isActive = true
        emailLabel.centerYAnchor.constraint(equalTo: eMailTextfield.topAnchor, constant: 0).isActive = true
        emailLabel.clipsToBounds = true
        emailLabel.layer.cornerRadius = emailLabel.bounds.height*0.3
        //displayNameLabel.layer.borderWidth = 1
        emailLabel.text = NSLocalizedString("Email", comment: "")
        emailLabel.backgroundColor = view.backgroundColor
        emailLabel.textAlignment = .center
        
        emailLabel.minimumScaleFactor = 0.1    //you need
        emailLabel.adjustsFontSizeToFitWidth = true
        emailLabel.lineBreakMode = .byClipping
        emailLabel.numberOfLines = 0
        
        self.view.bringSubviewToFront(emailLabel)
        
        passwordTextfield.translatesAutoresizingMaskIntoConstraints = false
        passwordTextfield.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        passwordTextfield.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.05).isActive = true
        passwordTextfield.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        passwordTextfield.topAnchor.constraint(equalTo: eMailTextfield.bottomAnchor, constant: 50).isActive = true
        passwordTextfield.clipsToBounds = true
        passwordTextfield.layer.cornerRadius = logInButton.bounds.height*0.3
        passwordTextfield.layer.borderWidth = 1
        
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        passwordLabel.widthAnchor.constraint(equalTo: passwordTextfield.widthAnchor, multiplier: 0.4).isActive = true
        passwordLabel.heightAnchor.constraint(equalTo: passwordTextfield.heightAnchor, multiplier: 0.4).isActive = true
        passwordLabel.leftAnchor.constraint(equalTo: passwordTextfield.leftAnchor, constant: 10).isActive = true
        passwordLabel.centerYAnchor.constraint(equalTo: passwordTextfield.topAnchor, constant: 0).isActive = true
        passwordLabel.clipsToBounds = true
        passwordLabel.layer.cornerRadius = passwordLabel.bounds.height*0.3
        //displayNameLabel.layer.borderWidth = 1
        passwordLabel.text = NSLocalizedString("Password", comment: "")
        passwordLabel.backgroundColor = view.backgroundColor
        passwordLabel.textAlignment = .center
        
        passwordLabel.minimumScaleFactor = 0.1    //you need
        passwordLabel.adjustsFontSizeToFitWidth = true
        passwordLabel.lineBreakMode = .byClipping
        passwordLabel.numberOfLines = 0
        
        self.view.bringSubviewToFront(passwordLabel)
        
        PasswordForgottenButton.translatesAutoresizingMaskIntoConstraints = false
        PasswordForgottenButton.widthAnchor.constraint(equalTo: passwordLabel.widthAnchor, multiplier: 1.2).isActive = true
        PasswordForgottenButton.heightAnchor.constraint(equalTo: passwordLabel.heightAnchor, multiplier: 1.2).isActive = true
        PasswordForgottenButton.rightAnchor.constraint(equalTo: passwordTextfield.rightAnchor, constant: 0).isActive = true
        PasswordForgottenButton.topAnchor.constraint(equalTo: passwordTextfield.bottomAnchor, constant: 10).isActive = true
        
        PasswordForgottenButton.clipsToBounds = true
        PasswordForgottenButton.backgroundColor = UIColor.clear
        PasswordForgottenButton.tintColor = UIColor.flatBlue()
        PasswordForgottenButton.layer.cornerRadius = logInButton.bounds.height*0.5
        
        PasswordForgottenButton.setTitle(NSLocalizedString("Forgot password?", comment: ""), for: .normal)
        
        logInButton.translatesAutoresizingMaskIntoConstraints = false
        logInButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3).isActive = true
        logInButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.05).isActive = true
        logInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        logInButton.topAnchor.constraint(equalTo: passwordTextfield.bottomAnchor, constant: 50).isActive = true
        
        logInButton.clipsToBounds = true
        logInButton.layer.cornerRadius = logInButton.bounds.height*0.3
        
        logInButton.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        logInButton.setTitleColor(UIColor.flatGreen(), for: .normal)
        logInButton.setTitle(NSLocalizedString("Log in", comment: ""), for: .normal)
        
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        infoLabel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.10).isActive = true
        infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        infoLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        
        infoLabel.clipsToBounds = true
        infoLabel.layer.cornerRadius = logInButton.bounds.height*0.5
        
        infoLabel.text = NSLocalizedString("If this is your first login, you will be registered automatically.", comment: "")
        infoLabel.numberOfLines = 0
        infoLabel.lineBreakMode = .byWordWrapping
        infoLabel.textAlignment = .center
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        errorLabel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.10).isActive = true
        errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        errorLabel.topAnchor.constraint(equalTo: logInButton.bottomAnchor, constant: 10).isActive = true
        
        errorLabel.clipsToBounds = true
        errorLabel.layer.cornerRadius = logInButton.bounds.height*0.5
        
        errorLabel.text = NSLocalizedString("If this is your first login, you will be registered automatically.", comment: "")
        errorLabel.numberOfLines = 0
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true
    }
}

