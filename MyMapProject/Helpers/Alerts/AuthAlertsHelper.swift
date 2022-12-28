//
//  AuthAlertsHelper.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 22.12.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import UIKit
import Firebase

class AuthAlertsHelper: BaseAlertHelper {
    
    static func authInfoAlert(on vc: UIViewController, okAction: @escaping () -> Void) {
        showBasicAlertWithAction(on: vc,
                                 with: NSLocalizedString("Auth info not found.", comment: ""),
                                 message: NSLocalizedString("For the usage of cloud synchronization, you need to sign in.", comment: "")) {
            okAction()
        }
    }
    
    static func changePasswordAlert(on vc: UIViewController, changePasswordAction: @escaping () -> Void, sendEmailAction: @escaping () -> Void) {
        let ac = UIAlertController(title: NSLocalizedString("Change Password", comment: ""),
                                   message: NSLocalizedString("If you select 'send email', a password forgot mail will be sent", comment: ""),
                                   preferredStyle: .alert)
        let changePasswordAction = UIAlertAction(title: NSLocalizedString("Enter Password", comment: ""), style: .default) {_ in
            changePasswordAction()
        }
        let sendEmailAction = UIAlertAction(title: NSLocalizedString("Send Email", comment: ""), style: .default) { _ in
           sendEmailAction()
        }
        let cancelAction1 = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive)
        ac.addAction(changePasswordAction)
        ac.addAction(sendEmailAction)
        ac.addAction(cancelAction1)
        vc.present(ac, animated: true)
    }
    
    static func enterPasswordAlert(on vc: UIViewController, submitAction: @escaping (_ password: String, _ newPassword: String, _ newPassword1: String) -> Void) {
        let ac = UIAlertController(title: NSLocalizedString("Change Password", comment: ""), message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.addTextField()
        ac.addTextField()
        guard let textFields = ac.textFields else { return }
        textFields[0].placeholder = NSLocalizedString("Current Password", comment: "")
        textFields[1].placeholder = NSLocalizedString("New Password", comment: "")
        textFields[2].placeholder = NSLocalizedString("Confirm Password", comment: "")
        textFields[0].textContentType = .password
        textFields[1].textContentType = .newPassword
        textFields[2].textContentType = .newPassword
        textFields[0].isSecureTextEntry = true
        textFields[1].isSecureTextEntry = true
        textFields[2].isSecureTextEntry = true

        let submitAction = UIAlertAction(title: NSLocalizedString("Submit", comment: ""), style: .default) { [unowned ac] _ in
            if let password = ac.textFields![0].text,
               let newPassword = ac.textFields![1].text,
               let newPassword1 = ac.textFields![2].text {
                submitAction(password, newPassword, newPassword1)
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive)
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        
        vc.present(ac, animated: true)
    }
    
    static func samePasswordAlert(on vc: UIViewController) {
        errorAlert(on: vc, with: NSLocalizedString("Oops!", comment: ""), errorMessage: NSLocalizedString("New pasword and confirm password must to be same.", comment: ""))
    }
    
    static func passwordResetEmailAlert(on vc: UIViewController, error: Error?) {
        let ac = UIAlertController(title: NSLocalizedString("Email Sent", comment: ""), message: NSLocalizedString("An password reset email will be sent.", comment: ""), preferredStyle: .alert)
        if let error = error {
            if let errCode = AuthErrorCode(rawValue: error._code) {
                switch errCode {
                    case .missingEmail:
                    ac.message = NSLocalizedString("You must enter an email address.", comment: "")
                    default:
                    ac.message = error.localizedDescription
                }
            }
            let okAction = UIAlertAction(title: NSLocalizedString(NSLocalizedString("OK", comment: ""), comment: ""), style: .default)
            ac.addAction(okAction)

            vc.present(ac, animated: true)
        } else {
            ac.message = NSLocalizedString("An password reset email sent.", comment: "")
            let okAction = UIAlertAction(title: NSLocalizedString(NSLocalizedString("OK", comment: ""), comment: ""), style: .default)
            ac.addAction(okAction)

            vc.present(ac, animated: true)
        }
    }
    
    static func reAuthAlert(on vc: UIViewController, error: Error?) -> Bool {
        if let error = error {
            let ac = UIAlertController(title: NSLocalizedString(" Password Changed", comment: ""), message: nil, preferredStyle: .alert)
            ac.title = NSLocalizedString("Oops!", comment: "")
                if let errCode = AuthErrorCode(rawValue: error._code) {
                    switch errCode {
                    case .wrongPassword:
                        ac.message = NSLocalizedString("Current password was entered incorrectly.", comment: "")
                    default:
                        ac.message = error.localizedDescription
                }
            }
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default)
            ac.addAction(okAction)
            vc.present(ac, animated: true)
            return false
        } else {
            return true
        }
    }
    
    static func passwordChangedAlert(on vc: UIViewController, error: Error?) {
        let ac = UIAlertController(title: NSLocalizedString("Password Changed", comment: ""), message: nil, preferredStyle: .alert)
        if let error = error {
            ac.title = NSLocalizedString("Oops!", comment: "")
            if let errCode = AuthErrorCode(rawValue: error._code) {
                switch errCode {
                case .weakPassword:
                    ac.message = NSLocalizedString("The password must be 6 characters long or more.", comment: "")
                default:
                ac.message = error.localizedDescription
                }
            }
        } else {
            
        }
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default)
        ac.addAction(okAction)
        vc.present(ac, animated: true)
    }
    
    static func passwordForgottenAlert(on vc: UIViewController, sendPasswordResetAction: @escaping ((_ text: String, _ isHidden: Bool) -> Void)) {
        let ac = UIAlertController(title: NSLocalizedString("Enter Email", comment: ""), message: NSLocalizedString("A password reset email will be sent.", comment: ""), preferredStyle: .alert)
            ac.addTextField()
            ac.textFields![0].placeholder = "Email Address"

            let submitAction = UIAlertAction(title: NSLocalizedString("Submit", comment: ""), style: .default) { [unowned ac] _ in
                let email = ac.textFields![0].text
                Auth.auth().sendPasswordReset(withEmail: email!) { error in
                    if let error = error {
                        if let errCode = AuthErrorCode(rawValue: error._code) {
                            switch errCode {
                                case .missingEmail:
                                sendPasswordResetAction(NSLocalizedString("An email address must be provided.", comment: ""), false)
                                case .invalidEmail:
                                sendPasswordResetAction(NSLocalizedString("Email address is badly formatted.", comment: ""), false)
                                default:
                                sendPasswordResetAction(error.localizedDescription, false)
                            }
                        }
                    } else {
                        sendPasswordResetAction(NSLocalizedString("A password reset email has been sent.", comment: ""), false)
                    }
                }
            }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString(NSLocalizedString("Cancel", comment: ""), comment: ""), style: .destructive)
        ac.addAction(cancelAction)
        ac.addAction(submitAction)

        vc.present(ac, animated: true)
    }
}
