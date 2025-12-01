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

let db = FirebaseInterface.shared.firestore

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
    
    var votes: Int = 0
    var voters: [String]
    var proposal:  Bool  = false
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
    func addUser(
        name: String,
        email: String,
        color: String? = nil,
        groupKey: Int? = nil,
        groupName: String,
        password: String,
        roommatesNames: [String]? = []
    ) async throws -> AuthDataResultModel {
        print("Attempting to add user: \(name), \(groupName)")
        
        //This block of code authenticates the user using the Auth library, but does not add user data
        let authDataResult = try await auth.createUser(withEmail: email, password: password)
        let result = AuthDataResultModel(
            user: authDataResult.user
        )
        
        // I (Tian) created this groupKey randomizer for creating a new group
        // TODO: Perhaps a way to prevent generating duplicate numbers
        let newGroupKey = groupKey ?? Int.random(in: 100000...999999)
        let groupKeyString = String(newGroupKey)
        
        
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
    
    // Helper: Update single field
    func updateUserField(
        userID: String,
        field: String,
        value: Any) async throws {
        try await db.collection("Users").document(userID).updateData([field: value])
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
    //edited by Tian to be able to show which user completed the task
    func markComplete(userName: String, choreId: String, groupKey: String) async {
        do {
            let choreRef = db.collection("chores")
                .document("group")
                .collection(groupKey)
                .document(choreId)
            
            // Use a transaction to prevent race conditions
            try await db.runTransaction({ (transaction, errorPointer) -> Any? in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(choreRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                
                guard snapshot.exists else {
                    print("Chore not found: \(choreId)")
                    return nil
                }
                
                let data = snapshot.data() ?? [:]
                
                // Check if chore is already completed
                let isCompleted = data["completed"] as? Bool ?? false
                if isCompleted {
                    print("Chore already completed")
                    return nil
                }
                
                // Get current description (keep it unchanged)
                let currentDescription = data["Description"] as? String ?? ""
                
                // Update the document - DO NOT modify description
                transaction.updateData([
                    "completed": true,
                    "completedBy": userName,  // Store who completed it
                    "completedAt": Date().timeIntervalSince1970  // Store when
                ], forDocument: choreRef)
                
                return nil
                
            })
            
            print("Chore \(choreId) marked complete by \(userName)")
            
        } catch {
            print("Error marking complete: \(error)")
        }
    }
    //We need to make a chore log repository for this
    //Also, for repeating chores, we will need to make it so that the chore is marked as "uncomplete" before it's due again.
    
    //In progress, not yet completed
    func makeLogDoc(groupKey:String, completion: @escaping ([String: Any]?) -> Void) async throws {
        //This will create a new document called "Log" if it doesn't exist (or overwrite it if it does exist)
        //We should only ever call this function ONCE PER GROUP. If you run setData a second time, the log will be OVERWRITTEN
        
        //Just to make sure that we don't overwrite Log, I will add a precondition to make sure Log already exists
        db.collection("chores").document("group").collection(groupKey).document("Log").getDocument {snapshot, err in
            if let err = err {
                print("Error getting document: \(err)")
                return
            } else {
                if snapshot?.exists == true {
                    print("The Log already exists, ending the function here")
                    return
                }
            }
        }
        
        let groupKeyAsInt:Int? = (groupKey as NSString).integerValue
        do {
            let names = try await getGroupMembers(groupKey: groupKeyAsInt ?? 0)
            print(names)
        } catch {
            print("Error getting document: \(error)")
        }
        
        print("Attempting to add Log doc")
        db.collection("chores").document("group").collection(groupKey).document("Log").setData(
            [:]
            ) { err in
            if let err = err {
                print("Error adding Log doc: \(err)")
            } else {
                print("Log doc added successfully!")
            }
        }
        //Before I populate the Log, we need to decide: What kind of data is stored in the log? Do we need to know when the people completed the chores as a timestamp? Or just how many times each user completed each chore? What about having the log be an entirely separate collection with a list of docs, each doc representing a user completing the chore at a given time??? Depending on how much info we need to store, a single doc per group may not be enough
    }
    
    //This may be needed as a helper function for makeLogDoc or other functions
    func getGroupMembers(groupKey:Int) async throws -> [String] {
        let snapshot = try await db.collection("users")
            .whereField("groupKey", isEqualTo: groupKey)
            .getDocuments()
        
        return snapshot.documents.compactMap { $0.get("name") as? String }
    }
    
    //We won't implement this until we decide how the chore proposal system should work
    func getProposedChores(){
        
    }
    
    // New consolidated functions for chore and user operations
    
    // Extracts groupKey from user data, handling both Int and String types
    func extractGroupKey(from userData: [String: Any]) -> (string: String?, int: Int?) {
        var groupKeyString: String?
        var groupKeyInt: Int?
        
        if let intKey = userData["groupKey"] as? Int {
            groupKeyString = String(intKey)
            groupKeyInt = intKey
        } else if let strKey = userData["groupKey"] as? String {
            groupKeyString = strKey
            groupKeyInt = Int(strKey)
        } else if let intKey = userData["GroupKey"] as? Int {
            groupKeyString = String(intKey)
            groupKeyInt = intKey
        } else if let strKey = userData["GroupKey"] as? String {
            groupKeyString = strKey
            groupKeyInt = Int(strKey)
        }
        
        return (groupKeyString, groupKeyInt)
    }
    
    // Gets the groupKey for a specific user
    func getGroupKey(forUserID userID: String) async throws -> (string: String?, int: Int?) {
        let userData = try await getUserData(uid: userID)
        return extractGroupKey(from: userData)
    }
    
    // Sets up a real-time listener for chores in a group
    func addChoresListener(groupKey: String, onChange: @escaping ([QueryDocumentSnapshot]?, Error?) -> Void) -> ListenerRegistration {
        return db
            .collection("chores")
            .document("group")
            .collection(groupKey)
            .addSnapshotListener { querySnapshot, error in
                onChange(querySnapshot?.documents, error)
            }
    }
    
    // Sets up a real-time listener for group members
    func addGroupMembersListener(groupKey: Int, onChange: @escaping ([QueryDocumentSnapshot]?, Error?) -> Void) -> ListenerRegistration {
        return db
            .collection("Users")
            .whereField("groupKey", isEqualTo: groupKey)
            .addSnapshotListener { querySnapshot, error in
                onChange(querySnapshot?.documents, error)
            }
    }
    
    // just used to only toggle the chore completion. Different to markComplete
    func updateChoreCompletion(groupKey: String, choreId: String, completed: Bool, completion: ((Error?) -> Void)? = nil) {
        db
            .collection("chores")
            .document("group")
            .collection(groupKey)
            .document(choreId)
            .updateData(["completed": completed]) { error in
                if let error = error {
                    print("Error updating chore: \(error)")
                }
                completion?(error)
            }
    }
    
    // Deletes a chore from a group
    func deleteChore(groupKey: String, choreId: String, completion: ((Error?) -> Void)? = nil) {
        db.collection("chores")
            .document("group")
            .collection(groupKey)
            .document(choreId)
            .delete { error in
                if let error = error {
                    print("Error deleting chore: \(error)")
                }
                completion?(error)
            }
    }
    
    // Fetches all users in a group (non-listener version)
    func fetchGroupMembers(groupKey: Int, completion: @escaping ([QueryDocumentSnapshot]?, Error?) -> Void) {
        db
            .collection("Users")
            .whereField("groupKey", isEqualTo: groupKey)
            .getDocuments { querySnapshot, error in
                completion(querySnapshot?.documents, error)
            }
    }
    
    // Updates a specific field for a user by their userID
    func updateUserField(userID: String, field: String, value: Any, completion: ((Error?) -> Void)? = nil) {
        db
            .collection("Users")
            .document(userID)
            .updateData([field: value]) { error in
                if let error = error {
                    print("Error updating \(field): \(error)")
                }
                completion?(error)
            }
    }
    
    // Saves a new chore to Firebase and returns the document reference
    func saveChore(groupKey: String, choreData: [String: Any]) {
        
        let groupCollection = db.collection("chores")
            .document("group")
            .collection(groupKey)
        
        // Ensure parent group document exists (but with NO chore fields)
        let groupDoc = db.collection("chores")
            .document("group")
            .collection(groupKey)
            .document(groupKey)

        groupDoc.setData([
            "groupKey": groupKey,
            "createdAt": Date().timeIntervalSince1970
        ], merge: true)

        // Save the actual chore in the subcollection
        groupCollection.addDocument(data: choreData)
    }

    
    // Checks if a group exists by groupKey
    func checkGroupExists(groupKey: Int, completion: @escaping (Bool, [String: Any]?) -> Void) {
        db
            .collection("Users")
            .whereField("groupKey", isEqualTo: groupKey)
            .limit(to: 1)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error checking group: \(error)")
                    completion(false, nil)
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    completion(true, documents[0].data())
                } else {
                    completion(false, nil)
                }
            }
    }
    
    // Async version of checkGroupExists
    func checkGroupExistsAsync(groupKey: Int) async throws -> (exists: Bool, userData: [String: Any]?) {
        let snapshot = try await db
            .collection("Users")
            .whereField("groupKey", isEqualTo: groupKey)
            .limit(to: 1)
            .getDocuments()
        
        if let document = snapshot.documents.first {
            return (true, document.data())
        }
        return (false, nil)
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
        "votes": chore.votes,
        "voters": chore.voters,
        "proposal": chore.proposal
    ]) { err in
        if let err = err {
            print("Error adding chore: \(err)")
        } else {
            print("Chore added successfully!")
        }
    }
}

func editChore(documentId: String, chore: Chore, groupKey: String, completion: @escaping (Bool) -> Void){
    db.collection("chores").document("group").collection(groupKey).document(documentId).updateData([
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
        "votes": chore.votes,
        "voters": chore.voters,
        "proposal": chore.proposal
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
/*
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
*/
func joinGroup(userID: String, groupKey: Int) async throws {
    try await db.collection("Users")
        .document(userID)
        .updateData(["groupKey": groupKey])
}


func voteProposal(groupKey: String, choreId: String, userId: String, approved: Bool, completion: @escaping (Bool) -> Void) {
    
    let chore = db.collection("groups").document(groupKey).collection("chores").document(choreId)
    
    db.runTransaction({ (transaction, errorPointer) -> Any? in
        let snapshot: DocumentSnapshot
        do {
            snapshot = try transaction.getDocument(chore)
        } catch let error as NSError {
            errorPointer?.pointee = error
            return nil
        }

        var votes = snapshot.get("votes") as? Int ?? 0
        var voters = snapshot.get("voters") as? [String] ?? []
        var proposal = snapshot.get("proposal") as? Bool ?? false
        
        if voters.contains(userId) {
            return nil
        }

        
        votes += approved ? 1 : 0
        voters.append(userId)
        if votes > 4 {
            proposal = false
        }
        
        transaction.updateData([
            "votes": votes,
            "voters": voters,
            "proposal": proposal
        ], forDocument: chore)

        return

    }) { (result, err) in

        if let err = err {
            print("Vote failed: \(err)")
            completion(false)
            return
        }
        print("Vote succeeded")
        completion(true)
    }
}


//To do: Make it so that when joinGroup is run, we add the added user to the Log doc.
