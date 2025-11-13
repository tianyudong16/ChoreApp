//
//  UserInfo.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/12/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct UserInfo: Identifiable, Codable {
    var id: String { uid }
    
    let uid: String
    var name: String
    var email: String
    var groupID: String
    var photoURL: String
    var colorData: Data   // UIColor archived as Data
    
    // Convert stored Data -> Color
    var color: Color {
        return Color.fromData(colorData)
    }
    
    // Convert stored Data -> CGColor
    var cgColor: CGColor {
        if let cg = colorData.toCGColor() {
            return cg
        }
        return UIColor.gray.cgColor
    }
    
    // Added a memberwise init so we can create this object for previews
    init(uid: String, name: String, email: String, groupID: String, photoURL: String, colorData: Data) {
        self.uid = uid
        self.name = name
        self.email = email
        self.groupID = groupID
        self.photoURL = photoURL
        self.colorData = colorData
    }
}

extension UserInfo {
    // Create a UserInfo from a Firestore document
    init(from doc: DocumentSnapshot) throws {
        let data = doc.data() ?? [:]
        
        self.uid = data["uid"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.groupID = data["groupID"] as? String ?? ""
        self.photoURL = data["photoURL"] as? String ?? ""
        
        if let colorString = data["colorData"] as? String,
           let colorData = Data(base64Encoded: colorString) {
            self.colorData = colorData
        } else {
            // Default to pink
            // Must archive a UIColor
            self.colorData = (try? NSKeyedArchiver.archivedData(
                withRootObject: UIColor.systemPink,
                requiringSecureCoding: true
            )) ?? Data()
        }
    }
}
