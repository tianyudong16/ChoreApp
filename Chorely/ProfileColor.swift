//
//  ProfileColor.swift
//  Chorely
//
//  Created by Tian Yu Dong on 12/1/25.
//

import SwiftUI

// Available colors for user profiles
// Each user gets assigned a random color on registration
// Users can change their color in ProfileView
enum ProfileColor: String, CaseIterable, Identifiable {
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case yellow = "Yellow"
    case orange = "Orange"
    case purple = "Purple"
    case pink = "Pink"
    case cyan = "Cyan"
    case mint = "Mint"
    case teal = "Teal"
    
    // Required for Identifiable protocol
    var id: String { rawValue }
    
    // Converts enum to SwiftUI Color for display
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .cyan: return .cyan
        case .mint: return .mint
        case .teal: return .teal
        }
    }
    
    // Creates ProfileColor from a string (for loading from Firebase)
    // Returns a random color if string doesn't match any case
    static func fromString(_ string: String) -> ProfileColor {
        return ProfileColor(rawValue: string) ?? random()
    }
    
    // Finds ProfileColor that matches a SwiftUI Color
    // Returns a random color if no match found
    static func fromColor(_ color: Color) -> ProfileColor {
        for profileColor in ProfileColor.allCases {
            if profileColor.color == color {
                return profileColor
            }
        }
        return random()
    }
    
    // Returns a random color (used for new user registration)
    static func random() -> ProfileColor {
        return allCases.randomElement()!
    }
}
