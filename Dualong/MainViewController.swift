//
//  ViewController.swift
//  Dualong
//
//  Created by Nolan Bridges on 7/23/20.
//  Copyright © 2020 NiMBLe Interactive. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

var userEmail: String! = ""
var rawEmail: String! = ""
var role: String = ""
var name: String = ""
var username: String = ""
var currScene: String = "Login"

class MainViewController: UIViewController
{
    
    @IBOutlet weak var cover: UIView!
    
    @IBOutlet weak var textBox: UITextView!
    
    @IBOutlet var signInButton: GIDSignInButton!
    
    let st = Storage.storage().reference()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        guard let shIns = GIDSignIn.sharedInstance() else { return }
        shIns.presentingViewController = self
        cover.isHidden = true
        if(shIns.hasPreviousSignIn())
        {
            cover.isHidden = false
            shIns.restorePreviousSignIn()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(setEmail(notification:)), name: .signedin, object: nil)
        
    }
    
    
    
    @objc func setEmail(notification: NSNotification)
    {
        userEmail = GIDSignIn.sharedInstance()?.currentUser.profile.email.lowercased()
        rawEmail = GIDSignIn.sharedInstance()?.currentUser.profile.email.lowercased()
        userEmail = userEmail?.replacingOccurrences(of: ".", with: ",")
        
        let db = Database.database().reference()
        
        db.child("users/\(userEmail!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists()
            {
                db.child("users/\(userEmail!)/account_type").observeSingleEvent(of: .value) { (SNAP) in
                    if let value = SNAP.value as? String
                    {
                        role = value
                    }
                }
                db.child("users/\(userEmail!)/name").observeSingleEvent(of: .value) { (SNAP) in
                    if let value = SNAP.value as? String
                    {
                        name = value
                    }
                }
                db.child("users/\(userEmail!)/username").observeSingleEvent(of: .value) { (SNAP) in
                    if let value = SNAP.value as? String
                    {
                        username = value
                        self.st.child("profilepics/\(username).jpg").getData(maxSize: 4 * 1024 * 1024, completion: { (data, error) in
                            if error != nil
                            {
                                print("error loading image \(error!)")
                            }
                            if let data = data
                            {
                                ownProfPic = UIImage(data: data)
                                NotificationCenter.default.post(name: Notification.Name("profImageLoaded"), object: nil)
                            }
                        })
                    }
                }
                
                self.performSegue(withIdentifier: "loginToHome", sender: self)
                currScene = "Home"
            } else
            {
                self.performSegue(withIdentifier: "LoginToSetup", sender: self)
                currScene = "Setup"
            }
        })
    }
    
    
    @objc func signOut(_ sender: UIButton)
    {
        print("signing out")
        GIDSignIn.sharedInstance()?.signOut()
        
        let firebaseAuth = Auth.auth()
        do
        {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError
        {
            print("failed to sign out")
            print(signOutError)
            return
        }
        
        print("Signed out")
    }

}

extension Notification.Name
{
    static let signedin = Notification.Name("signedin")
}

