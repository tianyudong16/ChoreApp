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

func getChore(documentId:String, completion: @escaping ([String: Any]?) -> Void)
{
    db.collection("chores").document(documentId).getDocument{snapshot,
        err in
        if let err = err {
            print("Error getting chore: \(err)")
            completion(nil)
            return
        }
        guard let data = snapshot?.data() else {
            print("Chore not found")
            completion(nil)
            return
        }
        
        completion(data)
    }
}
func addChore(checklist: Bool, date: String, day: String, description: String, monthlyrepeatbydate: Bool, monthlyrepeatbyweek: String, Name: String, PriorityLevel: String, RepetitionTime: String, TimeLength: Int, assignedUsers:[String], completed: Bool, groupKey: Int){
    db.collection("chores").addDocument(data: [
        "Checklist": checklist,
        "Date": date,
        "Day": day,
        "Description": description,
        "MonthlyRepeatByDate": monthlyrepeatbydate,
        "MonthlyRepeatByWeek": monthlyrepeatbyweek,
        "Name": Name,
        "PriorityLevel": PriorityLevel,
        "RepetitionTime": RepetitionTime,
        "TimeLength": TimeLength,
        "assignedUsers":assignedUsers,
        "completed": completed,
        "groupKey": groupKey,
    ]) { err in
        if let err = err {
            print("Error adding chore: \(err)")
        } else {
            print("Chore added successfully!")
        }
    }
}
