//
//  ThirdViewController.swift
//  tryAlamoFirePost
//
//  Created by Lila Kelland on 2020-07-17.
//  Copyright © 2020 Lila Kelland. All rights reserved.
//
// Displays temp over time chart with lowTempLimit, highTempLimit, tempf1 and tempf2.  If the sensor is invalid, line will turn grey.
// Main chart set up code based from a tutorial - will find reference

import UIKit
import Charts
import TinyConstraints
import Alamofire
import SwiftyJSON

struct TempTimeWebData:Decodable{
    let lowTempLimit: Double
    let highTempLimit: Double
    let tempArray: [Double]
    let timeArray: [Double]
    let tempArray2: [Double]
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
        // refreshes
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
        var ychartvalues2: [Double] = [0]
        var xchartvalues2: [Double] = [0]
        var tempCount: Int = 0
        var highTempLimitLine: Double = 80
        var lowTempLimitLine: Double = 100
        var yvalues = [ChartDataEntry]()
        var yvalues2 = [ChartDataEntry]()
        var lowTempValues = [ChartDataEntry]()
        var highTempValues = [ChartDataEntry]()
        
        AF.request("\(Environment.url_string)/getTempTimeArray").responseData { response in
            switch response.result {
            //loads data for data points on chart
                case .failure(let error):
                    print(error)
                case .success(let data):
                    do {
                        let tempTimeWebData = try JSONDecoder().decode(TempTimeWebData.self, from: data)
                        xchartvalues = (tempTimeWebData.timeArray)
                        ychartvalues = (tempTimeWebData.tempArray)
                        xchartvalues2 = xchartvalues
                        ychartvalues2 = (tempTimeWebData.tempArray2)
                        tempCount = (tempTimeWebData.tempCount)
                        highTempLimitLine = (tempTimeWebData.highTempLimit)
                        lowTempLimitLine = (tempTimeWebData.lowTempLimit)

                        for i in 0..<tempCount {
                            yvalues.append(ChartDataEntry(x: xchartvalues[i] , y: ychartvalues[i] ))
                            yvalues2.append(ChartDataEntry(x: xchartvalues2[i] , y: ychartvalues2[i] ))
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
        
        runUpdates()
    }

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }

    func setData(yvaluesp: [ChartDataEntry], highTempValues: [ChartDataEntry], lowTempValues: [ChartDataEntry]) {
        // Sets data points and characteristics of chart
        
        var allLineChartDataSets: [LineChartDataSet] = [LineChartDataSet]()
        let tempDataSet1 = LineChartDataSet(entries: yvaluesp , label: "Left BBQ Temperatures F / Time (s)")
        let tempDataSet2 = LineChartDataSet(entries: yvaluesp , label: "Right BBQ Temperatures F / Time (s)")
        let lowTemp = LineChartDataSet(entries: lowTempValues , label: "Low Temperature Cooking Limit \(cookingParameters.goldLowTempLimit ?? "70")")
        let highTemp = LineChartDataSet(entries: highTempValues , label: "High Temperature Cooking Limit \(cookingParameters.goldHighTempLimit ?? "400")")
        
        allLineChartDataSets.append(tempDataSet1)
        allLineChartDataSets.append(tempDataSet2)
        allLineChartDataSets.append(highTemp)
        allLineChartDataSets.append(lowTemp)

         // Set gradient under curve charateristics
        let gradientColors = [UIColor.systemOrange.cgColor, UIColor.clear.cgColor] as CFArray
        let colorLocations:[CGFloat] = [1.0, 0.0]
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
        
        //Set left temperature curve characteristics
        tempDataSet1.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
        tempDataSet1.drawFilledEnabled = true // Draw the Gradient
        tempDataSet1.mode = .cubicBezier
        tempDataSet1.drawCirclesEnabled = false
        tempDataSet1.valueFont = .boldSystemFont(ofSize: 12)
        tempDataSet1.valueTextColor = .white
        tempDataSet1.lineWidth = 2
        tempDataSet1.setColor(.red)
        tempDataSet1.fillAlpha = 0.8
        tempDataSet1.drawFilledEnabled = true
        tempDataSet1.drawValuesEnabled = false
        tempDataSet1.drawHorizontalHighlightIndicatorEnabled = false
        tempDataSet1.highlightColor = .systemRed
        
        //Set righttemperature curve characteristics
        tempDataSet2.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
        tempDataSet2.drawFilledEnabled = true // Draw the Gradient
        tempDataSet2.mode = .cubicBezier
        tempDataSet2.drawCirclesEnabled = false
        tempDataSet2.valueFont = .boldSystemFont(ofSize: 12)
        tempDataSet2.valueTextColor = .white
        tempDataSet2.lineWidth = 2
        tempDataSet2.setColor(.purple)
        tempDataSet2.fillAlpha = 0.8
        tempDataSet2.drawFilledEnabled = true
        tempDataSet2.drawValuesEnabled = false
        tempDataSet2.drawHorizontalHighlightIndicatorEnabled = false
        tempDataSet2.highlightColor = .systemPurple
        
        //High temp limit line characteristics
        highTemp.lineWidth = 1.0
        highTemp.lineDashLengths = [8]
        highTemp.drawCirclesEnabled = false
        highTemp.setColor(UIColor(red: 1, green: 0, blue: 0, alpha: 0.25))
        highTemp.drawHorizontalHighlightIndicatorEnabled = false
        highTemp.drawVerticalHighlightIndicatorEnabled = false
        
        //Low temp limit line characteristics
        lowTemp.lineWidth = 1.0
        lowTemp.lineDashLengths = [8]
        lowTemp.drawCirclesEnabled = false
        lowTemp.setColor(UIColor(red: 0, green: 1, blue: 1, alpha: 0.2))
        lowTemp.drawHorizontalHighlightIndicatorEnabled = false
        lowTemp.drawVerticalHighlightIndicatorEnabled = false

        //Draw the lines
        let data = LineChartData(dataSets: allLineChartDataSets)
         lineChartView.data = data
        data.setDrawValues(false) // (no labels)
    }
}
