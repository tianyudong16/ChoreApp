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

//Following Nick Sarno's SwiftfulThinking tutorial for some of the authentication code
struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoURL: String?
    
    init(user: User){
        self.uid = user.uid
        self.email = user.email
        self.photoURL = user.photoURL?.absoluteString
    }
}

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
    }
    
    //Adds a new user to the repository with the provided properties
    //TO DO: make it so that the color is different for each user in the group
    func addUser(name: String, email: String, color: String? = nil, groupKey: Int? = nil, groupName: String, password: String, roommatesNames: [String]? = [], roommates: Int? = nil) async throws -> AuthDataResultModel {
        print("Attempting to add user: \(name), \(groupName)")
        
        //This block of code authenticates the user using the Auth library, but does not add user data
        let authDataResult = try await auth.createUser(withEmail: email, password: password)
        let result = AuthDataResultModel(
            user: authDataResult.user
        )
        
        //This block of code adds user information to the Users collection (written by Ron, added to by Milo)
        db.collection("Users").addDocument(data: [
            "Email": email,
            "Name": name,//Note that the "Name" field on firestore is capitalized, but no other fields are
            "color": color ?? "Green",//Green is a default value if color is nil
            "groupKey": groupKey ?? 111111,//111111 is also a default value
            "groupName": groupName,
            "password": password,
            "roommate names": roommatesNames ?? [],//If no roommates are speficied, an empty list (not sure if firebase will like this lol)
            "roommates": roommates ?? 0//If roommates is nil, default to 0 roommates
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("User added successfully!")
            }
        }

        return result
    }

    
    func editUser(documentId: String, name: String, email: String, color: String, groupKey: Int, groupName: String, password: String, roommatesNames: [String], roommates: Int, completion: @escaping (Bool) -> Void){
        db.collection("Users").document(documentId).updateData([
            "Email": email,
            "Name": name,
            "color": color,
            "groupKey": groupKey,
            "groupName": groupName,
            "password": password,
            "roommate names": roommatesNames,
            "roommates": roommates
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                completion(false)
                return
            }
            
            completion(true)
            print("User added successfully!")
        }

    }

    //Signs in the user using the given name and password
    func signIn(name: String, email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await auth.signIn(withEmail: email, password: password)
        let result = AuthDataResultModel(
            user: authDataResult.user
        )
        
        return result
    }
    
    func signOut() {
        do {
            try auth.signOut()
            print("successful sign-out")
        } catch {
            print("error signing out :(")
        }
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

//Returns all of the chores where user's groupKey = the chore's groupKey. This function should have optional parameters that let you filter the list of chores.
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
        "Date": date,//exact date
        "Day": day,//day of week
        "Description": description,
        "MonthlyRepeatByDate": monthlyrepeatbydate,
        "MonthlyRepeatByWeek": monthlyrepeatbyweek,
        "Name": Name,
        "PriorityLevel": PriorityLevel,
        "RepetitionTime": RepetitionTime,
        "TimeLength": TimeLength,
        "assignedUsers":assignedUsers,
        "completed": completed,
        "groupKey": groupKey//We should use the groupKey of the user who's currently logged in instead of it being an argument
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
        "groupKey": groupKey//We should use the groupKey of the user who's currently logged in instead of it being an argument
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

//Not cpmplete yet also need to change the way of implementation
func joinGroup(userId: String, groupId: String, completion: @escaping (Bool) -> Void){

    db.collection("groups").document(groupId).updateData([
        "members": userId
    ]) {err in
        if let err = err{
            print("Error joining group: \(err)")
            completion(false)
            return
        }
        
        print("User joined successfully!")
        
        completion(true)
    }
}
