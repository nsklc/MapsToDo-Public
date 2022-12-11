//
//  File.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 13.09.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework
import Firebase
import FirebaseFirestore
import GoogleMobileAds

class ToDoFormViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var startStackView: UIStackView!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endStackView: UIStackView!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var statusStackView: UIStackView!
    @IBOutlet weak var statusPickerView: UIPickerView!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var camButton: UIButton!
    
    private var statusPickerData = [String]()
    private let realm = try! Realm()
    private var userDefaults: Results<UserDefaults>?
    private let db = Firestore.firestore()
    private let user = Auth.auth().currentUser
    var selectedItem: Item?
    
    weak var timer: Timer?
    private var interstitial: GADInterstitialAd?
    private var showAd = false
    
    @objc func fireTimer() {
        showAd = true
    }
    
    var status = [NSLocalizedString("Waiting To Run", comment: ""), NSLocalizedString("In Progress", comment: ""), NSLocalizedString("Completed", comment: ""), NSLocalizedString("Canceled", comment: "")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userDefaults = realm.objects(UserDefaults.self)
        
        timer = Timer.scheduledTimer(timeInterval: K.freeAccountLimitations.toDoPageTimer, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
        
        noteTextView.delegate = self
        
        view.backgroundColor = UIColor(hexString: K.colors.thirdColor)
        titleTextField.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        noteTextView.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        startDatePicker.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        endDatePicker.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        
        startDatePicker.datePickerMode = .dateAndTime
        endDatePicker.datePickerMode = .dateAndTime
        
        statusPickerData = [NSLocalizedString("Waiting To Run", comment: ""), NSLocalizedString("In Progress", comment: ""), NSLocalizedString("Completed", comment: ""), NSLocalizedString("Canceled", comment: "")]
        statusPickerView.delegate = self
        statusPickerView.dataSource = self
        //statusPickerView.tintColor = UIColor.flatWhite()
        statusPickerView.contentMode = .scaleToFill
        
        if let itemTitle = selectedItem?.title {
            titleTextField.text = itemTitle
        }
        if let itemStartDate = selectedItem?.startDate {
            startDatePicker.date = itemStartDate
        }
        if let itemEndDate = selectedItem?.endDate {
            endDatePicker.date = itemEndDate
        }
        if let itemNote = selectedItem?.note {
            noteTextView.text = itemNote
        }
        setSubViewsConstraints()
        updateStatus()
        
        noteTextView.returnKeyType = UIReturnKeyType.default
        noteTextView.addDoneButtonOnKeyboard()
        noteTextView.isScrollEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
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
    
    //MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
    }
    
    //MARK: - keyboardWillShow
    @objc func keyboardWillShow(notification: NSNotification) {
       guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        self.noteTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.top, right: 0)
        self.noteTextView.scrollIndicatorInsets = self.noteTextView.contentInset;
        
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
              // if keyboard size is not available for some reason, dont do anything
              return
           }
         
         // move the root view up by the distance of keyboard height
        //self.view.frame.origin.y = 0 - abs(keyboardSize.height - noteTextView.frame.maxY)
    
        self.noteTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: abs(noteTextView.frame.maxY - keyboardSize.minY) , right: 0)
        self.noteTextView.scrollIndicatorInsets = self.noteTextView.contentInset;
    }
    //MARK: - keyboardWillHide
    @objc func keyboardWillHide(notification:NSNotification) {
        //self.view.frame.origin.y = 0
        print("keyboardWillHide")
        self.noteTextView.contentInset = UIEdgeInsets.zero;
        self.noteTextView.scrollIndicatorInsets = UIEdgeInsets.zero;
    }
    //MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
     
    //MARK: - updateStatus
    func updateStatus() {
        let date = Date()
        if selectedItem?.status != 3 && selectedItem?.status != 2 {
            var status = 0
            if date.distance(to: startDatePicker.date) > 0 {
                statusPickerView.selectRow(0, inComponent: 0, animated: true)
                status = 0
            } else if date.distance(to: startDatePicker.date) < 0 && date.distance(to: endDatePicker.date) > 0 {
                statusPickerView.selectRow(1, inComponent: 0, animated: true)
                status = 1
            }
            do {
                try realm.write({
                    selectedItem?.status = status
                })
            } catch  {
                print("Error saving item, \(error)")
            }
        } else {
            statusPickerView.selectRow(selectedItem!.status, inComponent: 0, animated: true)
        }
        switch statusPickerView.selectedRow(inComponent: 0) {
        case 0:
            statusPickerView.backgroundColor = UIColor.flatYellow()
        case 1:
            statusPickerView.backgroundColor = UIColor.flatBlue()
        case 2:
            statusPickerView.backgroundColor = UIColor.flatGreen()
        case 3:
            statusPickerView.backgroundColor = UIColor.flatRed()
        default:
            statusPickerView.backgroundColor = UIColor.flatGray()
        }
    }
    //MARK: - startDateValueChanged
    @IBAction func startDateValueChanged(_ sender: UIDatePicker) {
        updateStatus()
    }
    //MARK: - endDateValueChanged
    @IBAction func endDateValueChanged(_ sender: UIDatePicker) {
        updateStatus()
    }
    //MARK: - saveButtonTapped
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        
        if let item = selectedItem {
            do {
                try realm.write({
                    item.title = titleTextField.text!
                    item.startDate = startDatePicker.date
                    item.endDate = endDatePicker.date
                    item.note = noteTextView.text
                })
            } catch  {
                print("Error saving item, \(error)")
            }
            saveItemToCloud(item: item)
        }
        if let navController = self.navigationController, navController.viewControllers.count >= 2 {
            let viewController = navController.viewControllers[navController.viewControllers.count - 2]
            viewController.viewDidLoad()
        }
        
        
        if showAd && userDefaults?.first?.accountType == K.invites.accountTypes.freeAccount {
            if interstitial != nil {
                interstitial?.present(fromRootViewController: self)
                
                let nc = NotificationCenter.default
                nc.post(name:  Notification.Name("addShowed"), object: nil)
                
            } else {
                print("Ad wasn't ready")
            }
        }

        navigationController?.popViewController(animated: true)
    }
    //MARK: - saveItemToCloud
    func saveItemToCloud(item: Item) {
        if userDefaults?.first?.accountType == K.invites.accountTypes.proAccount {
            db.collection(userDefaults!.first!.bossID).document("Items").collection("Items").document(item.id).setData(item.dictionaryWithValues(forKeys: ["title", "startDate", "endDate", "note", "status"]), merge: true) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    //print("Document successfully written!")
                    //db.collection(user.uid).document("Items").setData([item.id : self.updateTime], merge: true)
                }
            }
        }
    }
    //MARK: - setSubViewsConstraints
    func setSubViewsConstraints() {
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        titleTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        titleTextField.layer.borderWidth = 0.50
        titleTextField.layer.borderColor = UIColor.systemBlue.cgColor
        titleTextField.delegate = self
        
        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        notesLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        notesLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        notesLabel.bottomAnchor.constraint(equalTo: noteTextView.safeAreaLayoutGuide.topAnchor, constant: -5).isActive = true
        notesLabel.topAnchor.constraint(equalTo: titleTextField.safeAreaLayoutGuide.bottomAnchor, constant: 10).isActive = true
        //notesLabel.layer.borderWidth = 1
        //notesLabel.layer.borderColor = UIColor(hexString: K.colors.fourthColor)?.cgColor
        notesLabel.adjustsFontForContentSizeCategory = true
        notesLabel.textAlignment = .center
        notesLabel.text = NSLocalizedString("Notes", comment: "")
        
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        noteTextView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        noteTextView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        noteTextView.bottomAnchor.constraint(equalTo: startStackView.safeAreaLayoutGuide.topAnchor, constant: -10).isActive = true
        noteTextView.topAnchor.constraint(equalTo: notesLabel.safeAreaLayoutGuide.bottomAnchor, constant: 5).isActive = true
        noteTextView.isScrollEnabled = true
        //noteTextView.layer.borderWidth = 1
        //noteTextView.layer.borderColor = UIColor(hexString: K.colors.fourthColor)?.cgColor
        
        noteTextView.layer.borderWidth = 0.75
        noteTextView.layer.borderColor = UIColor.systemBlue.cgColor
        
        startStackView.translatesAutoresizingMaskIntoConstraints = false
        startStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        startStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        startStackView.bottomAnchor.constraint(equalTo: endStackView.safeAreaLayoutGuide.topAnchor, constant: -10).isActive = true
        startStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        endStackView.translatesAutoresizingMaskIntoConstraints = false
        endStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5).isActive = true
        endStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        endStackView.bottomAnchor.constraint(equalTo: statusStackView.topAnchor, constant: -10).isActive = true
        endStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        statusStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        statusStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        statusStackView.bottomAnchor.constraint(equalTo: saveButton.safeAreaLayoutGuide.topAnchor, constant: -10).isActive = true
        statusStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
        saveButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
        saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saveButton.backgroundColor = UIColor.flatGreenDark()
        
        camButton.translatesAutoresizingMaskIntoConstraints = false
        camButton.rightAnchor.constraint(equalTo: noteTextView.rightAnchor, constant: -5).isActive = true
        camButton.topAnchor.constraint(equalTo: noteTextView.topAnchor, constant: 5).isActive = true
        view.bringSubviewToFront(camButton)
        camButton.isHidden = true
    }
    
    //MARK: - camButtonTapped
    @IBAction func camButtonTapped(_ sender: UIButton) {
        addPhotoToTextView()
    }
    
    //MARK: - addPhotoToTextView
    func addPhotoToTextView() {
        // create an NSMutableAttributedString that we'll append everything to
        //let fullString = NSMutableAttributedString(string: "Start of text\n")
        let fullString = NSMutableAttributedString(string: noteTextView.text)

        // create our NSTextAttachment
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = UIImage(named: K.imagesFromXCAssets.satalite)?.imageScaled(to: CGSize(width: noteTextView.frame.width - 10, height: noteTextView.frame.width - 10))

        // wrap the attachment in its own attributed string so we can append it
        let image1String = NSAttributedString(attachment: image1Attachment)

        // add the NSTextAttachment wrapper to our full string, then add some more text.
        fullString.append(image1String)
        //fullString.append(NSAttributedString(string: "\nEnd of text"))
        
        
        // draw the result in a label
        noteTextView.attributedText = fullString
    }
    
}

extension ToDoFormViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    //MARK: - numberOfComponents
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    //MARK: - numberOfRowsInComponent
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return statusPickerData.count
    }
    //MARK: - titleForRow
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return statusPickerData[row]
    }
    //MARK: - didSelectRow
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            statusPickerView.backgroundColor = UIColor.flatYellow()
        case 1:
            statusPickerView.backgroundColor = UIColor.flatBlue()
        case 2:
            statusPickerView.backgroundColor = UIColor.flatGreen()
        case 3:
            statusPickerView.backgroundColor = UIColor.flatRed()
        default:
            statusPickerView.backgroundColor = UIColor.flatGray()
        }
        
        print(statusPickerData[row])
        if let item = selectedItem {
            do {
                try realm.write({
                    item.status = row
                })
            } catch  {
                print("Error saving item, \(error)")
            }
        }
    }
}

extension ToDoFormViewController: GADFullScreenContentDelegate {
    
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

extension ToDoFormViewController: UITextViewDelegate {
    //MARK: - textView shouldChangeTextIn
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = textView.text ?? ""

        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }

        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)

        // make sure the result is under 65535 characters
        return updatedText.count <= 65535
    }
}


extension ToDoFormViewController: UITextFieldDelegate {
    //MARK: - textFieldShouldReturn
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            titleTextField.resignFirstResponder()
        }
        return true
    }
    
    //MARK: - textField shouldChangeCharactersIn
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
}
