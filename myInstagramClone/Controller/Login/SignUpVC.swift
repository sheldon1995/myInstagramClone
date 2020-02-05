//
//  SignUpVC.swift
//  InstgramClone
//
//  Created by Sheldon on 1/7/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase

// To upload user's photo, need to inherent UIImagePickerControllerDelegate, UINavigationControllerDelegate.

class SignUpVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var imageSelected = false
    let addPhotoButton :UIButton = {
        let addPhoto =  UIButton()
        // The normal, or default state of a control—that is, enabled but neither selected nor highlighted.
        addPhoto.setImage(#imageLiteral(resourceName: "plus_photo").withRenderingMode(.alwaysOriginal), for: .normal)
        addPhoto.addTarget(self, action: #selector(handleProfilePhoto), for: .touchUpInside)
        return addPhoto
    }()
    
    let emailTextFiled : UITextField = {
        let tf = UITextField().getTextField(placeholder: "Email",isSecureTextEntry:false)
        // Every time, the editing is changed in the email text field, it's gonna call formValidation to make sure our for form is valid
        
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        return tf
    }()
    
    let passwordTextFiled : UITextField = {
        let tf = UITextField().getTextField(placeholder: "Password",isSecureTextEntry:true)
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        return tf
    }()
    
    let fullNameTextFiled : UITextField = {
        let tf = UITextField().getTextField(placeholder: "Full name",isSecureTextEntry:false)
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        return tf
    }()
    
    let userNameTextFiled : UITextField = {
        let tf = UITextField().getTextField(placeholder: "Username",isSecureTextEntry:false)
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        return tf
    }()
    
    let signUpButton:UIButton = {
        let button = UIButton().authButton(title: "Sign Up")
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    let allreadyHaveAccountButton:UIButton = {
        let button = UIButton().haveOrNotAccountButton(string1: "Already have an account?   ", string2: "Sign In")
        button.addTarget(self, action: #selector(backToLoginPage), for: .touchUpInside)
        return button
    }()
    
    func configurViewComponents(){
        let stackView = UIStackView(arrangedSubviews: [emailTextFiled,fullNameTextFiled,userNameTextFiled,passwordTextFiled,signUpButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        view.addSubview(stackView)
        stackView.anchor(top: addPhotoButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 240)
        
    }
    @objc func handleSignUp() {
        
        // properties
        guard let email = emailTextFiled.text else { return }
        guard let password = passwordTextFiled.text else { return }
        guard let fullName = fullNameTextFiled.text else { return }
        // Change all leters of username to lower cased.
        guard let username = userNameTextFiled.text?.lowercased() else { return }
        
        // Create an user with email and password
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            // handle error
            if let error = error {
                print("DEBUG: Failed to create user with error: ", error.localizedDescription)
                return
            }
            
            // Get profile image
            guard let profileImg = self.addPhotoButton.imageView?.image else { return }
            
            /*
             expressed as a value from 0.0 to 1.0. The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents the least compression (or best quality).
             */
            guard let uploadData = profileImg.jpegData(compressionQuality: 0.5) else { return }
            
            // An object representing a universally unique value that bridges to UUID
            let filename = NSUUID().uuidString
            
            // UPDATE: - In order to get download URL must add filename to storage ref like this
            let storageRef = STORAGE_PROFILE_IMG_REF.child(filename)
            
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                // handle error
                if let error = error {
                    print("Failed to upload image to Firebase Storage with error", error.localizedDescription)
                    return
                }
                
                // UPDATE: - Firebase 5 must now retrieve download url
                storageRef.downloadURL(completion: { (downloadURL, error) in
                    
                    // Profile imagew url
                    guard let profileImageUrl = downloadURL?.absoluteString else {
                        print("DEBUG: Profile image url is nil")
                        return
                    }
                    
                    // user id
                    guard let uid = authResult?.user.uid else { return }
                    guard let fcmToken = Messaging.messaging().fcmToken else {return}
                    let dictionaryValues = ["name": fullName,
                                            "username": username,
                                            "fcmToken": fcmToken,
                                            "profileImageUrl": profileImageUrl]
                    
                    let values = [uid: dictionaryValues]
                    
                    // save user info to database
                    //  The reference tree shown on the website
                    Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (error, ref) in
                        
                        guard let mainTabVC = keyWindow?.rootViewController as? MainPageViewController else {return}
                        
                        // Configure view controller
                        mainTabVC.configureViewController()
                        
                        // Dismiss login controller
                        self.dismiss(animated: true, completion: nil)
                        
                    })
                })
            })
        }
    }
    @objc func backToLoginPage(){
        // Pops the top view controller from the navigation stack and updates the display.
        // The current view controller is this sign up page, so go back to the login page 
        _ = navigationController?.popViewController(animated: true)
    }
    @objc func formValidation(){
        guard emailTextFiled.hasText, passwordTextFiled.hasText,fullNameTextFiled.hasText,userNameTextFiled.hasText,imageSelected==true else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
            return
        }
        signUpButton.isEnabled = true
        signUpButton.backgroundColor = UIColor(red: 17/255, green: 154/255, blue: 237/255, alpha: 1)
        
    }
    
    // Show up the page of album to select
    @objc func handleProfilePhoto(){
        // Configure image picker
        let imagePicker = UIImagePickerController()
        // The delegate receives notifications when the user picks an image or movie
        // UIImagePickerControllerDelegate, UINavigationControllerDelegate
        imagePicker.delegate = self
        // Allow user to edit the size of image.
        imagePicker.allowsEditing = true
        imagePicker.modalPresentationStyle = .fullScreen
        // Present image picker
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // This is the function get called once we sellected a image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // This is selected image
        guard let profileImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            imageSelected = false
            return
        }
        
        // Yes, the user indeed select one image
        imageSelected = true
        signUpButton.isEnabled = true
        signUpButton.backgroundColor = .enableColor
        // Confugure addPhotot button with selected image
        // Nice circular
        addPhotoButton.layer.cornerRadius = addPhotoButton.frame.width / 2
        // A Boolean indicating whether sublayers are clipped to the layer’s bounds. Animatable.
        // Now the layer is circular, but the image selected is not circular, to make it circular, need to set masksToBounds to true.
        addPhotoButton.layer.masksToBounds = true
        addPhotoButton.layer.borderColor = UIColor.black.cgColor
        addPhotoButton.layer.borderWidth = 2
        addPhotoButton.setImage(profileImage.withRenderingMode(.alwaysOriginal), for: .normal)
        
        // The presenting view controller is responsible for dismissing the view controller it presented.
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(addPhotoButton)
        addPhotoButton.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 40, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 140, height: 140)
        addPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        configurViewComponents()
        
        // Already have an account
        view.addSubview(allreadyHaveAccountButton)
        allreadyHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 40, paddingRight: 0, width: 0, height: 50)
    }
    
}
