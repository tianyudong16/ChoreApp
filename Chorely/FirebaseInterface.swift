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
    var proposal: Bool = false
    var createdBy: String = ""
    var seriesId: String = "" // Links all chores in a repeating series together
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
        //Note: This line of code will only run if no groupKey is provided.
        //However, a unique groupKey will be provided if you run this function using registerWithGroupCode.
        //This line will run, however, if the execution stack is ->register->createUser->addUser, ie. a user creates an account without joining an existing group.
        let newGroupKey = groupKey ?? Int.random(in: 100000...999999)
        
        // When a user first creates their account, they are assigned a random color
        // The color struct is located in ProfileColor
        let assignedColor = color ?? ProfileColor.random().rawValue
        
        
        //This block of code adds user information to the Users collection (written by Ron, added to by Milo)
        do {
            try await db.collection("Users").document(result.uid).setData([
                "Email": email,
                "Name": name,
                "color": color ?? assignedColor,
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
    
    // Marks a chore as complete
    func markComplete(userName: String, choreId: String, groupKey: String) async {
        let choreRef = db.collection("chores")
            .document("group")
            .collection(groupKey)
            .document(choreId)
        
        do {
            try await choreRef.updateData([
                "completed": true,
                "completedBy": userName,
                "completedAt": Date().timeIntervalSince1970
            ])
            print("Chore \(choreId) marked complete by \(userName)")
        } catch {
            print("Error marking complete: \(error)")
        }
        
        //added by Milo
        do {
            try await recordChore(groupKey: groupKey, choreId: choreId)
        }
        catch {
            print("Error running recordChore: \(error)")
        }
    }
    
    //This function writes to the log, making an entry that records that the user who is currently logged in completed the chore at the current time, as well as a reference to the user and the chore.
    //Implemented by Milo on 12/2/25
    func recordChore(groupKey:String, choreId: String) async throws {
        //let groupKeyAsInt:Int? = (groupKey as NSString).integerValue
        guard let userId = Auth.auth().currentUser?.uid else {
            print("error getting userID")
            return
        }//Grab the current users uid
        let userRefStrings = [db.collection("Users").document(userId).documentID]//Get a reference to the currently logged in user's doc & save it as an array
        let userRefs = userRefStrings.map { id in
            db.collection("users").document(id)
        }//convert it to an array of document references
        
        let choreRefString = db.collection("chores").document("group").collection(groupKey).document(choreId)
        let choreRef = db.document(choreRefString.path)//Get a reference to the chore's path
        
        print("Attempting to log the chore...")
        db.collection("chores").document("group").collection(groupKey).document("Logs").collection("ChoreLog").addDocument(
            data: [
                "timestamp": Timestamp(date: Date()),
                "chore": choreRef,
                "whoDidIt": userRefs,
            ]
        ) { err in
            if let err = err {
                print("Error logging the chore: \(err)")
            } else {
                print("Chore logged successfully!")
            }
        }
    }
    
    //Overloaded version of recordChore where uid is given directly
    func recordChore(groupKey:String, choreId: String, uid: String) async throws {
        //let groupKeyAsInt:Int? = (groupKey as NSString).integerValue
        let userRefStrings = [db.collection("Users").document(uid).documentID]//Get a reference to the given user's doc & save it as an array
        let userRefs = userRefStrings.map { id in
            db.collection("users").document(id)
        }//convert it to an array of document references
        
        let choreRefString = db.collection("chores").document("group").collection(groupKey).document(choreId)
        let choreRef = db.document(choreRefString.path)//Get a reference to the chore's path
        
        print("Attempting to log the chore...")
        db.collection("chores").document("group").collection(groupKey).document("Logs").collection("ChoreLog").addDocument(
            data: [
                "timestamp": Timestamp(date: Date()),
                "chore": choreRef,
                "whoDidIt": userRefs,
            ]
        ) { err in
            if let err = err {
                print("Error logging the chore: \(err)")
            } else {
                print("Chore logged successfully!")
            }
        }
    }
    
    //Similar to recordChore, except we mark the chore as being completed by the user(s) who were assigned to do the chore.
    //Edit: We should not use this function anymore - it is functionality that isn't in our system requirements, and would be an
    //unnecessary burden on our other functions
    /*
     func recordChoreDoneByAssigned(groupKey:String, choreId: String) async throws {
     //let groupKeyAsInt:Int? = (groupKey as NSString).integerValue
     
     let choreRefString = db.collection("chores").document("group").collection(groupKey).document(choreId)
     let choreRef = db.document(choreRefString.path)//Get a reference to the chore's path
     
     //Grab the usernames from the choreRef
     guard let userRefNames = try await choreRef.getDocument().get("assignedUsers") else {
     print("error getting chore doc data")
     return
     }
     //Convert userRefNames to a list of userRefs
     
     print("Attempting to log the chore...")
     db.collection("chores").document("group").collection(groupKey).document("Logs").collection("ChoreLog").addDocument(
     data: [
     "timestamp": Timestamp(date: Date()),
     "chore": choreRef,
     "whoDidIt": userRefs,
     ]
     ) { err in
     if let err = err {
     print("Error logging the chore: \(err)")
     } else {
     print("Chore logged successfully!")
     }
     }
     }*/
    
    //Returns all chores for a given user
    //duration 0 = for all time, 1 = for past month, 2 = for past week
    func getLogChores(uid: String, groupKey:String, duration:Int) async throws -> [String] {
        let userRefPath = db.collection("users").document(uid).path//Forgot to store it as a path
        print("Accessing the chore log...")
        let snapshot = try await db.collection("chores").document("group").collection(groupKey).document("Logs").collection("ChoreLog").whereField("whoDidIt", arrayContains: userRefPath).getDocuments()
        return snapshot.documents.compactMap { $0.get("chore") as? String }
    }
    
    func getNumLogChores(uid: String, groupKey:String, duration:Int) async throws -> Int {
        let userRefPath = db.collection("users").document(uid).path//Forgot to store it as a path
        print("Accessing the chore log...")
        let choreCount = try await db.collection("chores").document("group").collection(groupKey).document("Logs").collection("ChoreLog").whereField("whoDidIt", arrayContains: userRefPath).getDocuments().count
        return choreCount
    }
    
    //This will calculate the user's score for chore equity purposes
    //func calculateScoreForUser(uid: String, groupKey:String, duration:Int) async throws -> [Int] {
        
    //}
    
    /*
     //milo's private func for testing log once I can find a place to test it
     private func testing() async {
         guard let userId = Auth.auth().currentUser?.email else {return}
         do {
             let userData = try await FirebaseInterface.shared.getUserData(uid: FirebaseInterface.shared)
             let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
             let userLog = FirebaseInterface.shared.getLogChores(uid: userID, groupKey: keys?, duration: 0)
             print(userLog)
         } catch {
             print("Error loading user data: \(error)")
         }
     */
    
    // Generates all future occurrences for a repeating chore
    // Creates chores up to 3 months in advance
    func generateRepetitions(for chore: Chore, groupKey: String, seriesId: String) {
        guard chore.repetitionTime != "None" && !chore.repetitionTime.isEmpty else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = dateFormatter.date(from: chore.date) else {
            print("Could not parse date: \(chore.date)")
            return
        }
        
        let calendar = Calendar.current
        
        // Generate 1 year of repetitions from the start date
        let endDate = calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        
        var currentDate = startDate
        var isFirst = true
        var count = 0
        
        while currentDate <= endDate {
            // Skip the first one since it's already created
            if !isFirst {
                let dateStr = dateFormatter.string(from: currentDate)
                
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEEE"
                let dayStr = dayFormatter.string(from: currentDate)
                
                let newChore = Chore(
                    checklist: chore.checklist,
                    date: dateStr,
                    day: dayStr,
                    description: chore.description,
                    monthlyRepeatByDate: chore.monthlyRepeatByDate,
                    monthlyRepeatByWeek: chore.monthlyRepeatByWeek,
                    name: chore.name,
                    priorityLevel: chore.priorityLevel,
                    repetitionTime: chore.repetitionTime,
                    timeLength: chore.timeLength,
                    assignedUsers: chore.assignedUsers,
                    completed: false,
                    voters: [],
                    proposal: false,
                    createdBy: chore.createdBy,
                    seriesId: seriesId
                )
                
                addChore(chore: newChore, groupKey: groupKey)
                count += 1
            }
            isFirst = false
            
            // Calculate next date
            switch chore.repetitionTime.lowercased() {
            case "daily":
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case "weekly":
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case "monthly":
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            case "yearly":
                currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
            default:
                return
            }
        }
        
        print("Generated \(count) repetitions for \(chore.name) until \(dateFormatter.string(from: endDate))")
    }
    
    // Deletes all future occurrences of a repeating chore series
    func deleteFutureOccurrences(seriesId: String, fromDate: String, groupKey: String, completion: ((Error?) -> Void)? = nil) {
        guard !seriesId.isEmpty else {
            completion?(nil)
            return
        }
        
        // Query all chores with this seriesId and date >= fromDate
        db.collection("chores")
            .document("group")
            .collection(groupKey)
            .whereField("seriesId", isEqualTo: seriesId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching series: \(error)")
                    completion?(error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion?(nil)
                    return
                }
                
                let batch = self.firestore.batch()
                
                for doc in documents {
                    let choreDate = doc.data()["Date"] as? String ?? ""
                    // Delete if date is >= fromDate
                    if choreDate >= fromDate {
                        batch.deleteDocument(doc.reference)
                    }
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting future occurrences: \(error)")
                    } else {
                        print("Deleted future occurrences for series \(seriesId)")
                    }
                    completion?(error)
                }
            }
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
    

    
    // HELPER FUNCTIONS ADDED FOR VIEWMODEL SUPPORT (by Tian)
    
    // Extracts groupKey from user data, handling both Int and String types
    // Returns tuple with both string and int versions for flexibility
    // userData: Dictionary from getUserData
    // Returns: (string version, int version) - either may be nil
    func extractGroupKey(from userData: [String: Any]) -> (string: String?, int: Int?) {
        var groupKeyString: String?
        var groupKeyInt: Int?
        
        // Handle groupKey stored as Int
        if let intKey = userData["groupKey"] as? Int {
            groupKeyString = String(intKey)
            groupKeyInt = intKey
        }
        // Handle groupKey stored as String
        else if let strKey = userData["groupKey"] as? String {
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
    // Used by CalendarViewModel and ChoresViewModel
    // Parameters:
    //   groupKey: The group's key (as string)
    //   onUpdate: Callback with array of document snapshots
    // Returns: ListenerRegistration to remove listener when done
    func addChoresListener(groupKey: String, onChange: @escaping ([QueryDocumentSnapshot]?, Error?) -> Void) -> ListenerRegistration {
        return db
            .collection("chores")
            .document("group")
            .collection(groupKey)
            .addSnapshotListener { querySnapshot, error in
                onChange(querySnapshot?.documents, error)
            }
    }
    
    // Sets up real-time listener for group members
    // Used by CalendarViewModel to get member colors
    // Parameters:
    //   groupKey: The group's numeric key
    //   onUpdate: Callback with array of document snapshots
    // Returns: ListenerRegistration to remove listener when done
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
        db.collection("Users")
            .whereField("groupKey", isEqualTo: groupKey)
            .getDocuments {
                querySnapshot, error in
                    completion(querySnapshot?.documents, error)
            }
    }
    
    // Updates a single field in a user's document by their userID
    // Used by ProfileView to save name and color changes
    // Parameters:
    //   userID: Firebase UID of the user
    //   field: Name of the field to update
    //   value: New value for the field
    //   completion: Callback with error (nil on success)
    func updateUserField(userID: String, field: String, value: Any, completion: ((Error?) -> Void)? = nil) {
        db.collection("Users")
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
    // Used during registration when joining existing group
    // Parameters:
    //   groupKey: The 6-digit group code to check
    // Returns: (exists: Bool, userData: first user's data if found)
    func checkGroupExists(groupKey: Int, completion: @escaping (Bool, [String: Any]?) -> Void) {
        db.collection("Users")
          .whereField("groupKey",isEqualTo: groupKey)
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
        "Date": chore.date,
        "Day": chore.day,
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
        "proposal": chore.proposal,
        "createdBy": chore.createdBy,
        "seriesId": chore.seriesId
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
        "Date": chore.date,
        "Day": chore.day,
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
        "proposal": chore.proposal,
        "createdBy": chore.createdBy,
        "seriesId": chore.seriesId
    ]) { err in
        if let err = err {
            print("Error editing chore: \(err)")
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
