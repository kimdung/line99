//
//  OutlineLabelNode.swift
//  Line99
//
//  Created by Ngoc Nguyen on 10/03/2023.
//

import Foundation

import SpriteKit

class OutlinedLabelNode: SKLabelNode {

    var borderColor: UIColor = UIColor.black
    var borderWidth: CGFloat = 7.0
    var borderOffset : CGPoint = CGPoint(x: 0, y: 0)
    enum borderStyleType {
        case over
        case under
    }
    var borderStyle = borderStyleType.under

    var outlinedText: String! {
        didSet { drawText() }
    }

    private var border: SKShapeNode?

    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

    override init() { super.init() }

    init(fontNamed fontName: String!, fontSize: CGFloat) {
        super.init(fontNamed: fontName)
        self.fontSize = fontSize
    }

    func drawText() {
        if let borderNode = border {
            borderNode.removeFromParent()
            border = nil
        }

        if let text = outlinedText {
            self.text = text
            if let path = createBorderPathForText() {
                let border = SKShapeNode()

                border.strokeColor = borderColor
                border.lineWidth = borderWidth;
                border.path = path
                border.position = positionBorder(border: border)
                switch self.borderStyle {
                    case borderStyleType.over:
                        border.zPosition = self.zPosition + 1
                        break
                    default:
                        border.zPosition = self.zPosition - 1
                }

                addChild(border)

                self.border = border
            }
        }
    }

    private func getTextAsCharArray() -> [UniChar] {
        var chars = [UniChar]()

        for codeUnit in (text?.utf16)! {
            chars.append(codeUnit)
        }
        return chars
    }

    private func createBorderPathForText() -> CGPath? {
        let chars = getTextAsCharArray()
        let borderFont = CTFontCreateWithName((self.fontName as CFString?)!, self.fontSize, nil)

        var glyphs = Array<CGGlyph>(repeating: 0, count: chars.count)
        let gotGlyphs = CTFontGetGlyphsForCharacters(borderFont, chars, &glyphs, chars.count)

        if gotGlyphs {
            var advances = Array<CGSize>(repeating: CGSize(), count: chars.count)
            CTFontGetAdvancesForGlyphs(borderFont, CTFontOrientation.horizontal, glyphs, &advances, chars.count);

            let letters = CGMutablePath()
            var xPosition = 0 as CGFloat
            for index in 0...(chars.count - 1) {
                let letter = CTFontCreatePathForGlyph(borderFont, glyphs[index], nil)
                let t = CGAffineTransform(translationX: xPosition , y: 0)
                letters.addPath(letter!, transform: t)
                xPosition = xPosition + advances[index].width
            }

            return letters
        } else {
            return nil
        }
    }

    private func positionBorder(border: SKShapeNode) -> CGPoint {
        let sizeText = self.calculateAccumulatedFrame()
        let sizeBorder = border.calculateAccumulatedFrame()
        let offsetX = sizeBorder.width - sizeText.width

        switch self.horizontalAlignmentMode {
        case SKLabelHorizontalAlignmentMode.center:
            return CGPoint(x: -(sizeBorder.width / 2) + offsetX/2.0 + self.borderOffset.x, y: 1 + self.borderOffset.y)
        case SKLabelHorizontalAlignmentMode.left:
            return CGPoint(x: sizeBorder.origin.x - self.borderWidth*2 + offsetX + self.borderOffset.x, y: 1 + self.borderOffset.y)
        default:
            return CGPoint(x: sizeBorder.origin.x - sizeText.width - self.borderWidth*2 + offsetX + self.borderOffset.x, y: 1 + self.borderOffset.y)
        }
    }
}



class ASAttributedLabelNode: SKSpriteNode {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(size: CGSize) {
        super.init(texture: nil, color: UIColor.clear, size: size)
    }

    var attributedString: NSAttributedString! {
        didSet {
            draw()
        }
    }

    func draw() {
        guard let attrStr = attributedString else {
            texture = nil
            return
        }

        let scaleFactor = UIScreen.main.scale
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(data: nil, width: Int(size.width * scaleFactor), height: Int(size.height * scaleFactor), bitsPerComponent: 8, bytesPerRow: Int(size.width * scaleFactor) * 4, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return
        }

        context.scaleBy(x: scaleFactor, y: scaleFactor)
        context.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        UIGraphicsPushContext(context)

        let strHeight = attrStr.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil).height
        let yOffset = (size.height - strHeight) / 2.0
        attrStr.draw(with: CGRect(x: 0, y: yOffset, width: size.width, height: strHeight), options: .usesLineFragmentOrigin, context: nil)

        if let imageRef = context.makeImage() {
            texture = SKTexture(cgImage: imageRef)
        } else {
            texture = nil
        }

        UIGraphicsPopContext()
    }

}


class LFOutlinedLabel : SKSpriteNode {

    private let skewX : [CGFloat] = [-1, 1, 1,-1]
    private let skewY : [CGFloat] = [-1,-1, 1, 1]

    private var label : SKLabelNode = SKLabelNode()
    private var shadows : [SKLabelNode] = []

    public var borderOpacity : CGFloat = 1
    public var borderSize: CGFloat = 1
    public var borderColor: UIColor = UIColor.black
    public var text : String = "?"
    public var fontName : String = "Fonts.OptimaExtraBlack.rawValue"
    public var fontColor: UIColor = UIColor.white
    public var fontSize : CGFloat = 40

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //self.setup()
    }

    override init(texture: SKTexture!, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        //self.setup()
    }

    convenience init(size: CGSize, font: String, fSize: CGFloat, fColor: UIColor, bSize: CGFloat, bColor: UIColor, bOpacity: CGFloat)
    {
        self.init(texture: nil, color: UIColor.clear, size: size)
        self.fontName = font
        self.fontSize = fSize
        self.fontColor = fColor
        self.borderSize = bSize
        self.borderColor = bColor
        self.borderOpacity = bOpacity
        self.setup()
    }

    // create shadow labels
    private func setup() {
        if shadows.count == 0 {
            let width = self.size.width / 2
            let height = self.size.height / 2
            for j in 0...3 {
                let shadow = SKLabelNode(text: self.text)
                addChild(shadow)
                shadow.verticalAlignmentMode = .center
                shadow.horizontalAlignmentMode = .center
                shadow.zPosition = 999
//                shadow.position = CGPoint(x: width + (skewX[j] * borderSize) , y: height + (skewY[j] * borderSize))
                shadow.text = self.text
                shadow.fontSize = self.fontSize
                shadow.fontName = self.fontName
                shadow.fontColor = borderColor
                shadows.append(shadow)
            }
            let label = SKLabelNode(text: self.text)
            addChild(label)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zPosition = 1000
//            label.position = CGPoint(x: width , y: height )
            label.text = self.text
            label.fontSize = self.fontSize
            label.fontName = self.fontName
            label.fontColor = fontColor
            self.label = label
        }
    }

    public func update(){
        let width = self.size.width / 2
        let height = self.size.height / 2

        self.label.fontSize = fontSize
        self.label.fontName = fontName
        self.label.fontColor = fontColor
        self.label.verticalAlignmentMode = .center
        self.label.horizontalAlignmentMode = .center
        self.label.text = text
//        self.label.position = CGPoint(x: width  , y: height )

        for i in 0...3 {
            shadows[i].verticalAlignmentMode = .center
            shadows[i].horizontalAlignmentMode = .center
            shadows[i].fontColor = borderColor
            shadows[i].fontSize = fontSize
            shadows[i].alpha = borderOpacity
            shadows[i].fontName = fontName
            shadows[i].text = text
//            shadows[i].position = CGPoint(x: width + (skewX[i] * borderSize) , y: height + (skewY[i] * borderSize) )
        }
    }
}


extension SKLabelNode {

   func addStroke(color:UIColor, width: CGFloat) {

        guard let labelText = self.text else { return }

        let font = UIFont(name: self.fontName!, size: self.fontSize)

        let attributedString:NSMutableAttributedString
        if let labelAttributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelAttributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }

       let attributes:[NSAttributedString.Key:Any] = [.strokeColor: color, .strokeWidth: -width, .font: font!, .foregroundColor: self.fontColor!]
        attributedString.addAttributes(attributes, range: NSMakeRange(0, attributedString.length))

        self.attributedText = attributedString
   }
}


extension SKLabelNode {
    convenience init(fontNamed font: String, text: String, fontSize size: CGFloat, textColor: UIColor, shadowColor shadow: UIColor) {
        self.init(fontNamed: font)
        self.text = text
        self.fontSize = size
        self.fontColor = textColor
        let shadowNode = SKLabelNode(fontNamed: font)
        shadowNode.verticalAlignmentMode = self.verticalAlignmentMode
        shadowNode.horizontalAlignmentMode = self.horizontalAlignmentMode
        shadowNode.text = self.text
        shadowNode.zPosition = self.zPosition - 1
        shadowNode.fontColor = shadow
        // Just create a little offset from the main text label
        shadowNode.position = CGPoint(x: 0, y: -1)
        shadowNode.fontSize = self.fontSize
        shadowNode.alpha = 0.8

//        self.addChild(shadowNode)
    }
}
