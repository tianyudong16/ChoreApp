//
//  ColorDataExtensions.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/12/25.
//

import SwiftUI
import UIKit

// MARK: UIColor Extension
extension UIColor {
    
    //Converts UIColor to data for firebase storage purposes
    func toData() -> Data? {
        return try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
    
    //Decodes UIColor from data
    static func fromData(_ data: Data?) -> UIColor? {
        guard let data = data else { return nil }
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor
    }
}

// MARK: CGColor Extension
extension CGColor {
    
    //Converts CGColor to data for firestore
    func toData() -> Data? {
        // Convert self (CGColor) to UIColor, which IS archivable
        let uiColor = UIColor(cgColor: self)
        return try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
    }
}

// MARK: Data Extension
extension Data {
    
    //Converts stored data to CGColor
    func toCGColor() -> CGColor? {
        // We must unarchive as a UIColor, then get its .cgColor
        if let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(self) as? UIColor {
            return uiColor.cgColor
        }
        return nil // Return nil if it fails
    }
}

// MARK: Color Extension
extension Color {
    //Creates a SwiftUI Color from CGColor data
    static func fromData(_ data: Data?) -> Color {
        guard let cg = data?.toCGColor() else {
            return .gray
        }
        return Color(cgColor: cg)
    }
}
