//
//  ViewController.swift
//  tryoutAlamoFire
//
//  Created by Lila Kelland on 2020-07-06.
//  Copyright © 2020 Lila Kelland. All rights reserved.
//

import UIKit
import Alamofire

struct WebData:Decodable{
    let tempf: String
}

class ViewController: UIViewController {

    @IBOutlet weak var currentTemp: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let jsonUrlString = "http://192.168.7.82/"
        
        AF.request(jsonUrlString).responseData { response in
            switch response.result {
            case .failure(let error):
                print(error)
            case .success(let data):
                do {
                    let webData = try JSONDecoder().decode(WebData.self, from: data)
                    print(webData.tempf)
                    self.currentTemp.text = (webData.tempf)
                } catch let error {
                    print(error)
                }
                //#currentTemp.text = "..."
            }
        }
        
    }
       

}

//inside testt1Unburnt
let parameters = [
    "lowTemp": lowTempTextField.placeholder,
    "highTemp": highTempTextField.placeholder,
    "checkTime": checkTimeTextField.placeholder]

Alamofire.request(.POST, "http://127.0.0.1:8080/api", parameters: parameters, encoding: .JSON)
    .responseJSON { request, response, JSON, error in
        print(response)
        print(JSON)
        print(error)
    }
