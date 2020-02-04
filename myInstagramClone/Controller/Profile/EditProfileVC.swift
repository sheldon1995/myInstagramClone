//
//  EditProfileVC.swift
//  InstgramClone
//
//  Created by Sheldon on 1/26/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
class EditProfileVC: UIViewController {
    
    // MARK: Properties
    var isImageChanged = false
    var userNameChanged = false
    var nameChanged = false
    var updatedUsername : String?
    var updatedName : String?
    var profileVC:ProfileVC!
    var user: User? {
        didSet{
            guard let user = user else {return}
            guard let profileImgUrl = user.profileImageUrl else {return}
            guard let name = user.name else {return}
            guard let userName = user.userName else {return}
            
            self.profileImgView.loadImage(with: profileImgUrl)
            
            self.nameTextField.text = "\(name)"
            self.nameTextField.font = UIFont.systemFont(ofSize: 14)
            
            self.userNameTextField.text = "\(userName)"
            self.userNameTextField.font = UIFont.systemFont(ofSize: 14)
        }
        
    }
    
    let profileImgView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .black
        return iv
    }()
    
    
    lazy var changImgLabel : UILabel = {
        let label = UILabel()
        label.text = "Change Profile Photo"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .mainBlue
        label.numberOfLines = 0
        // Add gesuture recognizer.
        let changeImg = UITapGestureRecognizer(target: self, action: #selector(handleChangeProfileTapped))
        // The number of fingers required to tap for the gesture to be recognized.
        changeImg.numberOfTouchesRequired = 1
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(changeImg)
        return label
        
    }()
    
    let nameLabel : UILabel = {
        let label = UILabel()
        label.text = "Full Name"
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        return label
        
    }()
    
    let userNameLabel : UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
        
    }()
    
    let separatorView : UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()
    
    let nameTextField : UITextField = {
        let tf = UITextField()
        tf.textAlignment = .left
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    
    let userNameTextField : UITextField = {
        let tf = UITextField()
        tf.textAlignment = .left
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    let nameSeparator : UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()
    
    let userNameSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        userNameTextField.delegate = self
        nameTextField.delegate = self
        
        // Configure view componentes
        configureViewComponents()
        
        // Configute navigation bar
        configureNavigationBar()
        
    }
    
    
    // MARK: Handlers
    
    @objc func handleCancel(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func handleDone(){
        // Force to call textFieldDidEndEditing(_ textField: UITextField)
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        view.endEditing(true)
        
        if isImageChanged
        {
            updateProfileImage()
            
        }
        
        if userNameChanged{
            updateUserName(with: currentUid)
        }
        
        if nameChanged{
            updateName(with: currentUid)
        }
        
    }
    
    @objc func handleChangeProfileTapped(){
        
        // Configure image picker
        let imagePicker = UIImagePickerController()
        // The delegate receives notifications when the user picks an image or movie
        imagePicker.delegate = self
        // Allow user to edit the size of image.
        imagePicker.allowsEditing = true
        
        imagePicker.modalPresentationStyle = .fullScreen
        // Present image picker
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: API
    func configureNavigationBar(){
        navigationItem.title = "Edit Profile"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        // The style for a done button—for example, a button that completes some task and returns to the previous view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(handleDone))
        
        navigationController?.navigationBar.tintColor = .black
    }
    
    func updateUserName(with currentUid:String){
        USER_REF.child(currentUid).child("username").setValue(updatedUsername) { (error, ref) in
            guard let mainTabVC = keyWindow?.rootViewController as? MainPageViewController else {return}
            
            // Configure view controller
            mainTabVC.configureViewController()
            
            // Dismiss login controller
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func updateName(with currentUid:String){
        USER_REF.child(currentUid).child("name").setValue(updatedName) { (error, ref) in
            guard let mainTabVC = keyWindow?.rootViewController as? MainPageViewController else {return}
            
            // Configure view controller
            mainTabVC.configureViewController()
            
            // Dismiss login controller
            self.dismiss(animated: true, completion: nil)

        }
    }
    
    func updateProfileImage(){
        guard let oldImgUrl = user?.profileImageUrl else {return}
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        // Delete old profile page from storage
        Storage.storage().reference(forURL: oldImgUrl).delete(completion: nil)
        // Get the new profile image
        guard let newProfileImage = profileImgView.image else { return }
        
        /*
         expressed as a value from 0.0 to 1.0. The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents the least compression (or best quality).
         */
        guard let uploadData = newProfileImage.jpegData(compressionQuality: 0.8) else { return }
        
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
                USER_REF.child(currentUid).child("profileImageUrl").setValue(profileImageUrl,withCompletionBlock: {(error,ref) in
                    guard let mainTabVC = keyWindow?.rootViewController as? MainPageViewController else {return}
                    
                    // Configure view controller
                    mainTabVC.configureViewController()
                    
                    // Dismiss login controller
                    self.dismiss(animated: true, completion: nil)
                    
                    
                })
            })
        })
        
    }
    func configureViewComponents(){
        view.backgroundColor = .white
        
        let frame = CGRect(x: 0, y: 88, width: view.frame.width, height: 150)
        let containerView = UIView(frame: frame)
        // containerView.backgroundColor = UIColor.systemGroupedBackground
        view.addSubview(containerView)
        
        containerView.addSubview(profileImgView)
        profileImgView.anchor(top: containerView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 80, height: 80)
        profileImgView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        profileImgView.layer.cornerRadius = 80 / 2
        
        containerView.addSubview(changImgLabel)
        changImgLabel.anchor(top: profileImgView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        changImgLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        
        containerView.addSubview(separatorView)
        separatorView.anchor(top: nil, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        view.addSubview(nameLabel)
        nameLabel.anchor(top: containerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(userNameLabel)
        userNameLabel.anchor(top: nameLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(nameTextField)
        nameTextField.anchor(top: containerView.bottomAnchor, left: nameLabel.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: (view.frame.width / 1.6), height: 0)
        
        view.addSubview(userNameTextField)
        userNameTextField.anchor(top: nameTextField.bottomAnchor, left: userNameLabel.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: (view.frame.width / 1.6), height: 0)
        
        view.addSubview(nameSeparator)
        nameSeparator.anchor(top: nil, left: nameTextField.leftAnchor, bottom: nameTextField.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -6, paddingRight: 12, width: 0, height: 0.5)
        
        view.addSubview(userNameSeparator)
        userNameSeparator.anchor(top: nil, left: userNameTextField.leftAnchor, bottom: userNameTextField.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -6, paddingRight: 12, width: 0, height: 0.5)
        
        
    }
}

extension EditProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // This is selected image
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            profileImgView.image = selectedImage
            self.isImageChanged = true
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}

extension EditProfileVC: UITextFieldDelegate{
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        let trimmedUserNameString = userNameTextField.text?.replacingOccurrences(of: "\\s+$", with: "",options: .regularExpression)
        
        
        guard trimmedUserNameString != "" else{
            print("ERROR: Please enter a non-empty username")
            userNameChanged = false
            return
        }
        
        self.updatedUsername = trimmedUserNameString?.lowercased()
        userNameChanged = true
        
        // Trimmed name string
        let trimmedNameString = nameTextField.text?.replacingOccurrences(of: "\\s+$", with: "",options: .regularExpression)
        
        guard trimmedNameString != "" else{
            print("ERROR: Please enter a non-empty name")
            nameChanged = false
            return
        }
        
        self.updatedName = trimmedNameString?.lowercased()
        nameChanged = true
    }
}
