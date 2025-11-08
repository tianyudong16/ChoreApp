//
//  FirebaseInterface.swift
//  Chorely
//
//  Created by Milo Guan on 11/7/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class FirebaseInterface {
    static let shared = FirebaseInterface()
    
    let auth: Auth
    let firestore: Firestore
    
    private init(){
        if FirebaseApp.app() == nil{
            FirebaseApp.configure()
            print("Firebase configured successfully!")
        } else {
            print("Firebase already configured")
        }
        
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        
        //this signs us in on initialization, but we want to sign in when the user enters their name/password
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Auth failed: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                print("Signed in anonymously with UID: \(user.uid)")
            }
        }
    }
    
    func addUser(name: String, groupName: String) {
        print("Attempting to add user: \(name), \(groupName)")
        
        db.collection("Users").addDocument(data: [
            "Name": name,//Note that the "Name" field on firestore is capitalized, but no other fields are
            "color": "blue",//placeholder, we will write code to ensure each group member has a unique color
            "groupName": groupName,
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("User added successfully!")
            }
        }
    }
}
