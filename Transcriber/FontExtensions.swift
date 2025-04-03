import SwiftUI

extension Font {
    static func golosText(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return .custom("GolosText-Bold", size: size)
        case .semibold:
            return .custom("GolosText-SemiBold", size: size)
        case .medium:
            return .custom("GolosText-Medium", size: size)
        case .black:
            return .custom("GolosText-Black", size: size)
        case .heavy:
            return .custom("GolosText-ExtraBold", size: size)
        default:
            return .custom("GolosText-Regular", size: size)
        }
    }

    static func logoText(size: CGFloat) -> Font {
        // Use the correct PostScript name for the font
        return .custom("EvasSignaturesRegular", size: size)
    }
}
