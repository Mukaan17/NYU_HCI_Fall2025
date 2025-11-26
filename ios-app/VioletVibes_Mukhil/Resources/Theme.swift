//
//  Theme.swift
//  VioletVibes
//

import SwiftUI

struct Theme {
    // MARK: - Colors
    struct Colors {
        static let background = Color(hex: "0b132b")
        static let backgroundSecondary = Color(hex: "0d1630")
        static let backgroundCard = Color(hex: "1c2541")
        static let backgroundCardDark = Color(hex: "151e38")
        static let backgroundOverlay = Color(hex: "0b132b").opacity(0.95)
        static let backgroundPrimary = Color(hex: "0b132b")
        
        static let gradientStart = Color(hex: "6c63ff")
        static let gradientEnd = Color(hex: "8b7fff")
        static let gradientBlueStart = Color(hex: "38c4fc")
        static let gradientBlueEnd = Color(hex: "76caf5")
        
        static let textPrimary = Color(hex: "ffffff")
        static let textSecondary = Color(hex: "a9b4d1")
        static let textAccent = Color(hex: "cbb8ff")
        static let textBlue = Color(hex: "68d4ff")
        static let textError = Color(hex: "ff3b30")
        
        static let border = Color.white.opacity(0.1)
        static let borderLight = Color.white.opacity(0.05)
        static let borderMedium = Color.white.opacity(0.2)
        
        static let accentPurple = Color(hex: "6c63ff").opacity(0.1)
        static let accentPurpleMedium = Color(hex: "6c63ff").opacity(0.2)
        static let accentBlue = Color(hex: "68d4ff").opacity(0.1)
        static let accentBlueMedium = Color(hex: "68d4ff").opacity(0.2)
        static let accentPurpleText = Color(hex: "cbb8ff").opacity(0.1)
        
        static let accentError = Color(hex: "ff3b30").opacity(0.1)
        static let accentErrorMedium = Color(hex: "ff3b30").opacity(0.2)
        static let accentErrorBorder = Color(hex: "ff3b30").opacity(0.5)
        
        static let glassBackground = Color(hex: "1c2541").opacity(0.6)
        static let glassBackgroundLight = Color(hex: "1c2541").opacity(0.8)
        static let glassBackgroundDark = Color(hex: "151e38").opacity(0.6)
        static let glassBackgroundDarkLight = Color(hex: "151e38").opacity(0.8)
        
        static let whiteOverlay = Color.white.opacity(0.05)
        static let whiteOverlayLight = Color.white.opacity(0.1)
        static let whiteOverlayMedium = Color.white.opacity(0.2)
    }
    
    // MARK: - Typography
    struct Typography {
        enum FontWeight {
            case regular
            case medium
            case semiBold
            case bold
            
            var value: Font.Weight {
                switch self {
                case .regular: return .regular
                case .medium: return .medium
                case .semiBold: return .semibold
                case .bold: return .bold
                }
            }
        }
        
        enum FontSize: CGFloat {
            case xs = 12
            case sm = 13
            case base = 14
            case md = 15
            case lg = 16
            case xl = 17
            case `2xl` = 20
            case `3xl` = 32
            
            var value: CGFloat { rawValue }
        }
        
        enum LineHeight: CGFloat {
            case tight = 18
            case normal = 19.5
            case relaxed = 21
            case loose = 22
            case xl = 24
            case `2xl` = 26
            case `3xl` = 38.4
            
            var value: CGFloat { rawValue }
        }
        
        static let heading: CGFloat = 32
        static let body: CGFloat = 14
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 10
        static let xl: CGFloat = 12
        static let `2xl`: CGFloat = 16
        static let `3xl`: CGFloat = 20
        static let `4xl`: CGFloat = 24
        static let `5xl`: CGFloat = 40
        static let `6xl`: CGFloat = 48
    }
    
    // MARK: - Border Radius
    struct BorderRadius {
        static let sm: CGFloat = 6.8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 48
        static let full: CGFloat = 1000
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let primary = Shadow(color: Color(hex: "6c63ff"), offset: CGSize(width: 0, height: 10), radius: 15, opacity: 0.3)
        static let card = Shadow(color: .black, offset: CGSize(width: 0, height: 4), radius: 12, opacity: 0.25)
        static let message = Shadow(color: Color(hex: "6c63ff"), offset: CGSize(width: 0, height: 4), radius: 6, opacity: 0.2)
    }
    
    struct Shadow {
        let color: Color
        let offset: CGSize
        let radius: CGFloat
        let opacity: Double
    }
}

// MARK: - View Modifiers
extension View {
    func themeFont(size: Theme.Typography.FontSize, weight: Theme.Typography.FontWeight = .regular) -> some View {
        self.font(.system(size: size.value, weight: weight.value))
    }
    
    func themeShadow(_ shadow: Theme.Shadow) -> some View {
        self.shadow(color: shadow.color.opacity(shadow.opacity), radius: shadow.radius, x: shadow.offset.width, y: shadow.offset.height)
    }
}

