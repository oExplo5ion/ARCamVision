import UIKit

class CameraButton: UIView {
    var onClick:() -> Void = {}
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        onClick()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let stroke = CAShapeLayer()
        layer.addSublayer(stroke)
        stroke.path = UIBezierPath(ovalIn: CGRect(x: bounds.origin.x,
                                                  y: bounds.origin.y,
                                                  width: bounds.width,
                                                  height: bounds.height)).cgPath
        stroke.fillColor    = UIColor.clear.cgColor
        stroke.strokeColor  = UIColor.white.cgColor
        stroke.lineWidth    = 3
        
        let circle = CAShapeLayer()
        layer.addSublayer(circle)
        circle.path = UIBezierPath(ovalIn: CGRect(x: bounds.origin.x + 5,
                                                  y: bounds.origin.y + 5,
                                                  width: bounds.width - 10,
                                                  height: bounds.height - 10)).cgPath
        circle.strokeColor  = UIColor.clear.cgColor
        circle.fillColor    = UIColor.white.cgColor
    }
}
