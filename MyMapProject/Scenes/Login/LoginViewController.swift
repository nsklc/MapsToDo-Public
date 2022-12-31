//
//  LoginViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 27.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import FirebaseUI
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class LoginViewController: UIViewController, UINavigationControllerDelegate, GIDSignInDelegate, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    
    @IBOutlet weak var appIconImageView: UIImageView!
    @IBOutlet weak var signInWithGoogleButton: UIButton!
    @IBOutlet weak var loginWithEmailButton: UIButton!
    
    // Unhashed nonce.
    private var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(hexString: K.Colors.thirdColor)
        self.setLoginPage()
        GIDSignIn.sharedInstance()?.delegate = self
        
    }
    // MARK: - setLoginPage
    func setLoginPage() {
        let signInWithAppleButton = ASAuthorizationAppleIDButton()
        signInWithAppleButton.addTarget(self, action: #selector(handleAppleIdRequest), for: .touchUpInside)
        view.addSubview(signInWithAppleButton)
        
        setButtonConstraints(button: signInWithGoogleButton, icon: K.ImagesFromXCAssets.googleIcon)
        signInWithAppleButton.translatesAutoresizingMaskIntoConstraints = false
        signInWithAppleButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        signInWithAppleButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
        signInWithAppleButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        signInWithAppleButton.clipsToBounds = true
        signInWithAppleButton.layer.cornerRadius = signInWithAppleButton.bounds.height*0.5
        setButtonConstraints(button: loginWithEmailButton, icon: K.ImagesFromXCAssets.mailIcon)
        
        loginWithEmailButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        
        signInWithAppleButton.bottomAnchor.constraint(equalTo: loginWithEmailButton.safeAreaLayoutGuide.topAnchor, constant: -10).isActive = true
        
        signInWithGoogleButton.bottomAnchor.constraint(equalTo: signInWithAppleButton.safeAreaLayoutGuide.topAnchor, constant: -10).isActive = true
        
        signInWithGoogleButton.setTitle(NSLocalizedString("Sign in with Google", comment: ""), for: .normal)
        loginWithEmailButton.setTitle(NSLocalizedString("Sign in with Email", comment: ""), for: .normal)
    }
    
    // MARK: - setButtonConstraints
    func setButtonConstraints(button: UIButton, icon: String) {
        
        appIconImageView.translatesAutoresizingMaskIntoConstraints = false
        // appIconImageView.widthAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.4).isActive = true
        // appIconImageView.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.4).isActive = true
        
        appIconImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            appIconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
            appIconImageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 50).isActive = true
            appIconImageView.rightAnchor.constraint(equalTo: signInWithGoogleButton.safeAreaLayoutGuide.rightAnchor, constant: -50).isActive = true
            appIconImageView.heightAnchor.constraint(equalTo: appIconImageView.widthAnchor).isActive = true
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            appIconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
            appIconImageView.bottomAnchor.constraint(equalTo: signInWithGoogleButton.safeAreaLayoutGuide.topAnchor, constant: -50).isActive = true
            appIconImageView.widthAnchor.constraint(equalTo: appIconImageView.heightAnchor).isActive = true
        }
        
        self.view.layoutIfNeeded()
        
        appIconImageView.clipsToBounds = true
        appIconImageView.layer.cornerRadius = appIconImageView.bounds.height*0.1
        // appIconImageView.layer.borderWidth = 1
        appIconImageView.image = UIImage(named: K.ImagesFromXCAssets.appLogo)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        button.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.05).isActive = true
        button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        
        let image = UIImageView(image: UIImage(named: icon))
        image.tintColor = UIColor.flatBlue()
        image.backgroundColor = UIColor.flatWhiteDark()
        // image.backgroundColor = UIColor.flatRed()
        button.addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        image.leftAnchor.constraint(equalTo: button.leftAnchor).isActive = true
        image.heightAnchor.constraint(equalTo: button.heightAnchor, multiplier: 0.7).isActive = true
        image.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        image.widthAnchor.constraint(equalTo: button.widthAnchor, multiplier: 0.1).isActive = true
        
        button.clipsToBounds = true
        button.layer.cornerRadius = button.bounds.height*0.5
        
        button.backgroundColor = UIColor.flatWhiteDark()
        button.setTitleColor(UIColor.flatBlack(), for: .normal)
    }
    // MARK: - loginWithEmailButtonTapped
    @IBAction func loginWithEmailButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showEmailLoginViewController", sender: self)
    }
    // MARK: - SignInWithGoogleButtonTapped
    @IBAction func signInWithGoogleButtonTapped(_ sender: UIButton) {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
        
    }
    // MARK: - didSignInFor
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            print(error)
            // ...
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        // ...
        
        Auth.auth().signIn(with: credential) { (_, error) in
            if let error = error {
                print(error)
                // ...
                return
            }
            // User is signed in
            // ...
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    // MARK: - SignInWithAppleButtonTapped
    @objc func handleAppleIdRequest() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    // MARK: - sha256
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // MARK: - authorizationController
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (_, error) in
                if let error = error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error.localizedDescription)
                    return
                } else {
                    // User is signed in to Firebase with Apple.
                    // print("User is signed in to Firebase with Apple.")
                    
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    // MARK: - authorizationController
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
    
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}
