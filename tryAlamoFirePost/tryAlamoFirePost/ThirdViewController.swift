//
//  ThirdViewController.swift
//  tryAlamoFirePost
//
//  Created by Lila Kelland on 2020-07-17.
//  Copyright © 2020 Lila Kelland. All rights reserved.
//

import UIKit
import Charts
import TinyConstraints
import Alamofire
import SwiftyJSON


//var highTempLimitLine = (highTempLimit! as NSString).doubleValue
//var lowTempLimitLine = (lowTempLimit! as NSString).doubleValue

struct TempTimeWebData:Decodable{
    let lowTempLimit: Double
    let highTempLimit: Double
    let tempArray: [Double]
    let timeArray: [Double]
    let tempCount: Int
}

class ThirdViewController: UIViewController, ChartViewDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var cookingParameters: CookingParameters
        required init?(coder: NSCoder) {
            self.cookingParameters = appDelegate.cookingParameters
            super.init(coder: coder)
    }
    
    let containerViewHeight: CGFloat = 100
    var timer = Timer()
    
    func runUpdates() {
         timer = Timer.scheduledTimer(timeInterval: 2, target: self,   selector: (#selector(ThirdViewController.updateDisplay)), userInfo: nil, repeats: true)
    }
    
    @objc func updateDisplay() {
        getData()
    }
        
    func getData() {
        getTempTimeLists()
    }


    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray2
        return view
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26)
        label.textAlignment = .center
        label.textColor = .black
        label.shadowOffset = CGSize(width: 0, height: -0.5)
        label.shadowColor = .systemGray5
        label.text = "BBQ Temperatures"
        return label
    }()

    lazy var lineChartView: LineChartView = {
        let chartView = LineChartView()
        chartView.backgroundColor = .systemGray2

        chartView.rightAxis.enabled = false

        let yAxis = chartView.leftAxis
        yAxis.labelFont = .boldSystemFont(ofSize: 12)
        yAxis.setLabelCount(6, force: false)
        yAxis.labelTextColor = .white
        yAxis.axisLineColor = .systemRed
        yAxis.labelPosition = .outsideChart

        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelFont = .boldSystemFont(ofSize: 12)
        chartView.xAxis.setLabelCount(6, force: false)
        chartView.xAxis.labelTextColor = .white
        chartView.xAxis.axisLineColor = .systemRed

        chartView.animate(xAxisDuration: 1)

        return chartView
    }()

    func getTempTimeLists() {
        var ychartvalues: [Double] = [0]
        var xchartvalues: [Double] = [0]
        var tempCount: Int = 0
        var highTempLimitLine: Double = 80
        var lowTempLimitLine: Double = 100
        var yvalues = [ChartDataEntry]()
        var lowTempValues = [ChartDataEntry]()
        var highTempValues = [ChartDataEntry]()
        
        AF.request("http://192.168.7.87:8080/getTempTimeArray").responseData { response in
            switch response.result {
                case .failure(let error):
                    print(error)
                case .success(let data):
                    do {
                        let tempTimeWebData = try JSONDecoder().decode(TempTimeWebData.self, from: data)
                        xchartvalues = (tempTimeWebData.timeArray)
                        ychartvalues = (tempTimeWebData.tempArray)
                        tempCount = (tempTimeWebData.tempCount)
                        highTempLimitLine = (tempTimeWebData.highTempLimit)
                        lowTempLimitLine = (tempTimeWebData.lowTempLimit)

                        for i in 0..<tempCount {
                            yvalues.append(ChartDataEntry(x: xchartvalues[i] , y: ychartvalues[i] ))
                        }
                        
                        for i in 0..<tempCount {
                            lowTempValues.append(ChartDataEntry(x: xchartvalues[i] , y:lowTempLimitLine ))
                        }
                        for i in 0..<tempCount {
                            highTempValues.append(ChartDataEntry(x: xchartvalues[i] , y: highTempLimitLine ))
                        }

                        self.setData(yvaluesp: yvalues, highTempValues: highTempValues, lowTempValues: lowTempValues )
                    } catch let error {
                        print(error)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(containerView)
        view.addSubview(label)

        containerView.edgesToSuperview(excluding: .bottom, insets: .top(27), usingSafeArea: true)
        containerView.height(containerViewHeight)

        label.edges(to: containerView)
        view.addSubview(lineChartView)
        lineChartView.centerInSuperview()
        lineChartView.width(to: view)
        lineChartView.heightToWidth(of: view)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right

        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        runUpdates()
        
        
        
    }
    
    @objc func handleSwipes(_ sender: UISwipeGestureRecognizer)
    {
        if sender.direction == .left
        {
           print("Swipe left")
           // show the view from the right side
        }

        if sender.direction == .right
        {
           print("Swipe right")
           // show the view from the left side
        }
    }

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }

    func setData(yvaluesp: [ChartDataEntry], highTempValues: [ChartDataEntry], lowTempValues: [ChartDataEntry]) {
        var allLineChartDataSets: [LineChartDataSet] = [LineChartDataSet]()
        
       // let data = lineChartData
        let set1 = LineChartDataSet(entries: yvaluesp , label: "BBQ Temperatures F / Time (s)")
        let lowTemp = LineChartDataSet(entries: lowTempValues , label: "Low Temperature Cooking Limit \(cookingParameters.goldLowTempLimit ?? "70")")
        let highTemp = LineChartDataSet(entries: highTempValues , label: "High Temperature Cooking Limit \(cookingParameters.goldHighTempLimit ?? "400")")
        
        allLineChartDataSets.append(set1)
        allLineChartDataSets.append(highTemp)
        allLineChartDataSets.append(lowTemp)

        
         // Set gradient
        let gradientColors = [UIColor.systemOrange.cgColor, UIColor.clear.cgColor] as CFArray
        let colorLocations:[CGFloat] = [1.0, 0.0]
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object

         set1.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
         set1.drawFilledEnabled = true // Draw the Gradient

         set1.mode = .cubicBezier
         set1.drawCirclesEnabled = false
         set1.valueFont = .boldSystemFont(ofSize: 12)
         set1.valueTextColor = .white
         set1.lineWidth = 2
         set1.setColor(.red)
         set1.fillAlpha = 0.8
         set1.drawFilledEnabled = true
         set1.drawValuesEnabled = false

         set1.drawHorizontalHighlightIndicatorEnabled = false
         set1.highlightColor = .systemRed
        
        //highTemp.axisDependency = .left // Line will correlate with left axis values
       // highTemp.setColor(UIColor.green.withAlphaComponent(0.5))
        highTemp.lineWidth = 1.0
        highTemp.lineDashLengths = [8]
        highTemp.drawCirclesEnabled = false
        highTemp.setColor(UIColor(red: 1, green: 0, blue: 0, alpha: 0.25))
        highTemp.drawHorizontalHighlightIndicatorEnabled = false
        highTemp.drawVerticalHighlightIndicatorEnabled = false
        
        lowTemp.lineWidth = 1.0
        lowTemp.lineDashLengths = [8]
        lowTemp.drawCirclesEnabled = false
        lowTemp.setColor(UIColor(red: 0, green: 1, blue: 1, alpha: 0.2))
        lowTemp.drawHorizontalHighlightIndicatorEnabled = false
        lowTemp.drawVerticalHighlightIndicatorEnabled = false
    
        

//             let lineChartData = LineChartData(xVals: allDataPoints, dataSets: allLineChartDataSets)
//
//            testLineChartView.data = lineChartData
//
            
    
         let data = LineChartData(dataSets: allLineChartDataSets)
         lineChartView.data = data
         data.setDrawValues(false)
    }

      //------------------------------------------------------------------------------------------
//    func setData() {
//        let set1 = LineChartDataSet(entries: yValues, label: "BBQ Temperatures (F) / Time (s)")
//
//        // Set gradient
//        let gradientColors = [UIColor.systemOrange.cgColor, UIColor.clear.cgColor] as CFArray
//        let colorLocations:[CGFloat] = [1.0, 0.0]
//        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
//
//        set1.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
//        set1.drawFilledEnabled = true // Draw the Gradient
//
//        set1.mode = .cubicBezier
//        set1.drawCirclesEnabled = false
//        set1.valueFont = .boldSystemFont(ofSize: 12)
//        set1.valueTextColor = .white
//        set1.lineWidth = 1
//        set1.setColor(.red)
//        set1.fillAlpha = 0.8
//        set1.drawFilledEnabled = true
//        set1.drawValuesEnabled = true
//
//        set1.drawHorizontalHighlightIndicatorEnabled = false
//        set1.highlightColor = .systemRed
//
//
//        let data = LineChartData(dataSet: set1)
//        lineChartView.data = data
//        data.setDrawValues(true)
//
//        //lineChartView.highlightValue(x: <#T##Double#>, dataSetIndex: <#T##Int#>, dataIndex: <#T##Int#>)
//    }
 // ----------------------------------------------
//    let data = LineChartData()
//    var lineChartEntry1 = [ChartDataEntry]()
//
//    for i in 0..<x1.count {
//        lineChartEntry1.append(ChartDataEntry(x: Double(i), y: Double(x1[i]) ?? 0.0))
//    }
//    let line1 = LineChartDataSet(values: lineChartEntry1, label: "First Dataset")
//    data.addDataSet(line1)
//    if (x2.count > 0) {
//        var lineChartEntry2 = [ChartDataEntry]()
//        for i in 0..<x2.count {
//            lineChartEntry2.append(ChartDataEntry(x: Double(i), y: Double(x2[i]) ?? 0.0))
//        }
//    let line2 = LineChartDataSet(values: lineChartEntry2, label: "Second Dataset")
//    data.addDataSet(line2)

//___________________________________________
//    let yValues: [ChartDataEntry] = [
//        ChartDataEntry(x: 0.0, y: 10.0),
//        ChartDataEntry(x: 1.0, y: 14.0),
//        ChartDataEntry(x: 2.0, y: 17.0),
//        ChartDataEntry(x: 3.0, y: 18.0),
//        ChartDataEntry(x: 4.0, y: 11.0),
//        ChartDataEntry(x: 5.0, y: 16.0),
//        ChartDataEntry(x: 6.0, y: 18.0),
//        ChartDataEntry(x: 7.0, y: 13.0),
//        ChartDataEntry(x: 8.0, y: 17.0),
//        ChartDataEntry(x: 9.0, y: 15.0),
//    ]

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
