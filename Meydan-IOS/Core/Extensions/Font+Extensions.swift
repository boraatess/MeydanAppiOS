import SwiftUI

struct AppFont {
    // Manrope Fontları
    static let manropeRegular = "Manrope-Regular"
    static let manropeMedium = "Manrope-Medium"
    static let manropeSemiBold = "Manrope-SemiBold"
    static let manropeBold = "Manrope-Bold"
    static let manropeExtraBold = "Manrope-ExtraBold"
    static let manropeLight = "Manrope-Light"
    static let manropeExtraLight = "Manrope-ExtraLight"

    // Poppins Fontları
    static let poppinsRegular = "Poppins-Regular"
    static let poppinsItalic = "Poppins-Italic"
    static let poppinsThin = "Poppins-Thin"
    static let poppinsThinItalic = "Poppins-ThinItalic"
    static let poppinsExtraLight = "Poppins-ExtraLight"
    static let poppinsExtraLightItalic = "Poppins-ExtraLightItalic"
    static let poppinsLight = "Poppins-Light"
    static let poppinsLightItalic = "Poppins-LightItalic"
    static let poppinsMedium = "Poppins-Medium"
    static let poppinsMediumItalic = "Poppins-MediumItalic"
    static let poppinsSemiBold = "Poppins-SemiBold"
    static let poppinsSemiBoldItalic = "Poppins-SemiBoldItalic"
    static let poppinsBold = "Poppins-Bold"
    static let poppinsBoldItalic = "Poppins-BoldItalic"
    static let poppinsExtraBold = "Poppins-ExtraBold"
    static let poppinsExtraBoldItalic = "Poppins-ExtraBoldItalic"
    static let poppinsBlack = "Poppins-Black"
    static let poppinsBlackItalic = "Poppins-BlackItalic"
}

extension Font {
    
    // MARK: - Manrope
    static func manrope(_ style: ManropeStyle, size: CGFloat) -> Font {
        return .custom(style.name, size: size)
    }
    
    enum ManropeStyle {
        case regular, medium, semiBold, bold, extraBold, light, extraLight
        
        var name: String {
            switch self {
            case .regular: return AppFont.manropeRegular
            case .medium: return AppFont.manropeMedium
            case .semiBold: return AppFont.manropeSemiBold
            case .bold: return AppFont.manropeBold
            case .extraBold: return AppFont.manropeExtraBold
            case .light: return AppFont.manropeLight
            case .extraLight: return AppFont.manropeExtraLight
            }
        }
    }
    
    // MARK: - Poppins
    static func poppins(_ style: PoppinsStyle, size: CGFloat) -> Font {
        return .custom(style.name, size: size)
    }

    enum PoppinsStyle {
        case regular, italic, thin, thinItalic, extraLight, extraLightItalic, light, lightItalic, medium, mediumItalic, semiBold, semiBoldItalic, bold, boldItalic, extraBold, extraBoldItalic, black, blackItalic
        
        var name: String {
            switch self {
            case .regular: return AppFont.poppinsRegular
            case .italic: return AppFont.poppinsItalic
            case .thin: return AppFont.poppinsThin
            case .thinItalic: return AppFont.poppinsThinItalic
            case .extraLight: return AppFont.poppinsExtraLight
            case .extraLightItalic: return AppFont.poppinsExtraLightItalic
            case .light: return AppFont.poppinsLight
            case .lightItalic: return AppFont.poppinsLightItalic
            case .medium: return AppFont.poppinsMedium
            case .mediumItalic: return AppFont.poppinsMediumItalic
            case .semiBold: return AppFont.poppinsSemiBold
            case .semiBoldItalic: return AppFont.poppinsSemiBoldItalic
            case .bold: return AppFont.poppinsBold
            case .boldItalic: return AppFont.poppinsBoldItalic
            case .extraBold: return AppFont.poppinsExtraBold
            case .extraBoldItalic: return AppFont.poppinsExtraBoldItalic
            case .black: return AppFont.poppinsBlack
            case .blackItalic: return AppFont.poppinsBlackItalic
            }
        }
    }
}
