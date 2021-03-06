//
//  AddUserViewController.swift
//  Test2
//
//  Created by maciulek on 13/05/2022.
//

import UIKit

class AddUserViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var rolePicker: UIPickerView!
    @IBOutlet weak var addUserButton: UIButton!

    let roles = Role.allCases.filter( {$0 != .superadmin} )

    override func viewDidLoad() {
        super.viewDidLoad()
        username.delegate = self
        username.tag = 0
        username.becomeFirstResponder()
        password.delegate = self
        password.tag = 1
        rolePicker.delegate = self
        if UIDevice.current.userInterfaceIdiom != .pad {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentingViewController?.viewWillDisappear(true)
        setupListNavigationBar(largeTitle: false, title: "Add User")
    }

    // this is to make the parent call viewWillAppear even if this modal did not cover 100% of the screen
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presentingViewController?.viewWillAppear(true)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {return}
        //let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height , right: 0.0)
        //scrollView.contentInset = contentInsets
        //scrollView.scrollIndicatorInsets = contentInsets
        let frame = addUserButton.convert(addUserButton.bounds, to: scrollView)  // get absolute coordinates of the button
        let offset = keyboardSize.height - (view.frame.height - frame.maxY) + 8 // add 8 points of space
        if self.view.frame.origin.y == 0 && offset > 0 {
            self.view.frame.origin.y -= offset
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        //let contentInsets =  UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        //scrollView.contentInset = contentInsets
        //scrollView.scrollIndicatorInsets = contentInsets
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }

    @IBAction func addUserPressed(_ sender: UIButton) {
        guard let user = username.text, !user.isEmpty else {
            showInfoDialogBox(title: "Missing username", message: "Enter valid user name")
            return
            }
        guard let pass = password.text, !pass.isEmpty else {
            showInfoDialogBox(title: "Missing username", message: "Enter valid user name")
            return
        }
        sender.isEnabled = false
        let role = roles[rolePicker.selectedRow(inComponent: 0)]
        authProxy.addUserWithRole(hotelId: hotel.id, username: user, password: pass, role: role) { [weak self] authData, error in
            sender.isEnabled = true
            if let a = authData {
                self?.showInfoDialogBox(title: "User added", message: "User: \(a.email)\nRole: \(a.role?.rawValue ?? "-")\nId:\(a.uid)") { [weak self] _ in
                    self?.dismiss(animated: true)
                }
            } else {
                self?.showInfoDialogBox(title: "Error", message: "Error adding user: \(error.debugDescription)")
            }
        }
/*
        authProxy.addUser(hotelId: hotel.id, username: user, password: pass, role: role) { [weak self] (authData, error) in
            sender.isEnabled = true
            guard let self = self else { return }
            if let a = authData {
                authProxy.setUserRole(uid: a.uid, role: role) { [weak self] error in
                    guard let self = self else { return }
                    self.showInfoDialogBox(title: "User added", message: "User: \(a.email)\nRole: \(role)\nId:\(a.uid)") { [weak self] _ in
                        if self?.navigationController != nil {
                            _ = self?.navigationController?.popViewController(animated: true)
                        } else {
                            self?.dismiss(animated: true)
                        }
                    }
                }
            } else {
                self.showInfoDialogBox(title: "Error", message: "Error adding user: \(error.debugDescription)")
            }
        }
*/
    }
}

extension AddUserViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        roles.count
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let textColor: UIColor = (row == pickerView.selectedRow(inComponent: component)) ? .appviator : .black
        return NSAttributedString(string: roles[row].rawValue, attributes: [NSAttributedString.Key.foregroundColor: textColor])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.reloadAllComponents()
    }
}

extension AddUserViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextTextField = view.viewWithTag(textField.tag + 1) {
            textField.resignFirstResponder()
            nextTextField.becomeFirstResponder()
        }
        return true
    }
}
