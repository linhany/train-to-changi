//
//  LoginViewController.swift
//  TrainToChangi
//
//  Created by Yong Lin Han on 3/4/17.
//  Copyright © 2017 nus.cs3217.a0139655u. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInUIDelegate {

    @IBOutlet weak var googleSignInButton: GIDSignInButton!

    @IBAction func guestSignInButtonPressed(_ sender: UIButton) {
        AuthService.instance.loginAnonymously()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance().uiDelegate = self
    }

}
