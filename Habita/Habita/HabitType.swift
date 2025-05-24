//
//  HabitType.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

enum HabitType: String, CaseIterable {
    case quantitative = "Quantitative"
    case qualitative = "Qualitative"
    case scalable = "Scalable"
    
    var description: String {
        switch self {
        case .quantitative: return "Quantitative"
        case .qualitative: return "Qualitative"
        case .scalable: return "Scalable"
        }
    }
    
    var icon: String {
        switch self {
        case .quantitative: return "checkmark.circle"
        case .qualitative: return "number.circle"
        case .scalable: return "slider.horizontal.3"
        }
    }
}
