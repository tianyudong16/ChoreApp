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
        //This code will be removed once signIn is completed.
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Auth failed: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                print("Signed in anonymously with UID: \(user.uid)")
            }
        }
    }
    
    //Adds a new user to the repository with the provided properties
    //TO DO: make it so that the color is different for each user in the group
    func addUser(name: String, email: String, color: String, groupKey: Int, groupName: String, nickName: String, password: String, roommatesNames: [String], roommates: Int) {
        print("Attempting to add user: \(name), \(groupName)")
        
        db.collection("Users").addDocument(data: [
            "Name": name,//Note that the "Name" field on firestore is capitalized, but no other fields are
            "color": color,//no longer a placeholder but not sure if using String for color should work
            "groupKey": groupKey,
            
            "groupName": groupName,
            "nickname": nickName,
            "password": password,
            "roommate names": roommatesNames,
            "roommates": roommates
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("User added successfully!")
            }
        }
    }


    //Signs in the user using the given name and password
    func signIn(name: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.signIn(withEmail: <#T##String#>, password: <#T##String#>){result, error in
            if let error = error{
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(user))
            }
        }
    }
    
    //Note: we will need to add this functionality to addUser, and change the surrounding code of the ContentView page to support error catching.
    func signUp(name: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.createUser(withEmail: <#T##String#>, password: <#T##String#>){result, error in
            if let error = error{
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(user))
            }
        }
    }
        
    func signOut() {
        do {
            try auth.signOut()
            print("successful sign-out")
        } catch {
            print("error signing out :(")
        }
    }
        
    //TO DO: add functions that let a user change their password, name, and other attributes.
    
    //Returns all of the chores where user's groupKey = the chore's groupKey. This function should have optional parameters that let you filter the list of chores.
    func getChores(){
        
    }
    
    //Adds a new chore to the repository with the following properties:
    //name: String with the name
    //priority: 1 = low, 2 = med, 3 = high. Never type anything that's not these 3 numbers
    //repetitionTime: how often the chore is repeated (weekly, daily, ect). (To be honest, I don't know how we would represent this)
    //date: When the chore is due to be done (if not repeated).
    //description: a string containing the description
    //assignedTo: the users that the chore is assigned to. Should contain at least one user
    //isChecklist: whether or not the chore is a checklist chore as opposed to an event/repeating chore. False by default.
    func addChore(name: String, priority: Int?, repetitionTime: Double?, date: Timestamp, description: String?, assignedTo: Array<UserInfo>, isChecklist: Bool?){
        
    }
    
    //Marks a chore as complete, also records who did the chore
    func markComplete(user: UserInfo){
        
    }
    //We need to make a chore log repository for this
    //Also, for repeating chores, we will need to make it so that the chore is marked as "uncomplete" before it's due again.
    
    //We won't implement this until we decide how the chore proposal system should work
    func getProposedChores(){
        
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
        "groupKey": groupKey
    ]) { err in
        if let err = err {
            print("Error adding chore: \(err)")
        } else {
            print("Chore added successfully!")
        }
    }
}

func editChore(documentId: String, checklist: Bool, date: String, day: String, description: String, monthlyrepeatbydate: Bool, monthlyrepeatbyweek: String, Name: String, PriorityLevel: String, RepetitionTime: String, TimeLength: Int, assignedUsers:[String], completed: Bool, groupKey: Int, completion: @escaping (Bool) -> Void){
    db.collection("chores").document(documentId).updateData([
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
        "groupKey": groupKey
    ])  { err in
        if let  err = err {
            print("Error editimg chore: \(err)")
            completion(false)
            return
        }
        
        print("Chore edited successfully!")
        
        completion(true)
    }
    
}
