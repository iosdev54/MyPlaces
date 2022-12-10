//
//  NewServiceViewController.swift
//  MyPlaces
//
//  Created by Dmytro Grytsenko on 22.11.2022.
//

import UIKit

class NewServiceViewController: UIViewController {
    
    //MARK: - Private constants
    private let segueIdentifierShowService = "showService"
    
    var currentService: Service!
    private var imageIsChanged = false
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.applyShadow(cornerRadius: 10)
        }
    }
    
    @IBOutlet weak var contentView: UIView! {
        didSet {
            contentView.makeCorner(with: 10)
        }
    }

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var serviceImage: UIImageView!
    @IBOutlet weak var serviceName: UITextField!
    @IBOutlet weak var serviceType: UITextField!
    @IBOutlet weak var serviceLocation: UITextField!
    @IBOutlet weak var servicePhone: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveButton.isEnabled = false
        
        //Для отслеживания редактирования поля name
        serviceName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        setupEditScreen()
                
        hideKeyboardWhenTappedAround()
        
        showAndHideKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.hidesBarsOnSwipe = false
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func saveService() {
        
        let image = imageIsChanged ? serviceImage.image : UIImage.placeholder
        
        let imageData = image?.pngData()
        
        let newService = Service(name: serviceName.text!, type: serviceType.text, location: serviceLocation.text, phone: servicePhone.text, imageData: imageData, rating: Double(ratingControl.rating))
        
        if currentService != nil {
            try! realm.write {
                currentService?.name = newService.name
                currentService?.type = newService.type
                currentService?.location = newService.location
                currentService?.phone = newService.phone
                currentService?.imageData = newService.imageData
                currentService?.rating = newService.rating
            }
        } else {
            StorageManager.saveObject(newService)
        }
    }
    
    private func setupEditScreen() {
        
        if currentService != nil {
            
            setupNavigationBar()
            
            imageIsChanged = true
            
            serviceName.text = currentService.name
            serviceType.text = currentService.type
            serviceLocation.text = currentService.location
            servicePhone.text = currentService.phone
            ratingControl.rating = Int(currentService.rating)
            
            guard let data = currentService?.imageData, let image = UIImage(data: data) else { return }
            serviceImage.image = image
            serviceImage.contentMode = .scaleAspectFill
            serviceImage.clipsToBounds = true
        }
    }
    
    private func setupNavigationBar() {
        
        if let topItem = navigationController?.navigationBar.topItem {
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
        navigationItem.leftBarButtonItem = nil
        title = currentService?.name
        saveButton.isEnabled = true
    }
    
    @IBAction func addImageAction(_ sender: UIButton) {
        
        let camera = UIAction( title: "Camera", image: UIImage(systemName: "camera")) { [weak self] _ in
            guard let `self` = self else { return }
            self.chooseImagePicker(sourse: .camera)
        }
        
        let photo = UIAction( title: "Photo", image: UIImage(systemName: "photo")) { [weak self] _ in
            guard let `self` = self else { return }
            self.chooseImagePicker(sourse: .photoLibrary)
        }
        let menuActions = [camera, photo]
        let menu = UIMenu( title: "Select sourse of photo", children: menuActions)
        
        sender.showsMenuAsPrimaryAction = true
        sender.menu = menu
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier, let mapVC = segue.destination as? MapViewController else { return }
        mapVC.incomeSegueIdentifier = identifier
        mapVC.mapViewControllerDelegate = self
        
        if identifier == segueIdentifierShowService {
            mapVC.place.name = serviceName.text!
            mapVC.place.location = serviceLocation.text
            mapVC.place.type = serviceType.text
            mapVC.place.imageData = serviceImage.image?.pngData()
        }
    }
    
}
//MARK: - Text field delegate
extension NewServiceViewController: UITextFieldDelegate {
    
    //Скрываем клавиатуту по нажатию на done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let maxLength: Int!
        
        switch textField {
        case serviceLocation: maxLength = 45
        default:
            maxLength = 15
        }

          let currentString = (textField.text ?? "") as NSString
          let newString = currentString.replacingCharacters(in: range, with: string)

          return newString.count <= maxLength
    }
    
    @objc private func textFieldChanged() {
        
        saveButton.isEnabled = serviceName.text?.isEmpty == false ? true : false
    }
    
}

//MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension NewServiceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImagePicker(sourse: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourse) {
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = sourse
            present(imagePicker, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        serviceImage.image = info[.editedImage] as? UIImage
        serviceImage.contentMode = .scaleAspectFill
        serviceImage.clipsToBounds = true
        
        imageIsChanged = true
        
        dismiss(animated: true)
    }
    
}

//MARK: - MapViewControllerDelegate
extension NewServiceViewController: MapViewControllerDelegate {
    
    func getAddress(_ address: String?) {
        serviceLocation.text = address
    }
}

//MARK: - Show and Hide Keyboard
extension NewServiceViewController {
    func hideKeyboardWhenTappedAround() {
        
        let scrollViewTap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
                scrollViewTap.numberOfTapsRequired = 1
                scrollView.addGestureRecognizer(scrollViewTap)
    }
    
    func showAndHideKeyboard() {
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func hideKeyboard() {

        scrollView.endEditing(true)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = .zero
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom + 10, right: 0)
        }
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
    
}
