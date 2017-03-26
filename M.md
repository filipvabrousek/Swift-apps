# Messenger clone

* push to WC (1)
* push to relevant WC (2)

```swift
class LandingVC: UIViewController {
    
    //MARK: Properties
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }

/*-------1-------*/
    func pushTo(viewController: ViewControllerType)  {
        switch viewController {
        case .conversations:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "Navigation") as! NavVC
            self.present(vc, animated: false, completion: nil)
        case .welcome:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "Welcome") as! WelcomeVC
            self.present(vc, animated: false, completion: nil)
        }
    }
    
/*-------2-------*/
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let userInformation = UserDefaults.standard.dictionary(forKey: "userInformation") {
            let email = userInformation["email"] as! String
            let password = userInformation["password"] as! String
            User.loginUser(withEmail: email, password: password, completion: { [weak weakSelf = self] (status) in
                DispatchQueue.main.async {
                    if status == true {
                        weakSelf?.pushTo(viewController: .conversations)
                    } else {
                        weakSelf?.pushTo(viewController: .welcome)
                    }
                    weakSelf = nil
                }
            })
        } else {
            self.pushTo(viewController: .welcome)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

```


# Welcome screen

* Customize, create cloud animation (1)
* manage loading states (2)

```swift
class WelcomeVC: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    //MARK: Properties
    @IBOutlet weak var darkView: UIView!
.........
.........
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
/*------1-------*/
    func customization()  {
        self.darkView.alpha = 0
        self.imagePicker.delegate = self
        self.profilePicView.layer.borderColor = GlobalVariables.blue.cgColor
        self.profilePicView.layer.borderWidth = 2
        //LoginView customization
        self.view.insertSubview(self.loginView, belowSubview: self.cloudsView)
        self.loginView.translatesAutoresizingMaskIntoConstraints = false
        self.loginView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.loginViewTopConstraint = NSLayoutConstraint.init(item: self.loginView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 60)
        self.loginViewTopConstraint.isActive = true
        self.loginView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.45).isActive = true
        self.loginView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
        self.loginView.layer.cornerRadius = 8
        //RegisterView Customization
        self.view.insertSubview(self.registerView, belowSubview: self.cloudsView)
        self.registerView.translatesAutoresizingMaskIntoConstraints = false
        self.registerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.registerTopConstraint = NSLayoutConstraint.init(item: self.registerView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 1000)
        self.registerTopConstraint.isActive = true
        self.registerView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.6).isActive = true
        self.registerView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
        self.registerView.layer.cornerRadius = 8
    }
   
    func cloundsAnimation() {
        let distance = self.view.bounds.width - self.cloudsView.bounds.width
        self.cloudsViewLeading.constant = distance
        UIView.animate(withDuration: 15, delay: 0, options: [.repeat, .curveLinear], animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    /*------2-------*/
    func showLoading(state: Bool)  {
        if state {
            self.darkView.isHidden = false
            self.spinner.startAnimating()
            UIView.animate(withDuration: 0.3, animations: { 
                self.darkView.alpha = 0.5
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: { 
                self.darkView.alpha = 0
            }, completion: { _ in
                self.spinner.stopAnimating()
                self.darkView.isHidden = true
            })
        }
    }
    
    func pushTomainView() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Navigation") as! NavVC
        self.show(vc, sender: nil)
    }
    ```
    
    
* open photo picker (3)
* switch views (4)
   
   
```swift
    /* --------3----------*/
    func openPhotoPickerWith(source: PhotoSource) {
        switch source {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            if (status == .authorized || status == .notDetermined) {
                self.imagePicker.sourceType = .camera
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        case .library:
            let status = PHPhotoLibrary.authorizationStatus()
            if (status == .authorized || status == .notDetermined) {
                self.imagePicker.sourceType = .savedPhotosAlbum
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    
    /* ---------4----------*/
    @IBAction func switchViews(_ sender: UIButton) {
        if self.isLoginViewVisible {
            self.isLoginViewVisible = false
            sender.setTitle("Login", for: .normal)
            self.loginViewTopConstraint.constant = 1000
            self.registerTopConstraint.constant = 60
        } else {
            self.isLoginViewVisible = true
            sender.setTitle("Create New Account", for: .normal)
            self.loginViewTopConstraint.constant = 60
            self.registerTopConstraint.constant = 1000
        }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
        for item in self.waringLabels {
            item.isHidden = true
        }
    }
    
 ```
 * register and log-in (5)
 * select picture and helper methods
 
 
```swift
    /* --------5-----------*/
    @IBAction func register(_ sender: Any) {
        for item in self.inputFields {
            item.resignFirstResponder()
        }
        self.showLoading(state: true)
        User.registerUser(withName: self.registerNameField.text!, email: self.registerEmailField.text!, password: self.registerPasswordField.text!, profilePic: self.profilePicView.image!) { [weak weakSelf = self] (status) in
            DispatchQueue.main.async {
                weakSelf?.showLoading(state: false)
                for item in self.inputFields {
                    item.text = ""
                }
                if status == true {
                    weakSelf?.pushTomainView()
                    weakSelf?.profilePicView.image = UIImage.init(named: "profile pic")
                } else {
                    for item in (weakSelf?.waringLabels)! {
                        item.isHidden = false
                    }
                }
            }
        }
    }
    
    
    /*------------------------------------------------------------------------LOGIN------------------------------------------------------------------------*/
    @IBAction func login(_ sender: Any) {
        for item in self.inputFields {
            item.resignFirstResponder()
        }
        self.showLoading(state: true)
        User.loginUser(withEmail: self.loginEmailField.text!, password: self.loginPasswordField.text!) { [weak weakSelf = self](status) in
            DispatchQueue.main.async {
                weakSelf?.showLoading(state: false)
                for item in self.inputFields {
                    item.text = ""
                }
                if status == true {
                    weakSelf?.pushTomainView()
                } else {
                    for item in (weakSelf?.waringLabels)! {
                        item.isHidden = false
                    }
                }
                weakSelf = nil
            }
        }
    }
    
    
    /*----------6------------*/
    @IBAction func selectPic(_ sender: Any) {
        let sheet = UIAlertController(title: nil, message: "Select the source", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openPhotoPickerWith(source: .camera)
        })
        let photoAction = UIAlertAction(title: "Gallery", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openPhotoPickerWith(source: .library)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheet.addAction(cameraAction)
        sheet.addAction(photoAction)
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
    }
    
    /*------------------------------------------------------------------------DELEGATES------------------------------------------------------------------------*/
    func textFieldDidBeginEditing(_ textField: UITextField) {
        for item in self.waringLabels {
            item.isHidden = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profilePicView.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cloundsAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.cloudsViewLeading.constant = 0
        self.cloudsView.layer.removeAllAnimations()
        self.view.layoutIfNeeded()
    }
}

```
# Navigation WC
* customize (1)
* dismiss and show extra views

```swift
class NavVC: UINavigationController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    //MARK: Properties
    @IBOutlet var contactsView: UIView!
    @IBOutlet var profileView: UIView!
    @IBOutlet var previewView: UIView!
    @IBOutlet var mapPreviewView: UIView!
    @IBOutlet weak var mapVIew: MKMapView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profilePicView: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    var topAnchorContraint: NSLayoutConstraint!
    let darkView = UIView.init()
    var items = [User]()
    
/* --------1-----------*/
    func customization() {
        //DarkView customization
        self.view.addSubview(self.darkView)
        self.darkView.backgroundColor = UIColor.black
        self.darkView.alpha = 0
        self.darkView.translatesAutoresizingMaskIntoConstraints = false
        self.darkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.darkView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.darkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.darkView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.darkView.isHidden = true
    //ContainerView customization
        let extraViewsContainer = UIView.init()
        extraViewsContainer.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(extraViewsContainer)
        self.topAnchorContraint = NSLayoutConstraint.init(item: extraViewsContainer, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 1000)
        self.topAnchorContraint.isActive = true
        extraViewsContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        extraViewsContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        extraViewsContainer.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 1).isActive = true
        extraViewsContainer.backgroundColor = UIColor.clear
    //ContactsView customization
        extraViewsContainer.addSubview(self.contactsView)
        self.contactsView.translatesAutoresizingMaskIntoConstraints = false
        self.contactsView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.contactsView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.contactsView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.contactsView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        self.contactsView.isHidden = true
        self.collectionView?.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        self.contactsView.backgroundColor = UIColor.clear
    //ProfileView Customization
        extraViewsContainer.addSubview(self.profileView)
        self.profileView.translatesAutoresizingMaskIntoConstraints = false
        self.profileView.heightAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width * 0.9)).isActive = true
        let profileViewAspectRatio = NSLayoutConstraint.init(item: self.profileView, attribute: .width, relatedBy: .equal, toItem: self.profileView, attribute: .height, multiplier: 0.8125, constant: 0)
        profileViewAspectRatio.isActive = true
        self.profileView.centerXAnchor.constraint(equalTo: extraViewsContainer.centerXAnchor).isActive = true
        self.profileView.centerYAnchor.constraint(equalTo: extraViewsContainer.centerYAnchor).isActive = true
        self.profileView.layer.cornerRadius = 5
        self.profileView.clipsToBounds = true
        self.profileView.isHidden = true
        self.profilePicView.layer.borderColor = GlobalVariables.purple.cgColor
        self.profilePicView.layer.borderWidth = 3
        self.view.layoutIfNeeded()
    //PreviewView Customization
        extraViewsContainer.addSubview(self.previewView)
        self.previewView.isHidden = true
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.previewView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.previewView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.previewView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.previewView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 3.0
    //MapPreView Customization
        extraViewsContainer.addSubview(self.mapPreviewView)
        self.mapPreviewView.isHidden = true
        self.mapPreviewView.translatesAutoresizingMaskIntoConstraints = false
        self.mapPreviewView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.mapPreviewView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.mapPreviewView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.mapPreviewView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        //NotificationCenter for showing extra views
        NotificationCenter.default.addObserver(self, selector: #selector(self.showExtraViews(notification:)), name: NSNotification.Name(rawValue: "showExtraView"), object: nil)
        self.fetchUsers()
        self.fetchUserInfo()

    }
    
    /*-------------2-----------*/
    func dismissExtraViews() {
        self.topAnchorContraint.constant = 1000
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
            self.darkView.alpha = 0
            self.view.transform = CGAffineTransform.identity
        }, completion:  { (true) in
            self.darkView.isHidden = true
            self.profileView.isHidden = true
            self.contactsView.isHidden = true
            self.previewView.isHidden = true
            self.mapPreviewView.isHidden = true
            self.mapVIew.removeAnnotations(self.mapVIew.annotations)
            let vc = self.viewControllers.last
            vc?.inputAccessoryView?.isHidden = false
        })
    }
    
     /*---------------3--------------*/
    func showExtraViews(notification: NSNotification)  {
        let transform = CGAffineTransform.init(scaleX: 0.94, y: 0.94)
        self.topAnchorContraint.constant = 0
        self.darkView.isHidden = false
        if let type = notification.userInfo?["viewType"] as? ShowExtraView {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                self.darkView.alpha = 0.8
                if (type == .contacts || type == .profile) {
                    self.view.transform = transform
                }
            })
            switch type {
            case .contacts:
                self.contactsView.isHidden = false
                if self.items.count == 0 {
                }
            case .profile:
                self.profileView.isHidden = false
            case .preview:
                self.previewView.isHidden = false
                self.previewImageView.image = notification.userInfo?["pic"] as? UIImage
                self.scrollView.contentSize = self.previewImageView.frame.size
            case .map:
                self.mapPreviewView.isHidden = false
                let coordinate = notification.userInfo?["location"] as? CLLocationCoordinate2D
                let annotation = MKPointAnnotation.init()
                annotation.coordinate = coordinate!
                self.mapVIew.addAnnotation(annotation)
                self.mapVIew.showAnnotations(self.mapVIew.annotations, animated: false)
            }
        }
    }

```
* zoom rect for scale (1)
* fetch users (2)
* double tap gestures and helepr methods (3)

```swift
/*----------1------------*/
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = self.previewImageView.frame.size.height / scale
        zoomRect.size.width  = self.previewImageView.frame.size.width  / scale
        let newCenter = self.previewImageView.convert(center, from: self.scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
       /*---------2-------------*/
    func fetchUsers()  {
        if let id = FIRAuth.auth()?.currentUser?.uid {
            User.downloadAllUsers(exceptID: id, completion: {(user) in
                DispatchQueue.main.async {
                    self.items.append(user)
                    self.collectionView.reloadData()
                }
            })
        }
    }
    
    func fetchUserInfo() {
        if let id = FIRAuth.auth()?.currentUser?.uid {
            User.info(forUserID: id, completion: {[weak weakSelf = self] (user) in
                DispatchQueue.main.async {
                    weakSelf?.nameLabel.text = user.name
                    weakSelf?.emailLabel.text = user.email
                    weakSelf?.profilePicView.image = user.profilePic
                    weakSelf = nil
                }
            })
        }
    }
    
       /*-----------3-------------*/
    @IBAction func doubleTapGesture(_ sender: UITapGestureRecognizer) {
        if self.scrollView.zoomScale == 1 {
            self.scrollView.zoom(to: zoomRectForScale(scale: self.scrollView.maximumZoomScale, center: sender.location(in: sender.view)), animated: true)
        } else {
            self.scrollView.setZoomScale(1, animated: true)
        }
    }
    
    @IBAction func closeView(_ sender: Any) {
        self.dismissExtraViews()
    }
  
    @IBAction func logOutUser(_ sender: Any) {
        User.logOutUser { (status) in
            if status == true {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

```