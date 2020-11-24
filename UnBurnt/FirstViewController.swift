//
//  FirstViewController.swift
//  tryAlamoFirePost
//
//  Created by Lila Kelland on 2020-07-09.
//  Copyright © 2020 Lila Kelland. All rights reserved.
//
//  Grabs user coooking parameters (temp limits and timer duration), displays placeholders from values stored on server

import UIKit
import Alamofire
import SwiftyJSON

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class FirstViewController: UIViewController, UITextFieldDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var cookingParameters: CookingParameters
        required init?(coder: NSCoder) {
            self.cookingParameters = appDelegate.cookingParameters
            super.init(coder: coder)
    }
    
    @IBOutlet weak var lowTemp: UITextField!
    @IBOutlet weak var highTemp: UITextField!
    @IBOutlet weak var checkTime: UITextField!
    
    
    @IBOutlet weak var lowTempInputError: UILabel!
    @IBOutlet weak var highTempInputError: UILabel!
    @IBOutlet weak var checkTimeInputError: UILabel!
    
//    @IBAction func swipeMade(_ sender: UISwipeGestureRecognizer) {
//       if sender.direction == .left {
//          print("left swipe made")
//       }
//       if sender.direction == .right {
//          print("right swipe made")
//          self.performSegue(withIdentifier: "toGraphFromTempTime", sender: self)
//       }
//    }
    
    @IBAction func submitAction(_ sender: UIButton) {
// display user input errors on screen (set function calls check functions)
        // Clear all previous error messages
        lowTempInputError.text = ""
        highTempInputError.text = ""
        checkTimeInputError.text = ""
        
        // verify and load if valid
        do {
            try cookingParameters.setLowTempLimit(lowTempInput: lowTemp.text!)
            } catch InputError.inputEmpty(let message) {
                lowTempInputError.text = message
            } catch InputError.inputNonInteger(let message) {
                lowTempInputError.text = message
            } catch InputError.inputNegative(let message) {
                lowTempInputError.text = message
            } catch {
                print("Unexpected error: \(error).")
            }
        
        do {
            try cookingParameters.setHighTempLimit(lowTempInput: lowTemp.text!, highTempInput: highTemp.text!)
            } catch InputError.inputEmpty(let message) {
                highTempInputError.text = message
            } catch InputError.inputNonInteger(let message) {
                highTempInputError.text = message
            } catch InputError.inputNegative(let message) {
                highTempInputError.text = message
            } catch InputError.lowVsHigh(let message) {
                highTempInputError.text = message
            } catch {
                print("Unexpected error: \(error).")
            }
    
        do {
            try cookingParameters.setCheckTimeLimit(checkTimeInput: checkTime.text!)
            } catch InputError.inputEmpty(let message) {
                checkTimeInputError.text = message
            } catch InputError.inputNonInteger(let message) {
                checkTimeInputError.text = message
            } catch InputError.inputNegative(let message) {
                checkTimeInputError.text = message
            } catch InputError.lowVsHigh(let message) {
                checkTimeInputError.text = message
            } catch {
                print("Unexpected error: \(error).")
            }
        
        // Upload to server
        do {
            try cookingParameters.pushCookingParametersToServer(lowTempLimit: cookingParameters.goldLowTempLimit, highTempLimit: cookingParameters.goldHighTempLimit, checkTime:cookingParameters.goldCheckTime)
        } catch  {
            checkTimeInputError.text = "\(error) - please try again"
        }
        
        print("Submit button was pressed!")
    }
    
    @objc func updatePlaceholders() {
        // get cooking parameters to keep this state updated
        lowTemp.placeholder = cookingParameters.goldLowTempLimit
        highTemp.placeholder = cookingParameters.goldHighTempLimit
        checkTime.placeholder = cookingParameters.goldCheckTime
    }
    
    var timer = Timer()
    func runUpdates() {
         timer = Timer.scheduledTimer(timeInterval: 2, target: self,   selector: (#selector(FirstViewController.updatePlaceholders)), userInfo: nil, repeats: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           self.view.endEditing(true)
           return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePlaceholders()
        self.hideKeyboardWhenTappedAround()
        runUpdates()
    }
}


