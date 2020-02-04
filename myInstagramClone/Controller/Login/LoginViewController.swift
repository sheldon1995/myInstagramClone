//
//  LoginViewController.swift
//  InstgramClone
//
//  Created by Sheldon on 1/3/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit
import Firebase
class LoginViewController: UIViewController {
    
    let logoContainerView :UIView = {
        let view = UIView()
        let logoImageView =  UIImageView()
        view.addSubview(logoImageView)
        logoImageView.image = #imageLiteral(resourceName: "logo2")
        logoImageView.contentMode = .scaleAspectFill
        logoImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        // Center the logo vertically and horizontally.
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        view.backgroundColor = .mainBlue
        return view
    }()
    let emailTextFiled : UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        // Alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0.
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        // Displays a rounded-style border for the text field.
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        return tf
    }()
    
    let passwordTextFiled : UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        // Alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0.
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        // Displays a rounded-style border for the text field.
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        // Identifies whether the text object should disable text copying and in some cases hide the text being entered.
        tf.isSecureTextEntry = true
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        return tf
    }()
    
    let loginButton:UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .mainBlue
        // Round the button
        button.layer.cornerRadius = 5
        
        button.addTarget(self, action: #selector(handleLogIn), for: .touchUpInside)
        
        // The button is not processable until all information are gaven.
        button.isEnabled = false
        button.backgroundColor = .disableColor
        return button
    }()
    
    let noAccountButton:UIButton = {
        let button = UIButton(type: .system)
        // A mutable string object that also contains attributes
        let attributeTitle = NSMutableAttributedString(string: "Don't have an account?   ", attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor:UIColor.lightGray])
        attributeTitle.append(NSAttributedString(string: "Sign Up", attributes:[NSAttributedString.Key.font:UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor:UIColor.mainBlue]))
        button.setAttributedTitle(attributeTitle, for: .normal)
        
        // Add target/action to button, when it is clicked, the function "handleShowSignUp" gets called
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    // This function takes users to sign up page
    @objc func handleShowSignUp(){
        let signUpVC = SignUpVC()
        // Pushes a view controller onto the receiver’s stack and updates the display.
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    @objc func handleLogIn(){
        // Priporities
        guard let email = emailTextFiled.text else { return }
        guard let password = passwordTextFiled.text else { return }
        Auth.auth().signIn(withEmail: email, password: password, completion: {(user,error) in
            
            // Handle error
            if let error = error{
                print("Unable to sign in with error, ",error.localizedDescription)
                 return
            }
            // Sign in with this email, password, navigate to main page.
            print("Successfully signed user in!")
            
            /*
             UIApplication.shared.keyWindow?.rootViewController as as? MainPageViewController else {return}
             will cause a warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for applications that support multiple scenes as it returns a key window across all connected scenes
             */
            
            guard let mainTabVC = keyWindow?.rootViewController as? MainPageViewController else {return}
            
            // Configure view controller
            mainTabVC.configureViewController()
            
            // Dismiss login controller
            self.dismiss(animated: true, completion: nil)
        })
        
    }
    
    @objc func formValidation(){
        guard emailTextFiled.hasText, passwordTextFiled.hasText else {
            
            loginButton.isEnabled = false
            loginButton.backgroundColor = .disableColor
            return
        }
        
        // All info is gaven
        loginButton.isEnabled = true
        loginButton.backgroundColor = .enableColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Hide navigation bar
        navigationController?.navigationBar.isHidden = true
                
        view.backgroundColor = .white
        view.addSubview(logoContainerView)
        
        // Logo
        logoContainerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150)
        // Email, password and login button
        configurViewComponents()
        
        // Don't have account button
        view.addSubview(noAccountButton)
        noAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 40, paddingRight: 0, width: 0, height: 50)
    }
    func configurViewComponents(){
        let stackView = UIStackView(arrangedSubviews: [emailTextFiled,passwordTextFiled,loginButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        view.addSubview(stackView)
        stackView.anchor(top: logoContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 40, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 140)
        
    }
}
