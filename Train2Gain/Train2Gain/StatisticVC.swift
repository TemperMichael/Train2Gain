//
//  StatisticVC.swift
//  Train2Gain
//
//  Created by Michael Temper on 04.10.15.
//  Copyright (c) 2015 Temper. All rights reserved.
//

import UIKit
import CoreData
import Charts

 //TODO - Statistics not used currently since charts framework was updated due to Swift 3 and I didn't have time to adjust my project to the changes
class StatisticVC: UIViewController, ChartViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, IAxisValueFormatter {
    
    var weightUnit = UserDefaults.standard.object(forKey: "weightUnit")! as! String
    var xVals: [String] = []
    var pickerData: [String] = [String]()
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var months = [NSLocalizedString("All", comment: "All"),NSLocalizedString("January", comment: "January"),NSLocalizedString("February", comment: "February"),NSLocalizedString("March", comment: "March"),NSLocalizedString("April", comment: "April"),NSLocalizedString("May", comment: "May"),NSLocalizedString("June", comment: "June"),NSLocalizedString("July", comment: "July"),NSLocalizedString("August", comment: "August"),NSLocalizedString("September", comment: "September"),NSLocalizedString("October", comment: "October"),NSLocalizedString("November", comment: "November"),NSLocalizedString("December", comment: "December")]
    var years: [String] = []
    var exercises: [String] = []
    var sets: [String] = ["1. Set", "2. Set", "3. Set"]
    var appdel = UIApplication.shared.delegate as! AppDelegate
    var doneEx: [DoneExercise] = []
    var selectedMonths: [String] = []
    var selectedExercise = "Exercise"
    var selectedYear = ""
    var selectedSet = ""
    var selectedDoneEx: [DoneExercise] = []
    var setAmount = 0
    var monthDateDict = NSDictionary(dictionary: [NSLocalizedString("Jan", comment: "Jan"):1,NSLocalizedString("Feb", comment: "Feb"):2,NSLocalizedString("Mar", comment: "Mar"):3,NSLocalizedString("Apr", comment: "Apr"):4,NSLocalizedString("May", comment: "May"):5,NSLocalizedString("Jun", comment: "Jun"):6,NSLocalizedString("Jul", comment: "Jul"):7,NSLocalizedString("Aug", comment: "Aug"):8,NSLocalizedString("Sep", comment: "Sep"):9,NSLocalizedString("Oct", comment: "Oct"):10,NSLocalizedString("Nov", comment: "Nov"):11,NSLocalizedString("Dec", comment: "Dec"):12])

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    
    // MARK: IBOutlets & IBActions
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var selectorsBG: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var exerciseButton: UIButton!
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var yearButton: UIButton!
    @IBOutlet weak var pickerBG: UIView!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var pickerTitle: UILabel!
    @IBOutlet weak var selectedValueLabel: UILabel!

    
    override func viewWillDisappear(_ animated: Bool) {
        
        appDelegate.shouldRotate = false
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        appDelegate.shouldRotate = true
 
        // Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: selectorsBG.frame.size)
        selectorsBG.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
        // Get current year
        let date = Date()
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.year], from: date)
        if let year =  components.year {
            for i in (1979...year).reversed() {
                years.append("\(i)")
            }
        }
        let requestDoneEx = NSFetchRequest<NSFetchRequestResult>(entityName: "DoneExercise")
        doneEx = (try! appdel.managedObjectContext?.fetch(requestDoneEx)) as! [DoneExercise]
        
        // Sort array by date
        doneEx.sort(by: { $0.date.compare($1.date as Date) == ComparisonResult.orderedAscending})
        
        // Get exercises
        var alreadyAddedEx: [String] = []
        for i in 0  ..< doneEx.count {
            if !alreadyAddedEx.contains(doneEx[i].name) {
                alreadyAddedEx.append(doneEx[i].name)
                exercises.append(doneEx[i].name)
            }
        }
   
        if exercises.count < 1 {
            exercises.append(NSLocalizedString("No exercises done yet!", comment: "No exercises done yet!"))
        }
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerData = []
        
        //Setup chartview
        chartView.delegate = self
        chartView.chartDescription?.text = ""
        chartView.noDataText = NSLocalizedString("No data available for this setup!", comment: "No data available for this setup!")
        chartView.highlightPerTapEnabled = true
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.drawGridBackgroundEnabled = false
        chartView.pinchZoomEnabled = true
        chartView.backgroundColor = UIColor.white
        chartView.legend.enabled = true
        chartView.legend.font = UIFont(name:"HelveticaNeue-Light", size: 11)!
        chartView.legend.horizontalAlignment = Legend.HorizontalAlignment.left
        chartView.legend.verticalAlignment = Legend.VerticalAlignment.bottom
        chartView.legend.xOffset = -10
        let xAxis = chartView.xAxis;
        xAxis.labelFont =  UIFont(name: "HelveticaNeue-Light", size: 12)!
        xAxis.labelTextColor = UIColor(red: 51 / 255, green: 181 / 255, blue: 229 / 255, alpha: 1)
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.spaceMax = 1
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
        leftAxis.axisMaximum = 100
        leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = false
        let rightAxis = chartView.rightAxis
        rightAxis.labelTextColor = UIColor.gray
        rightAxis.axisMaximum = 9
        rightAxis.drawZeroLineEnabled = false
        rightAxis.axisMinimum = 0
        rightAxis.drawGridLinesEnabled = false
        chartView.rightAxis.enabled = true
        setDataCount()
        
    }

    // MARK: My Methods
    func setDataCount() {
        
        setAmount = 0
        setButton.isEnabled = false
        setButton.setTitleColor(UIColor.lightText, for: UIControlState.disabled)
        xVals = []
        for singleMonth in selectedMonths {
            addEmptyDays(singleMonth)
        }
        var yVals: [ChartDataEntry] = []
        var yValsRight: [ChartDataEntry] = []
        var rightMax = 0.0
        var leftMax = 0.0
        var weight = 0.0
        
        // Get current day,month and year
        var date = Date()
        var calendar = Calendar.current
        var components = (calendar as NSCalendar).components([.year, .month, .day], from: date)
        var month = components.month
        var year = components.year
        var day = components.day
        
        // Loop to show single month or whole year
        for singleMonth in selectedMonths {
            var saveDays: [Int] = []
            for singleDoneEx in selectedDoneEx {
                
                // Get day, month and year
                date = singleDoneEx.date as Date
                calendar = Calendar.current
                components = (calendar as NSCalendar).components([.year, .month,.day], from: date)
                month = components.month
                year = components.year
                day = components.day
                
                // Get maximum for axis
                if singleDoneEx.weight.doubleValue > weight {
                    leftMax = singleDoneEx.weight.doubleValue
                    if weightUnit == "lbs" {
                        leftMax = leftMax * 2.20462262185
                    }
                }
                weight = singleDoneEx.weight.doubleValue
                
                // Only add correct data to chartview
                if year == Int(selectedYear) && month == monthDateDict.value(forKey: singleMonth) as? Int && weight != 0.0 {
                    setAmount = singleDoneEx.sets.intValue
                    
                    //Check unit
                    if weightUnit == "lbs" {
                        weight = weight * 2.20462262185
                    }
                    if singleDoneEx.setCounter.stringValue == selectedSet && !saveDays.contains(day!) {
                        
                        //Fullfill axis when whole year should show up
                        if selectedMonths.count > 1 {
                            
                            
                            if ((year! % 4 == 0) && (year! % 100 != 0)) || (year! % 400 == 0) && monthDateDict.value(forKey: singleMonth) as! Int > 2 {
                                
                                // Leap year
                                day! += 1
                            }
                            
                            // Add days to set data to correct day in correct month
                            switch monthDateDict.value(forKey: singleMonth) as! Int {
                                case 2 :
                                    day! += 31
                                case 3 :
                                    day! += 59
                                case 4 :
                                    day! += 90
                                case 5 :
                                    day! += 120
                                case 6 :
                                    day! += 151
                                case 7 :
                                    day! += 181
                                case 8 :
                                    day! += 212
                                case 9 :
                                    day! += 243
                                case 10 :
                                    day! += 273
                                case 11 :
                                    day! += 304
                                case 12 :
                                    day! += 334
                                default :
                                    print("Month Error")
                            }
                        }
                        
                        yVals.append(ChartDataEntry(x: Double(day! - 1), y: weight))
                        if singleDoneEx.doneReps.doubleValue > rightMax {
                            rightMax = singleDoneEx.doneReps.doubleValue
                        }
                        yValsRight.append(ChartDataEntry(x: Double(day! - 1), y: singleDoneEx.doneReps.doubleValue))
                        saveDays.append(day!)
 
                        // For testing
                        /*
                        for i in 0  ..< 365  {
                            let randNr = Double(arc4random_uniform(200))
                            if randNr > leftMax {
                                leftMax = randNr
                            }
                            let randNrRight =  Double(arc4random_uniform(10))
                            if randNrRight > rightMax {
                                rightMax = randNrRight
                            }
                            yVals.append(ChartDataEntry(x: Double(i), y: randNr)
)
                            yValsRight.append(ChartDataEntry(x: Double(i), y: randNrRight))
                        }
 */
                        
                    }
                }
            }
        }

        if let checkNumb = Int((self.setButton.titleLabel!.text! as NSString).substring(to: 1)) {
            if checkNumb > self.setAmount {
                self.setButton.setTitle(NSLocalizedString("Set", comment: "Set"), for: UIControlState())
                selectedSet = ""
            }
        }
        
        // Put in some space for better view
        leftMax += (leftMax / 100) * 6
        rightMax += rightMax / 10
        if leftMax == 0 {
            leftMax = 1
        }
        if rightMax == 0 {
            rightMax = 1
        }
        chartView.leftAxis.axisMaximum = leftMax
        chartView.rightAxis.axisMaximum = rightMax
        
        // Setup and show chartview
        if xVals != [] && yVals != [] {
            chartView.leftAxis.enabled = true
            chartView.xAxis.enabled = true
            chartView.rightAxis.enabled = true
            selectedExercise = selectedExercise == NSLocalizedString("Exercise", comment: "Exercise") ? "-" : selectedExercise
            let set1 = LineChartDataSet(values: yValsRight, label: NSLocalizedString("Done Reps", comment: "Done Reps"))
            set1.setColor(UIColor.lightGray)
            set1.axisDependency = YAxis.AxisDependency.right
            set1.setCircleColor(UIColor.lightGray)
            set1.lineWidth = 2
            set1.circleRadius = 1.5
            set1.drawCircleHoleEnabled = true
            set1.valueFont = UIFont(name: "HelveticaNeue-Light", size:9)!
            set1.fillAlpha = 255 / 255.0
            let set2 = LineChartDataSet(values: yVals, label: "\(selectedExercise) in \(weightUnit) \(selectedYear)")
            set2.axisDependency = YAxis.AxisDependency.left
            set2.setColor(UIColor(red: 51  / 255, green: 181 / 255, blue: 229 / 255, alpha: 1))
            set2.setCircleColor(UIColor(red: 51 / 255, green: 181 / 255, blue: 229 / 255, alpha: 1))
            set2.lineWidth = 2
            set2.circleRadius = 1.5
            set2.drawCircleHoleEnabled = true
            set2.valueFont = UIFont(name: "HelveticaNeue-Light", size: 9)!
            set2.fillAlpha = 255/255.0
            let dataSets = [set1, set2]
            let data = LineChartData(dataSets: dataSets)
            chartView.data = data
        } else {
            chartView.leftAxis.enabled = false
            chartView.xAxis.enabled = false
            chartView.rightAxis.enabled = false
            selectedValueLabel.isHidden = true
            chartView.data?.clearValues()
        }
        chartView.notifyDataSetChanged()
        if setAmount > 0 {
            setButton.isEnabled = true;
            setButton.setTitleColor(UIColor.white, for: UIControlState())
        }
    }
    
    // Add correct number of days for x-Axis
    func addEmptyDays(_ month: String) {
        
        self.xVals.append("\(month)")
        
        switch month {
        case NSLocalizedString("Jan", comment: "Jan"),NSLocalizedString("Mar", comment: "Mar"),NSLocalizedString("May", comment: "May"),NSLocalizedString("Jul", comment: "Jul"),NSLocalizedString("Aug", comment: "Aug"),NSLocalizedString("Oct", comment: "Oct"),NSLocalizedString("Dec", comment: "Dec") :
            
            for i in 2 ..< 32 {
                self.xVals.append(String(i));
            }
        case NSLocalizedString("Apr", comment: "Apr"),NSLocalizedString("Jun", comment: "Jun"),NSLocalizedString("Sep", comment: "Sep"),NSLocalizedString("Nov", comment: "Nov") :
            
            
            for i in 2 ..< 31 {
                self.xVals.append(String(i));
            }
        case NSLocalizedString("Feb", comment: "Feb") :
            for i in 2  ..< 29 {
                self.xVals.append(String(i))
            }
            if let year = Int(selectedYear) {
                if ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0) {
                    
                    //Leap year
                    self.xVals.append(String(29))
                }
            }
            default:
                print("Error addEmptyDay")
        }
    }
    
    // Fit background image to display size
    func imageResize(_ imageObj: UIImage, sizeChange: CGSize) -> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
        
    }
    
    @IBAction func exerciseCL(_ sender: AnyObject) {
        
        pickerTitle.text = NSLocalizedString("Exercise", comment: "Exercise")
        pickerData = exercises
        setupPickerView()
        
    }
    
    @IBAction func setCL(_ sender: AnyObject) {
        
        let translationSet = NSLocalizedString("Set", comment: "Set")
        pickerTitle.text = translationSet
        sets = []
        for  i in 1...setAmount {
            sets.append("\(i). \(translationSet)")
        }
        pickerData = sets
        setupPickerView()
        
    }
    
    @IBAction func monthCL(_ sender: AnyObject) {
        
        pickerTitle.text = NSLocalizedString("Month", comment: "Month")
        pickerData = months
        setupPickerView()
        
    }
    
    @IBAction func yearCL(_ sender: AnyObject) {
        
        pickerTitle.text = NSLocalizedString("Year", comment: "Year")
        pickerData = years
        setupPickerView()
        
    }

    // MARK: PickerView
    func setupPickerView() {
        
        pickerView.reloadAllComponents()
        blurView.frame = pickerBG.bounds
        blurView.translatesAutoresizingMaskIntoConstraints = false
        if !pickerBG.subviews.contains(blurView) {
            pickerBG.addSubview(blurView)
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: pickerBG, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: pickerBG, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: pickerBG, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: pickerBG, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0))
        }
        pickerBG.alpha = 0
        pickerBG.isHidden = false
        self.view.bringSubview(toFront: pickerBG)
        pickerBG.bringSubview(toFront: pickerView)
        pickerBG.bringSubview(toFront: finishButton)
        pickerBG.bringSubview(toFront: pickerTitle)
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.pickerBG.alpha = 1
            }, completion: { finished in
        })
        
    }
    
    // The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
        
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return pickerData.count
        
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let backVal = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 100))
        backVal.font = UIFont(name: "HelveticaNeue-Thin" , size: 22)
        backVal.textColor = UIColor.white
        backVal.textAlignment = .center
        backVal.text =  pickerData[row]
        return backVal
        
    }
    
    //Animate the hiding of the pickerview, set data and set titles of the buttons
    @IBAction func finishCL(_ sender: AnyObject) {
        
        
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.pickerBG.alpha = 0
            
            
            }, completion: { finished in
                self.pickerBG.isHidden = true
        })
        
        switch self.pickerTitle.text! {
        case NSLocalizedString("Exercise", comment: "Exercise"):
            selectedDoneEx.removeAll()
            if(self.pickerData[self.pickerView.selectedRow(inComponent: 0)] != NSLocalizedString("No exercises done yet!", comment: "No exercises done yet!")){
            self.exerciseButton.setTitle(self.pickerData[self.pickerView.selectedRow(inComponent: 0)], for: UIControlState())
            }
            selectedExercise = self.pickerData[self.pickerView.selectedRow(inComponent: 0)]
            
            for i in 0 ..< doneEx.count {
                if(doneEx[i].name == selectedExercise){
                    selectedDoneEx.append(doneEx[i])
                }
            }
            
            
        case NSLocalizedString("Month", comment: "Month"):
            let selectedText = self.pickerData[self.pickerView.selectedRow(inComponent: 0)]
            self.monthButton.setTitle(selectedText, for: UIControlState())
            
            
            selectedMonths.removeAll()
            
            if(selectedText == NSLocalizedString("All", comment: "All")){
                selectedMonths = [NSLocalizedString("Jan", comment: "Jan"),NSLocalizedString("Feb", comment: "Feb"),NSLocalizedString("Mar", comment: "Mar"),NSLocalizedString("Apr", comment: "Apr"),NSLocalizedString("May", comment: "May"),NSLocalizedString("Jun", comment: "Jun"),NSLocalizedString("Jul", comment: "Jul"),NSLocalizedString("Aug", comment: "Aug"),NSLocalizedString("Sep", comment: "Sep"),NSLocalizedString("Oct", comment: "Oct"),NSLocalizedString("Nov", comment: "Nov"),NSLocalizedString("Dec", comment: "Dec")]
            }else{
                selectedMonths.append((selectedText as NSString).substring(to: 3))
            }
            
        case NSLocalizedString("Year", comment: "Year"):
            self.yearButton.setTitle(self.pickerData[self.pickerView.selectedRow(inComponent: 0)], for: UIControlState())
            
            selectedYear = self.pickerData[self.pickerView.selectedRow(inComponent: 0)]
            
        case NSLocalizedString("Set", comment: "Set"):
            
            self.setButton.setTitle(self.pickerData[self.pickerView.selectedRow(inComponent: 0)], for: UIControlState())
            
            selectedSet = (self.pickerData[self.pickerView.selectedRow(inComponent: 0)] as NSString).substring(to: 1)
            
        default:
            print("Error PickerChoose")
            
        }
        self.setDataCount()
        
    }
    
    @IBAction func snapshotCL(_ sender: AnyObject) {
        
        let informUserSnapshot = UIAlertController(title: NSLocalizedString("Snapshot", comment: "Snapshot"), message: NSLocalizedString("Do you want to take a snapshot of the chart?", comment: "Do you want to take a snapshot of the chart?"), preferredStyle: UIAlertControllerStyle.alert)
        informUserSnapshot.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.default, handler: nil))
        informUserSnapshot.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            UIImageWriteToSavedPhotosAlbum(self.chartView.getChartImage(transparent: false)!, nil, nil, nil)
        }))
        
        present(informUserSnapshot, animated: true, completion: nil)
        
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
        selectedValueLabel.isHidden = false
        if highlight.dataSetIndex == 1 {
            selectedValueLabel.textColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
            selectedValueLabel.text = NSString(format: "Val.:%.2f \(weightUnit)" as NSString,entry.x ) as String
        } else {
            selectedValueLabel.textColor = UIColor.gray
            let translationReps = NSLocalizedString("reps", comment: "reps")
            selectedValueLabel.text = "Val.:\(entry.x) \(translationReps)"
        }
        
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        selectedValueLabel.isHidden = true
    }
    
    func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String {
        
        return ""
        
    }


}
