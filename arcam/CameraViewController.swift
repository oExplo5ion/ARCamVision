import UIKit
import ARKit
import Vision

class CameraViewController: UIViewController {
    
    // MARK: Fields
    private var imageOrientation: CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
        case .portrait: return .right
        case .landscapeRight: return .down
        case .portraitUpsideDown: return .left
        case .unknown: fallthrough
        case .faceUp: fallthrough
        case .faceDown: fallthrough
        case .landscapeLeft: return .up
        }
    }
    
    private var sceneView = ARSCNView()
    private var scanTimer:Timer? = nil
    private var bottomConstraint = NSLayoutConstraint()
    private lazy var scanedFacesViews = [UIView]()
    private var text = "TEXT"
    
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    // MARK: Ovverides
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.session.run(ARWorldTrackingConfiguration(), options: ARSession.RunOptions())
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            self.scanForFaces()
        })
        scanTimer?.fire()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        scanTimer?.invalidate()
        scanTimer = nil
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blur.layer.cornerRadius = blur.bounds.height / 2
    }
    
    // MARK: Funcs
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: UI
extension CameraViewController {
    func setupUI() {
        view = sceneView
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        let cameraButton = CameraButton()
        view.addSubview(cameraButton)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        cameraButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cameraButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        cameraButton.isUserInteractionEnabled = true
        cameraButton.onClick = { self.takePhoto() }
        
        view.addSubview(blur)
        blur.translatesAutoresizingMaskIntoConstraints = false
        bottomConstraint = blur.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        bottomConstraint.isActive = true
        blur.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8).isActive = true
        blur.rightAnchor.constraint(equalTo: cameraButton.leftAnchor, constant: -16).isActive = true
        blur.heightAnchor.constraint(equalToConstant: 40).isActive = true
        blur.clipsToBounds = true
        
        let labelTextField = UITextField()
        view.addSubview(labelTextField)
        labelTextField.translatesAutoresizingMaskIntoConstraints = false
        labelTextField.topAnchor.constraint(equalTo: blur.topAnchor, constant: 5).isActive = true
        labelTextField.bottomAnchor.constraint(equalTo: blur.bottomAnchor, constant: -5).isActive = true
        labelTextField.leftAnchor.constraint(equalTo: blur.leftAnchor, constant: 10).isActive = true
        labelTextField.rightAnchor.constraint(equalTo: blur.rightAnchor, constant: -10).isActive = true
        labelTextField.textColor = .white
        let placeholderAtr:[NSAttributedStringKey:Any] = [
            NSAttributedStringKey.foregroundColor   : UIColor.white,
            NSAttributedStringKey.font              : UIFont.systemFont(ofSize: 20, weight: .regular)
        ]
        labelTextField.attributedPlaceholder = NSAttributedString(string: "Text", attributes: placeholderAtr)
        labelTextField.addTarget(self, action: #selector(labelTextFieldChanged(textField:)), for: .editingChanged)
    }
    
    // MARK: Keyboard
    @objc func keyboardConstraint() -> NSLayoutConstraint? {
        return bottomConstraint
    }
    
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo, let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let keyboardHeightLayoutConstraint = self.keyboardConstraint() {
            let endFrameY = endFrame.origin.y
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            if endFrameY >= UIScreen.main.bounds.size.height {
                keyboardHeightLayoutConstraint.constant = -50
            } else {
                keyboardHeightLayoutConstraint.constant = -endFrame.size.height
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
        
    }
}

// MARK: Face
extension CameraViewController {
    private func scanForFaces() {
        scanedFacesViews.forEach({ $0.removeFromSuperview() })
        scanedFacesViews.removeAll(keepingCapacity: true)
        
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else { return }
        let image = CIImage(cvImageBuffer: capturedImage)
        
        let detectFaceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            DispatchQueue.main.async {
                if error != nil { return }
                guard let faces = request.results as? [VNFaceObservation] else { return }
                for face in faces {
                    self.addFace(box: face.boundingBox)
                }
            }
        }
        
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image, orientation: self.imageOrientation, options: [VNImageOption : Any]())
                .perform([detectFaceRequest])
        }
    }
    
    private func addFace(box:CGRect) {
        let getFaceFrame:(_ box:CGRect) -> CGRect = { box in
            let origin = CGPoint(x: box.minX * self.sceneView.frame.width, y: (1 - box.maxY) * self.sceneView.frame.height)
            let size = CGSize(width: box.width * self.sceneView.frame.width, height: box.height * self.sceneView.frame.height)
            return CGRect(origin: origin, size: size)
        }
        
        let faceView = UIView(frame: getFaceFrame(box))
        
        let label = UILabel()
        faceView.addSubview(label)
        label.bounds = faceView.bounds
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .black)
        label.textAlignment = .center
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 2, height: 2)
        label.text = self.text
        label.adjustsFontSizeToFitWidth = true
        
        self.sceneView.addSubview(faceView)
        self.scanedFacesViews.append(faceView)
    }
}

// MARK: Textfield
extension CameraViewController {
    @objc private func labelTextFieldChanged(textField:UITextField) {
        guard let textFieldText = textField.text else { return }
        self.text = textFieldText
    }
}

// MARK: Camera
extension CameraViewController {
    func takePhoto() {
        defer {
            UIGraphicsEndImageContext()
        }
        UIGraphicsBeginImageContext(sceneView.frame.size)
        sceneView.drawHierarchy(in: sceneView.frame, afterScreenUpdates: true)
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
    
    func runImageTakenAnimation() {
        
    }
}
