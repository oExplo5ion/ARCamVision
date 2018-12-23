import UIKit

class ARCTextField: UITextField {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
