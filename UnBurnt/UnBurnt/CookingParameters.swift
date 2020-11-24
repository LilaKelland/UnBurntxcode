//
//  CookingParameters.swift
//  UnBurnt ios app
//
//  Created by Lila Kelland on 2020-08-21.
//  Copyright © 2020 Lila Kelland. All rights reserved.

// push and gets cooking parameters (cooking timer, high temp and low temp) to and from server
//
 // top level vars  = state
// func = behaviour

import UIKit
import Alamofire
import SwiftyJSON

extension String {
    var isInt: Bool {
        return Int(self) != nil
    }
}

extension String {
    var isNeg: Bool {
        return Int(self)! < 0
    }
}

struct ConfigWebData: Decodable{
    let lowTemp: String
    let highTemp: String
    let checkTime: String
}

enum InputError: Error {
    case inputEmpty(message: String)
    case inputNonInteger(message: String)
    case inputNegative(message: String)
    case lowVsHigh(message: String)
}

class CookingParameters {
    
    var lowTempInput: String = "30"
    var highTempInput: String = "700"
    var checkTimeInput: String = "300"
    
    var goldLowTempLimit: String!
    var goldHighTempLimit: String!
    var goldCheckTime: String!
    
    init(){
        //get limits from server
        goldLowTempLimit = lowTempInput//myInputs.lowTempInput
        goldHighTempLimit = highTempInput//myInputs.highTempInput
        goldCheckTime = checkTimeInput//myInputs.checkTimeInput
    }
    
//Validate user inputs
    func checkLowTempInput(lowTempInputToValidate: String) throws  {
    // need to error try except at input not output just error string
        guard lowTempInputToValidate.isEmpty == false else {
            throw InputError.inputEmpty(message: "")
        }
        if lowTempInputToValidate.isEmpty == false {
            guard lowTempInputToValidate.isInt == true else {
                throw InputError.inputNonInteger(message: "Low temp limit value must be an integer.")
            }
        }
        guard lowTempInputToValidate.isNeg == false else {
            throw InputError.inputNegative(message: "Low temp limit value must be positive.")
        }
    }
            
    func checkHighTempInput(lowTempInputToValidate:String, highTempInputToValidate:String) throws  {
        guard highTempInputToValidate.isEmpty == false else{
            throw InputError.inputEmpty(message: "")
        }
        guard highTempInputToValidate.isInt == true else{
                throw InputError.inputNonInteger(message: "High temp limit value must be an integer.")
        }
        guard highTempInputToValidate.isNeg == false else{
            throw InputError.inputNegative(message: "High temp limit value must be positive. ")
        }
        if (highTempInputToValidate.isEmpty == false) && (lowTempInputToValidate.isEmpty == false){
            guard (Int(lowTempInputToValidate)! < Int(highTempInputToValidate)!) else {
                throw InputError.lowVsHigh(message: "High temp limit must be larger than low temp.")
            }
        }
    }
    
    func checkCheckTimeInput(checkTimeInputToValidate: String) throws  {
        guard checkTimeInputToValidate.isEmpty == false else {
            throw InputError.inputEmpty(message: "")
        }
        guard checkTimeInputToValidate.isInt == true else {
            throw InputError.inputNonInteger(message: "Check Time limit value must be an integer.")
        }
        guard checkTimeInputToValidate.isNeg == false else {
            throw InputError.inputNegative(message: "Check Time limit value must be positive. ")
        }
    }

// Set (input) parameters to defaults (limit) if pass checks
    func setLowTempLimit(lowTempInput: String) throws {
        try checkLowTempInput(lowTempInputToValidate: lowTempInput)
        // if no exceptions:
        if highTempInput.isEmpty == false {
            goldLowTempLimit = lowTempInput
        }
    }
    
    func setHighTempLimit(lowTempInput: String, highTempInput: String) throws {
        try checkHighTempInput(lowTempInputToValidate: lowTempInput, highTempInputToValidate: highTempInput)
         // if no exceptions:
        if highTempInput.isEmpty == false {
            goldHighTempLimit = highTempInput
        }
     }
        
    func setCheckTimeLimit(checkTimeInput: String) throws {
        try checkCheckTimeInput(checkTimeInputToValidate: checkTimeInput)
         // if no exceptions:
        if checkTimeInput.isEmpty == false {
            goldCheckTime = checkTimeInput
        }
     }

// Push parameters to server
    func pushCookingParametersToServer(lowTempLimit: String, highTempLimit: String, checkTime: String) throws  {
        
        let parameters = [
            "lowTemp": goldLowTempLimit,
            "highTemp": goldHighTempLimit,
            "checkTime": goldCheckTime
            ]
        
       // getCookingParameters(lowTempInput: String, highTempInput: String, checkTimeInput: String)
        AF.request("\(Environment.url_string)/cookingParameters", method: .get, parameters: parameters)
           .validate()
          .responseString {
            response in
               switch response.result {
                   case .success( _):
                       print("parameters set on server - sucess!")
//                       self.finishSetLoad = true
                   case .failure(let error):
//                        self.finishSetLoad = false
                       print(error)
                }
            }
    }

// Read each parameter from server
    func getLowTempCookingParameter() -> String  {
        var finishLoad: Bool = false
        var counter: Int = 0
        AF.request("\(Environment.url_string)/getDefaultConfig").responseData { response in
                switch response.result {
                    case .failure(let error):
                        print(error)
                    case .success(let data):
                        do {
                            let configWebData = try JSONDecoder().decode(ConfigWebData.self, from: data)
                            self.goldLowTempLimit = (configWebData.lowTemp)
                            finishLoad = true

                        } catch let error {
                            print(error)
                            finishLoad = false
                    }
                }
            while finishLoad == false {
                sleep(1)
                if counter <= 10 {
                    counter += 1
                } else {
                    finishLoad = true
                }
            }
        }
        return self.goldLowTempLimit
    }
    
    func getHighTempCookingParameter() -> String {
        var finishLoad: Bool = false
        var counter: Int = 0
        AF.request("\(Environment.url_string)/getDefaultConfig").responseData { response in
                switch response.result {
                    case .failure(let error):
                        print(error)
                    case .success(let data):
                        do {
                            let configWebData = try JSONDecoder().decode(ConfigWebData.self, from: data)
                            self.goldHighTempLimit = (configWebData.highTemp)
                            finishLoad = true

                        } catch let error {
                            print(error)
                            finishLoad = false
                    }
                }
            while finishLoad == false {
                sleep(1)
                if counter <= 10 {
                    counter += 1
                } else {
                    finishLoad = true
                }
            }
        }
        
        return self.goldHighTempLimit
    }
    
    func getCheckTimeCookingParameter() -> String {
        var finishLoad: Bool
            = false
        var counter: Int = 0
        AF.request("\(Environment.url_string)/getDefaultConfig").responseData { response in
                switch response.result {
                    case .failure(let error):
                        print(error)
                    case .success(let data):
                        do {
                            let configWebData = try JSONDecoder().decode(ConfigWebData.self, from: data)
                            self.goldCheckTime = (configWebData.checkTime)
                            finishLoad = true

                        } catch let error {
                            print(error)
                            finishLoad = false
                    }
                }
            
            while finishLoad == false {
                sleep(1)
                if counter <= 10 {
                    counter += 1
                } else {
                    finishLoad = true
                }
            }
            
        }
        return self.goldCheckTime
    }
   
}
