//
//  GroupMember.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/12/25.
//

import Foundation
import FirebaseFirestore

struct GroupMember: Identifiable {
    var id: String { uid }
    
    let uid: String
    let name: String
    let photoURL: String
    let colorData: Data
    
    init(
        uid: String,
        name: String,
        photoURL: String,
        colorData: Data
    ) {
        self.uid = uid
        self.name = name
        self.photoURL = photoURL
        self.colorData = colorData
    }
    
    init(from doc: DocumentSnapshot) throws {
        guard let data = doc.data() else {
            throw NSError(domain: "GroupMember", code: 404)
        }
        
        self.uid = data["uid"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.photoURL = data["photoURL"] as? String ?? ""
        
        let base64 = data["colorData"] as? String ?? ""
        self.colorData = Data(base64Encoded: base64) ?? Data()
    }
}
