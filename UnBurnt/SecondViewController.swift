//
//  SecondViewController.swift
//  UnBurnt
//
//  Created by Lila Kelland on 2020-07-09.
//  Copyright © 2020 Lila Kelland. All rights reserved.
//
//  Displays temperatures (left and right side) and times (since last read from server, and time to next BBQ check)
//  Temperatures change colour with cooking state - dial background turns red if presumed on fire
//  If there is something flaky with thermocouple will display greyed out "N/A" (but for any calculations will use other thermocouple's value)
//  Used guage from:
//https://www.hackingwithswift.com/articles/150/how-to-create-a-custom-gauge-control-using-uikit

import UIKit
import Alamofire
import SwiftyJSON
import SwiftUI

struct WebData:Decodable{
    let tempf1: Int
    let tempf2: Int
    let is_tempf1_valid: Bool
    let is_tempf2_valid: Bool
    let combined_temp: Int
    let timeElapsed: String
    let checkTimer: String
    let timeNow: Int
    let timeStamp: String
}

struct StateData:Decodable{
    let state: String
}

//-------------------code between"-----" (below to next set of dashes) only very slightly modified from indicated refrerence

class GaugeView: UIView{
    //https://www.hackingwithswift.com/articles/150/how-to-create-a-custom-gauge-control-using-uikit
    var outerBezelColor = UIColor.darkGray//(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    var outerBezelWidth: CGFloat = 10

    var innerBezelColor = UIColor.lightGray
    var innerBezelWidth: CGFloat = 5

    var insideColor = UIColor.systemGray4
    
    var segmentWidth: CGFloat = 20
    var segmentColors = [UIColor(red: 0, green: 1, blue: 1, alpha: 0.2), UIColor(red: 0, green: 1, blue: 0, alpha: 0.25), UIColor(red: 0, green: 1, blue: 0, alpha: 0.25), UIColor(red: 0, green: 1, blue: 0, alpha: 0.25), UIColor(red: 1, green: 0, blue: 0, alpha: 0.25)]
    
    //8 and 4
    var totalAngle: CGFloat = 270
    var rotation: CGFloat = -135
    
    var majorTickColor = UIColor.darkGray
    var majorTickWidth: CGFloat = 2
    var majorTickLength: CGFloat = 25

    var minorTickColor = UIColor.black.withAlphaComponent(0.5)
    var minorTickWidth: CGFloat = 1
    var minorTickLength: CGFloat = 20
    var minorTickCount = 3
    
    var outerCenterDiscColor = UIColor(white: 0.9, alpha: 1)
    var outerCenterDiscWidth: CGFloat = 35
    var innerCenterDiscColor = UIColor(white: 0.5, alpha: 1)
    var innerCenterDiscWidth: CGFloat = 25
    
    var needleColor = UIColor(white: 0.5, alpha: 1)
    var needleWidth: CGFloat = 4
    let needle = UIView()
    
    let valueLabelL = UILabel()
    let valueLabelR = UILabel()
    var valueFont = UIFont.systemFont(ofSize: 30)
    
    
    func drawBackground(in rect: CGRect, context ctx: CGContext) {
        // draw the outer bezel as the largest circle
        outerBezelColor.set()
        ctx.fillEllipse(in: rect)

        // move in a little on each edge, then draw the inner bezel
        let innerBezelRect = rect.insetBy(dx: outerBezelWidth, dy: outerBezelWidth)
        innerBezelColor.set()
        ctx.fillEllipse(in: innerBezelRect)

        // finally, move in some more and draw the inside of our gauge
        let insideRect = innerBezelRect.insetBy(dx: innerBezelWidth, dy: innerBezelWidth)
        insideColor.set()
        ctx.fillEllipse(in: insideRect)
        
    }
    override func draw(_ rect: CGRect) {
               guard let ctx = UIGraphicsGetCurrentContext() else { return }
               drawBackground(in: rect, context: ctx)
                drawSegments(in: rect, context: ctx)
                drawTicks(in: rect, context: ctx)
                drawCenterDisc(in: rect, context: ctx)
           }
    
    func deg2rad(_ number: CGFloat) -> CGFloat {
        return number * .pi / 180
    }
    
    func drawCenterDisc(in rect: CGRect, context ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: rect.midX, y: rect.midY)

        let outerCenterRect = CGRect(x: -outerCenterDiscWidth / 2, y: -outerCenterDiscWidth / 2, width: outerCenterDiscWidth, height: outerCenterDiscWidth)
        outerCenterDiscColor.set()
        ctx.fillEllipse(in: outerCenterRect)

        let innerCenterRect = CGRect(x: -innerCenterDiscWidth / 2, y: -innerCenterDiscWidth / 2, width: innerCenterDiscWidth, height: innerCenterDiscWidth)
        innerCenterDiscColor.set()
        ctx.fillEllipse(in: innerCenterRect)
        ctx.restoreGState()
    }
    
    
    func drawSegments(in rect: CGRect, context ctx: CGContext) {
        // 1: Save the current drawing configuration
        ctx.saveGState()

        // 2: Move to the center of our drawing rectangle and rotate so that we're pointing at the start of the first segment
        ctx.translateBy(x: rect.midX, y: rect.midY)
        ctx.rotate(by: deg2rad(rotation) - (.pi / 2))

        // 3: Set up the user's line width
        ctx.setLineWidth(segmentWidth)

        // 4: Calculate the size of each segment in the total gauge
        let segmentAngle = deg2rad(totalAngle / CGFloat(segmentColors.count))

        // 5: Calculate how wide the segment arcs should be
        let segmentRadius = (((rect.width - segmentWidth) / 2) - outerBezelWidth) - innerBezelWidth

        // 6: Draw each segment
        for (index, segment) in segmentColors.enumerated() {
            // figure out where the segment starts in our arc
            let start = CGFloat(index) * segmentAngle

            // activate its color
            segment.set()

            // add a path for the segment
            ctx.addArc(center: .zero, radius: segmentRadius, startAngle: start, endAngle: start + segmentAngle, clockwise: false)

            // and stroke it using the activated color
            ctx.drawPath(using: .stroke)
        }

        // 7: Reset the graphics state
        ctx.restoreGState()
    }
    
    func drawTicks(in rect: CGRect, context ctx: CGContext) {
        // save our clean graphics state
        ctx.saveGState()
        ctx.translateBy(x: rect.midX, y: rect.midY)
        ctx.rotate(by: deg2rad(rotation) - (.pi / 2))

        let segmentAngle = deg2rad(totalAngle / CGFloat(segmentColors.count))

        let segmentRadius = (((rect.width - segmentWidth) / 2) - outerBezelWidth) - innerBezelWidth

        // save the graphics state where we've moved to the center and rotated towards the start of the first segment
        ctx.saveGState()

        ctx.setLineWidth(majorTickWidth)
        majorTickColor.set()
        
        let majorEnd = segmentRadius + (segmentWidth / 2)
        let majorStart = majorEnd - majorTickLength

        for _ in 0 ... segmentColors.count {
            ctx.move(to: CGPoint(x: majorStart, y: 0))
            ctx.addLine(to: CGPoint(x: majorEnd, y: 0))
            ctx.drawPath(using: .stroke)
            ctx.rotate(by: segmentAngle)
        }
        // go back to the state we had before we drew the major ticks
        ctx.restoreGState()

        // save it again, because we're about to draw the minor ticks
        ctx.saveGState()

        ctx.setLineWidth(minorTickWidth)
        minorTickColor.set()

        let minorEnd = segmentRadius + (segmentWidth / 2)
        let minorStart = minorEnd - minorTickLength
        let minorTickSize = segmentAngle / CGFloat(minorTickCount + 1)
        
        for _ in 0 ..< segmentColors.count {
            ctx.rotate(by: minorTickSize)

            for _ in 0 ..< minorTickCount {
                ctx.move(to: CGPoint(x: minorStart, y: 0))
                ctx.addLine(to: CGPoint(x: minorEnd, y: 0))
                ctx.drawPath(using: .stroke)
                ctx.rotate(by: minorTickSize)
            }
        }
        // go back to the graphics state where we've moved to the center and rotated towards the start of the first segment
        ctx.restoreGState()

        // go back to the original graphics state
        ctx.restoreGState()
    }

    func setUp() {
        needle.backgroundColor = needleColor
        needle.translatesAutoresizingMaskIntoConstraints = false

        // make the needle a third of our height
        needle.bounds = CGRect(x: 0, y: 0, width: needleWidth, height: bounds.height / 3)

        // align it so that it is positioned and rotated from the bottom center
        needle.layer.anchorPoint = CGPoint(x: 0.5, y: 1)

        // now center the needle over our center point
        needle.center = CGPoint(x: bounds.midX, y: bounds.midY)
        addSubview(needle)
    //--------------------------------------------------------------------------------------------------
    // below to next "-------" still from reference but I've modified below
        
        valueLabelL.font = valueFont
        valueLabelR.font = valueFont
        valueLabelL.textColor = UIColor.systemGray
        valueLabelR.textColor = UIColor.systemGray
        valueLabelL.text = "N/A"
        valueLabelR.text = "N/A"
        valueLabelL.translatesAutoresizingMaskIntoConstraints = false
        valueLabelR.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabelL)
        addSubview(valueLabelR)

        NSLayoutConstraint.activate([

            valueLabelL.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -30),
            valueLabelL.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -23),
            valueLabelR.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 33),
            valueLabelR.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -23)
        ])
    }
    
    var needlePosition: CGFloat = 0
    
    var needleTemp: CGFloat = 0.0001 {
        didSet {
            needlePosition =  self.needleTemp / 800.0
            print (self.needleTemp)
            
            // create a lerp from the start angle (rotation) through to the end angle (rotation + totalAngle)
            let lerpFrom = rotation
            let lerpTo = rotation + totalAngle

            // lerp from the start to the end position, based on the needle's position
            let needleRotation = lerpFrom + (lerpTo - lerpFrom) * needlePosition
            needle.transform = CGAffineTransform(rotationAngle: deg2rad(needleRotation))
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
}
//-------------------------------------------------------------------------------- from reference above


class SecondViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var cookingParameters: CookingParameters
        required init?(coder: NSCoder) {
            self.cookingParameters = appDelegate.cookingParameters
            super.init(coder: coder)
    }

    @IBOutlet weak var timeElapsed: UILabel!
    @IBOutlet weak var timerCountdown: UILabel!
    @IBOutlet weak var tempTimestamp: UILabel!
    @IBOutlet weak var StackViewBkg: UIStackView! // determine how to get rid of this
    @IBOutlet var TempTimeView: UIView! // ditto
    
    var gaugeView: GaugeView!
    var timer = Timer()
    var tempf1Valid: Bool = false
    var tempf2Valid: Bool = false
    var tempf1: Int = 0
    var tempf2: Int = 0
    var timeElapsedInSeconds: Int = 0
    var timerCountdownInSeconds: Int = 0
    var webTimeElapsed: String = ""
    var webCheckTimer: String = ""
    var webTimeStamp: String = ""
    var needleTemp: CGFloat = 0.000001
    var counter: Int = 7
    var serversTimeNow: Int = 0
    var cookingState: String = "cold_off"
    

    func runUpdates() {
         timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(SecondViewController.updateDisplay)), userInfo: nil, repeats: true)
    }
    
//**
    @objc func updateDisplay() {
        syncronizeDataDisplayTimers()
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return (String(format: "%02d:%02d:%02d", hours, minutes, seconds))
    }
    
    func isServerUpToDate() -> Bool {
        if (Int(NSDate().timeIntervalSince1970) - self.serversTimeNow) < 20 {
            return true
        } else {
            return false
        }
    }
    
    func syncronizeDataDisplayTimers() { ///still a bit funny - need to stop slight delay when checking server for updates, and subsequent jump forward to catch up
        print("counter \(counter)")
        print("server time delay \(Int(NSDate().timeIntervalSince1970) - self.serversTimeNow)")
        if ((self.tempf1Valid == false) && (self.tempf2Valid == false)){
            print("sensor lost")
            counter = 6
        }
        
        if counter < 6 {
            self.counter += 1
            if self.timeElapsedInSeconds > 7 {
                self.timeElapsedInSeconds += 1
            }
            if self.timerCountdownInSeconds > 0 {
                self.timerCountdownInSeconds -= 1
            }
            if (isServerUpToDate() == false) || (self.cookingState == "cold_off") {
                self.timeElapsed.text = self.timeString(time: TimeInterval(0))
                self.timerCountdown.text = self.timeString(time: TimeInterval(0))
            } else {
                
                self.timeElapsed.text = self.timeString(time: TimeInterval(self.timeElapsedInSeconds))
                self.timerCountdown.text = self.timeString(time: TimeInterval(self.timerCountdownInSeconds))
            }
            
        } else {
            self.counter = 0
            self.getTempTime()
            self.upDateTimeStampandTimerText()
            self.setGaugeDisplayColours()
            self.upDateGaugeNeedlePosition()
            self.updateGaugeTempValues()
        }
    }

    
    func getTempTime() {
        AF.request("\(Environment.url_string)/getTempTime").responseData { response in
            switch response.result {
                case .failure(let error):
                    print(error)
                case .success(let data):
                    do {
                        let webData = try JSONDecoder().decode(WebData.self, from: data)

                        self.serversTimeNow = webData.timeNow
                        self.tempf1 = webData.tempf1
                        self.tempf2 = webData.tempf2
                        self.tempf1Valid = webData.is_tempf1_valid
                        self.tempf2Valid = webData.is_tempf2_valid
                        self.webTimeElapsed = webData.timeElapsed
                        self.webCheckTimer = webData.checkTimer
                        self.webTimeStamp = webData.timeStamp
                        self.needleTemp = CGFloat(webData.combined_temp)
                        print("needleTemp \(self.gaugeView.needleTemp)")
//                        Add in exception handling when passed from python
                } catch let error {
                    print(error)
                }
            }
        }
    }
    
    func upDateTimeStampandTimerText(){
        if (self.isServerUpToDate()){
            self.setTimerCountDownText()
            self.setTimeElapsedText()
        }
        self.tempTimestamp.text = self.webTimeStamp
    }
    
    func setTimeElapsedText() {
        if (self.webTimeElapsed.isInt == true) && (Int(self.webTimeElapsed)! >= self.timeElapsedInSeconds) {
                self.timeElapsedInSeconds = Int(self.webTimeElapsed)!
                self.timeElapsed.text = self.timeString(time: TimeInterval(self.timeElapsedInSeconds))
        }
    }
    
    func setTimerCountDownText() {
        if (self.webCheckTimer.isInt == true) && (Int(self.webCheckTimer)! >= self.timerCountdownInSeconds) {
            self.timerCountdownInSeconds = Int(self.webCheckTimer)!
            self.timerCountdown.text = self.timeString(time: TimeInterval(self.timerCountdownInSeconds))
        }
    }
    
    func getLowTempLimit()  -> String {
        var lowTempLimit: String! = "30"
        lowTempLimit = cookingParameters.getLowTempCookingParameter()
        return(lowTempLimit)
    }
    
    func getHighTempLimit()  -> String {
        var highTempLimit: String! = "700"
        highTempLimit = cookingParameters.getHighTempCookingParameter()
        return(highTempLimit)
    }
    
    func getCookingState(){
        AF.request("\(Environment.url_string)/getState").responseData { [self] response in
            switch response.result {
                case .failure(let error):
                    print(error)
                case .success(let sdata):
                    do {
                       let stateData = try JSONDecoder().decode(StateData.self, from: sdata)
                       self.cookingState = stateData.state

                       print("cooking state \(self.cookingState)")
                        
                } catch let error {
                   print(error)
               }
            }
        }
    }
    
    func setGaugeDisplayColours(){
        var lowTempLimit: String
        var highTempLimit: String
        
        var label1color: UIColor = UIColor.systemBlue
        var label2color: UIColor = UIColor.systemBlue
        var insideGuageColor: UIColor = UIColor.systemGray4
        
        lowTempLimit = getLowTempLimit()
        highTempLimit = getHighTempLimit()
        getCookingState()
        
        print("low temp limit \(String(describing: Int(lowTempLimit)))")
        print("high temp limit \(String(describing: Int(highTempLimit)))")
        
        if isServerUpToDate() {
            if ((self.cookingState == "cold_off") || ((self.tempf1Valid == false) && (self.tempf2Valid == false))){
                label1color = UIColor.systemBlue
                label2color = UIColor.systemBlue
                insideGuageColor = UIColor.systemGray4
            }
            
            if (self.cookingState == "burning") {
                 label1color = .darkGray
                 label2color = .darkGray
                 insideGuageColor = UIColor.systemRed
            }
            
            if (self.cookingState.hasPrefix("cooking")) {
                    
                if self.tempf1Valid {
                    if (self.tempf1 <= Int(lowTempLimit)!) {
                        label1color = UIColor.systemBlue
                        insideGuageColor = UIColor.systemGray4
                    } else if (self.tempf1 >= Int(highTempLimit)!) {
                        label1color = UIColor.systemRed
                        insideGuageColor = UIColor.systemGray4
                    } else {
                        label1color = UIColor.systemOrange
                        insideGuageColor = UIColor.systemGray4
                    }
                } else {
                        label1color = UIColor.systemGray
                }
                
                if self.tempf2Valid {
                    if (self.tempf2 <= Int(lowTempLimit)!) {
                        label2color = UIColor.systemBlue
                    } else if (self.tempf2 >= Int(highTempLimit)!) {
                        label2color = UIColor.systemRed
                    } else  {
                        label2color = UIColor.systemOrange
                    }
                } else {
                    label2color = UIColor.systemGray
                }
            }
            
        } else {
               label1color = UIColor.systemGray
               label2color = UIColor.systemGray
               insideGuageColor = UIColor.systemGray4
        }
    
        self.gaugeView.valueLabelL.textColor = label1color
        self.gaugeView.valueLabelR.textColor = label2color
        self.gaugeView.insideColor = insideGuageColor
        self.gaugeView.setNeedsDisplay()
    }
    
    func upDateGaugeNeedlePosition(){
        if isServerUpToDate() == false {
            self.gaugeView.needleTemp = 0.001
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIView.animate(withDuration: 1) {
                    self.gaugeView.needleTemp = self.needleTemp
                }
            }
        }
    }
    
    func updateGaugeTempValues() {
            if ((self.tempf1Valid == true) && (isServerUpToDate())) {
                self.gaugeView.valueLabelL.text = String(self.tempf1)
            } else {
                self.gaugeView.valueLabelL.text = "N/A"
            }
        
            if ((self.tempf2Valid == true) && (isServerUpToDate())) {
                self.gaugeView.valueLabelR.text = String(self.tempf2)
            } else {
                self.gaugeView.valueLabelR.text = "N/A"
            }
    }

    
    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications() // will need this in the main thread - to kick off registration of APNS
        }
      }
    }
        

    override func viewDidLoad() {
        super.viewDidLoad()
            self.gaugeView = GaugeView(frame: CGRect(x: 65, y: 40, width: 256, height: 256))
            self.gaugeView.backgroundColor = .systemGray2
            self.view.addSubview(gaugeView)

            //subscribeToNotifications()
            runUpdates()
    }
    
}


