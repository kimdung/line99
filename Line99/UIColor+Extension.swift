//
//  UIColor+Extension.swift
//  Line99
//
//  Created by Ngoc Nguyen on 10/04/2023.
//

import Foundation
import UIKit

extension UIColor {

    public convenience init(hex: String) {
        var hexStr: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if (hexStr.hasPrefix("#")) {
            hexStr.remove(at: hexStr.startIndex)
        }

        let scanner = Scanner(string: hexStr)
        var hexNumber: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        if scanner.scanHexInt64(&hexNumber) {
            if hexStr.count == 8 {
                r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                a = CGFloat(hexNumber & 0x000000ff) / 255
            } else if hexStr.count == 6 {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                a = 1
            }
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF),
            green: CGFloat((rgb >> 8) & 0xFF),
            blue: CGFloat(rgb & 0xFF),
            alpha: a
        )
    }

    class func liBlackColor() -> UIColor {
        return UIColor(white: 36.0 / 255.0, alpha: 1.0)
    }

    class func liDarkGreyColor() -> UIColor {
        return UIColor(red: 111.0 / 255.0, green: 116.0 / 255.0, blue: 118.0 / 255.0, alpha: 1.0)
    }

    class func liLightGreyColor() -> UIColor {
        return UIColor(red: 148.0 / 255.0, green: 154.0 / 255.0, blue: 157.0 / 255.0, alpha: 1.0)
    }

    class func liGreyBorderOneColor() -> UIColor {
        return UIColor(red: 197.0 / 255.0, green: 201.0 / 255.0, blue: 202.0 / 255.0, alpha: 1.0)
    }

    //sdfasdf
    class func liGreyBorderTwoColor() -> UIColor {
        return UIColor(red: 226.0 / 255.0, green: 230.0 / 255.0, blue: 232.0 / 255.0, alpha: 1.0)
    }

    class func liLightNavyColor() -> UIColor {
        return UIColor(red: 16.0 / 255.0, green: 104.0 / 255.0, blue: 145.0 / 255.0, alpha: 1.0)
    }

    class func liLightNavy103Color() -> UIColor {
        return UIColor(red: 16.0 / 255.0, green: 103.0 / 255.0, blue: 145.0 / 255.0, alpha: 1.0)
    }

    class func liDarknavyColor() -> UIColor {
        return UIColor(red: 7.0 / 255.0, green: 40.0 / 255.0, blue: 56.0 / 255.0, alpha: 1.0)
    }

    class func liLiveRedColor() -> UIColor {
        return UIColor(red: 250.0 / 255.0, green: 71.0 / 255.0, blue: 83.0 / 255.0, alpha: 1.0)
    }

    class func liWhiteColor() -> UIColor {
        return UIColor(red: 250.0 / 255.0, green: 250.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0)
    }

    /**
     スタイルガイドには無い、透過白色

     - parameter alpha: 透明度

     - returns: 透過白色
     */
    class func liClearWhiteColor(_ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 250.0 / 255.0, green: 250.0 / 255.0, blue: 250.0 / 255.0, alpha: alpha)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClearBlackColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.75)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClear69WhiteColor() -> UIColor {
        return UIColor(white: 1.0, alpha: 0.69)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClear80WhiteColor() -> UIColor {
        return UIColor(white: 1.0, alpha: 0.8)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClear59BlackColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.59)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClear60BlackColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.6)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClear45BlackColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.45)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClear30BlackColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.3)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClear20BlackColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.2)
    }

    /**
     スタイルガイドには無い、透過黒色

     - returns: 透過黒色
     */
    class func liClear85BlackColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.85)
    }

    /**
     スタイルガイドには無い、透過色(マスクのfrom)

     - returns: 透過色(マスクのfrom)
     */
    class func liClearMaskFromColor() -> UIColor {
        return UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.0)
    }

    /**
     スタイルガイドには無い、透過色(マスクのto)

     - returns: 透過色(マスクのto)
     */
    class func liClearMaskToColor() -> UIColor {
        return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.70)
    }

    /**
     スタイルガイドには無い、特集画面の透過色(マスクのfrom)

     - returns: 透過色(マスクのfrom)
     */
    class func liClearMaskFeatureFromColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.6)
    }

    /**
     スタイルガイドには無い、特集画面の透過色(マスクのto)

     - returns: 透過色(マスクのto)
     */
    class func liClearMaskFeatureToColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.0)
    }

    /**
     スタイルガイドには無い、ライブプレイヤーの透過色(マスクのfrom)

     - returns: 透過色(マスクのfrom)
     */
    class func liClearMaskLiveFooterFromColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.0)
    }

    /**
     スタイルガイドには無い、ライブプレイヤーの透過色(マスクのto)

     - returns: 透過色(マスクのto)
     */
    class func liClearMaskLiveFooterToColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.8)
    }

    /**
     スタイルガイドには無い、セル選択色

     - returns: セル選択色
     */
    class func liSelectedCellColor() -> UIColor {
        return UIColor(red: 7.0 / 255.0, green: 40.0 / 255.0, blue: 56.0 / 255.0, alpha: 0.05)
    }

    class func liCastShadowColor() -> UIColor {
        return UIColor(white: 0.0, alpha: 0.1)
    }

}

struct Colors {

    // Black & White
    static let black = UIColor(hex: "#000000")
    static let white = UIColor(hex: "#FFFFFF")

    static let li1B5D7CColor = UIColor(hex:"#1B5D7C")
    static let liF4F4F4Color = UIColor(hex:"#F4F4F4")
    static let liDarknavyColor = UIColor.liDarknavyColor()
    static let liLightGreyColor = UIColor.liLightGreyColor()
    static let liWhiteColor = UIColor.liWhiteColor()
    static let liClear69WhiteColor = UIColor.liClear69WhiteColor()
    static let liClear80WhiteColor = UIColor.liClear80WhiteColor()
    static let liBlackColor = UIColor.liBlackColor()
    static let liDarkGreyColor = UIColor.liDarkGreyColor()
    static let liLightNavyColor = UIColor.liLightNavyColor()
    static let liLightNavy103Color = UIColor.liLightNavy103Color()
    static let liClearBlackColor = UIColor.liClearBlackColor()
    static let liClear20BlackColor = UIColor.liClear20BlackColor()
    static let liClear59BlackColor = UIColor.liClear59BlackColor()
    static let liClear60BlackColor = UIColor.liClear60BlackColor()
    static let liClear30BlackColor = UIColor.liClear30BlackColor()
    static let liClear85BlackColor = UIColor.liClear85BlackColor()
    static let liClear45BlackColor = UIColor.liClear45BlackColor()
    static let liGreyBorderOneColor = UIColor.liGreyBorderOneColor()
    static let liGreyBorderTwoColor = UIColor.liGreyBorderTwoColor()
    static let liClearMaskFromColor = UIColor.liClearMaskFromColor()
    static let liClearMaskToColor = UIColor.liClearMaskToColor()
    static let liClearMaskFeatureFromColor = UIColor.liClearMaskFeatureFromColor()
    static let liClearMaskFeatureToColor = UIColor.liClearMaskFeatureToColor()
    static let liClearMaskLiveFooterFromColor = UIColor.liClearMaskLiveFooterFromColor()
    static let liClearMaskLiveFooterToColor = UIColor.liClearMaskLiveFooterToColor()
    static let liSelectedCellColor = UIColor.liSelectedCellColor()
    static let liLiveRedColor = UIColor.liLiveRedColor()
    static let liCastShadowColor = UIColor.liCastShadowColor()
    static func liClearWhiteColor(_ alpha: CGFloat) -> UIColor {
        return UIColor.liClearWhiteColor(alpha)
    }

}

