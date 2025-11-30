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
struct Chore {
    var checklist: Bool = false
    var date: String
    var day: String
    var description: String = " "
    var monthlyRepeatByDate: Bool = false
    var monthlyRepeatByWeek: String = " "
    var name: String
    var priorityLevel: String = "low"
    var repetitionTime: String
    var timeLength: Int
    var assignedUsers: [String]
    var completed: Bool = false
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
    func addUser(name: String, email: String, color: String? = nil, groupKey: Int? = nil, groupName: String, password: String, roommatesNames: [String]? = []) async throws -> AuthDataResultModel {
        print("Attempting to add user: \(name), \(groupName)")
        
        //This block of code authenticates the user using the Auth library, but does not add user data
        let authDataResult = try await auth.createUser(withEmail: email, password: password)
        let result = AuthDataResultModel(
            user: authDataResult.user
        )
        
        // I (Tian) created this groupKey randomizer for creating a new group
        // TODO: Perhaps a way to prevent generating duplicate numbers
        let newGroupKey = groupKey ?? Int.random(in: 100000...999999)
        
        //This block of code adds user information to the Users collection (written by Ron, added to by Milo)
        do {
            try await db.collection("Users").document(result.uid).setData([
                "Email": email,
                "Name": name,
                "color": color ?? "Green",
                "groupKey": newGroupKey,
                "groupName": groupName,
                "password": password,
                "roommate names": roommatesNames ?? [],
            ])
            print("User added successfully!")
        } catch {
            print("Error adding document: \(error)")
            throw error // added this line for error handling
        }

        return result
    }

    //This edits an existing user. Any number of the parameters can be empty
    func editUser(name: String? = nil, email: String? = nil, color: String? = nil, groupKey: Int? = nil, groupName: String? = nil, password: String? = nil, roommatesNames: [String]? = nil) async throws {
        guard let userId = Auth.auth().currentUser?.email else {return}//This ensures the current user is signed in
        let documentId = db.collection("Users").document(userId).documentID//This is the document ID associated with the currently signed-in user.
        
        //We need to try-await for each attribute individually, since the updateData function will actually accept nil values and blank those values. EditAttribute contains the code which actually edits the firebase document.
        do {
            if let nameLocal = name {//This ensures that if the name field is empty, we don't change the existing name
                try await editAttribute(attributeName: "Name", newValue: nameLocal, documentId: documentId)
            }
            if let emailLocal = email {
                try await editAttribute(attributeName: "Email", newValue: emailLocal, documentId: documentId)
            }
            if let colorLocal = color {
                try await editAttribute(attributeName: "color", newValue: colorLocal, documentId: documentId)
            }
            if let groupLocal = groupKey {
                try await editAttribute(attributeName: "groupKey", newValue: groupLocal, documentId: documentId)
            }
            if let groupNameLocal = groupName {
                try await editAttribute(attributeName: "groupName", newValue: groupNameLocal, documentId: documentId)
            }
            if let passwordLocal = password {
                try await editAttribute(attributeName: "password", newValue: passwordLocal, documentId: documentId)
            }
            if let roommatesLocal = roommatesNames {
                try await editAttribute(attributeName: "roommate names", newValue: roommatesLocal, documentId: documentId)
            }
        } catch {
            print("Error editing user: \(error)")
        }
    }
    
    //A private function to help streamline editUser, it would be too bloated if we had to put this whole block for each thing individually.
    private func editAttribute(attributeName: String, newValue: Any, documentId: String) async throws {
        //attributeName is the name of the field we are changing (ex. password)
        do {
            //We only edit the document one attribute at a time.
            try await db.collection("Users").document(documentId).updateData([
                attributeName: newValue
            ])
            //Unlike the setData function, we don't need to specify merge, and the other attributes are untouched
            print("Succesfully added \(attributeName)")
        } catch {
            print("Error editing  \(attributeName): \(error)")
            return //error case
        }
        return//successful case
    }

    //Signs in the user using the given name and password
    func signIn(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await auth.signIn(withEmail: email, password: password)
        let result = AuthDataResultModel(
            user: authDataResult.user
        )
        
        return result
    }
    
    // getUserData function
    func getUserData(uid: String) async throws -> [String: Any] {
        let document = try await firestore.collection("Users").document(uid).getDocument()
        guard let data = document.data() else {
            // Return empty dictionary if no data found
            return [:]
        }
        return data
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
    //userName is for passing down the string of the name of user who did the chore
    //choreId is the documentation id of the chore and should be just the name of the chore
    //groupKey is the groupKey of the chore
    //Implemented by Ron on 11.30.2025
    func markComplete(userName: String, choreId: String, groupKey: String){
        let chore = db.collection("chores").document("groups").collection(groupKey).document(choreId)
        
        chore.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching chore: \(error)")
                return
            }

            let data = snapshot?.data() ?? [:]
            let oldDescription = data["Description"] as? String ?? ""

            let newDescription = oldDescription + "\n\(userName) did the chore."

            chore.updateData([
                "completed": true,
                "Description": newDescription
            ]) { error in
                if let error = error {
                    print("Error marking complete: \(error)")
                } else {
                    print("Chore \(choreId) marked complete by \(userName)")
                }
            }
        }
    }
    //We need to make a chore log repository for this
    //Also, for repeating chores, we will need to make it so that the chore is marked as "uncomplete" before it's due again.
    
    //We won't implement this until we decide how the chore proposal system should work
    func getProposedChores(){
        
    }
}

//Returns all of the chores where user's groupKey = the chore's groupKey. This function should have optional parameters that let you filter the list of chores.
func getChore(documentId: String, groupKey:String, completion: @escaping ([String: Any]?) -> Void)
{
    db.collection("chores").document("group").collection(groupKey).document(documentId).getDocument{snapshot,
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

func addChore(chore: Chore, groupKey: String){
    db.collection("chores").document("group").collection(groupKey).addDocument(data: [
        "Checklist": chore.checklist,
        "Date": chore.date,//exact date
        "Day": chore.day,//day of week
        "Description": chore.description,
        "MonthlyRepeatByDate": chore.monthlyRepeatByDate,
        "MonthlyRepeatByWeek": chore.monthlyRepeatByWeek,
        "Name": chore.name,
        "PriorityLevel": chore.priorityLevel,
        "RepetitionTime": chore.repetitionTime,
        "TimeLength": chore.timeLength,
        "assignedUsers": chore.assignedUsers,
        "completed": chore.completed,
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

//userId is the documentId of the user
//function is to change the groupKey of user to the group's groupKey
//created by Ron on 11.19
func joinGroup(userId: String, groupKey: Int) async {
    do {
        let userData = db.collection("users").document(userId)
        let snapshot = try await userData.getDocument()
        guard snapshot.exists else{
            print("User document not found for id \(userId)")
            return
        }
        try await userData.updateData(["groupKey": groupKey])
        print("Updated groupkey for user \(userId)")
    } catch {
        print("Failed to join", error)
    }
}
