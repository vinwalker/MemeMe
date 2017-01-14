//
//  ViewController.swift
//  ImagePickerExperiment
//
//  Created by Vincent Walker on 3/5/16.
//  Copyright © 2016 NueraSmart. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    fileprivate let topDefaultText = "TOP"
    fileprivate let bottomDefaultText = "BOTTOM"
    fileprivate var keyboardHidden: Bool = true
    fileprivate var memedImage: Meme!
    
    enum TextFieldType: Int { case top = 0, bottom }
    
    let memeTextAttributes = [
        NSStrokeColorAttributeName : UIColor.black,
        NSForegroundColorAttributeName : UIColor.white,
        NSFontAttributeName : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSStrokeWidthAttributeName : CGFloat(-3.0),
    ] as [String : Any]

    override func viewDidLoad() {
        super.viewDidLoad()
        enableShare(false)
        setupMemeText(topText, desc: topDefaultText)
        setupMemeText(bottomText, desc: bottomDefaultText)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        self.subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unsubscribeFromKeyboardNotifications()
    }

    @IBAction func cancelMeme(_ sender: AnyObject) {
        resetViewController()
    }
    
     func pickAnImageFromAlbum(_ sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func pickAnImageFromCamera (_ sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func shareMeme(_ sender: AnyObject) {
        save()
        if self.memedImage != nil {
            let activityViewController = UIActivityViewController(activityItems: [self.memedImage.memedImage], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
                if completed {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func enableShare(_ isEnabled: Bool) {
        shareButton.isEnabled = isEnabled
    }
    
    func setupMemeText(_ memeText: UITextField, desc: String) {
        memeText.text = desc
        memeText.defaultTextAttributes = memeTextAttributes
        //Applying the attributes resets the alignment.  Alignment must be set after attributes are applied.
        memeText.textAlignment = NSTextAlignment.center
        memeText.delegate = self
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var newImage: UIImage
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            newImage = possibleImage
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            newImage = possibleImage
        } else {
            return
        }
        imagePickerView.image = newImage
        enableShare(true)
        dismiss(animated: true, completion: nil)
    }
    
    //Take a screen shot of the image. Apply the UIGraphicsBeginImageContextWithOptions for retina displays.
    func generateMemedImage() -> UIImage
    {
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame,
            afterScreenUpdates: true)
        let memedImage : UIImage =
        UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return memedImage
    }
    
    func save() {
        //Create the meme
        let memeImage = generateMemedImage()
        let meme = Meme(topText:topText.text!, bottomText: bottomText.text!,  image: imagePickerView.image!,  memedImage: memeImage)
        self.memedImage = meme
    }
    
    // Clear text on start editing if the textfield contains default text.
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch(TextFieldType(rawValue: textField.tag)!) {
        case .top:
            ClearDefaultText(textField, defaultText: topDefaultText)
        case .bottom:
            ClearDefaultText(textField, defaultText: bottomDefaultText)
        }
    }
    
    func ClearDefaultText(_ textField: UITextField, defaultText: String) {
        if textField.text == defaultText {
            textField.text = ""
        }
    }    
    
    // remember the recently edited text field to allow
    // the keyboard hide event to decide if view needs to shift.
    func textFieldShouldReturn(_ txtField: UITextField) -> Bool {
        txtField.endEditing(false)
        return true
    }

    // Reset textfields and image
    func resetViewController() {
        imagePickerView.image = nil
        enableShare(false)
        topText.text = topDefaultText
        bottomText.text = bottomDefaultText
    }
    
    //keyboard Adjustments
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name:
            NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name:
            NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(_ notification: Notification) {

        if(bottomText.isFirstResponder && keyboardHidden){
            toolBar.isHidden = true
            self.view.frame.origin.y -= getKeyboardHeight(notification)
            keyboardHidden = false

        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if(bottomText.isFirstResponder && !keyboardHidden){
            self.view.frame.origin.y += getKeyboardHeight(notification)
            keyboardHidden = true
            toolBar.isHidden = false
        }
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }

}

