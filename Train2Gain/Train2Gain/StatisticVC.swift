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



class StatisticVC: UIViewController, ChartViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
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
    
    
    var weightUnit: String! = NSUserDefaults.standardUserDefaults().objectForKey("weightUnit")! as! String
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
    
    var xVals:[String] = []
    
    var pickerData: [String] = [String]()
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var months = ["All","January","February","March","April","May","June","July","August","September","October","November","December"]
    
    var years:[String] = []
    
    var exercises:[String] = []
    
    var sets:[String] = ["1. Set","2. Set","3. Set"]
    
    var appdel = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var doneEx:[DoneExercise] = []
    
    var selectedMonths:[String] = []
    
    var selectedExercise = "Exercise"
    
    var selectedYear = ""
    
    var selectedSet = ""
    
    var selectedDoneEx:[DoneExercise] = []
    
    var setAmount = 0
    
    var monthDateDict = NSDictionary(dictionary: ["Jan":1,"Feb":2,"Mar":3,"Apr":4,"May":5,"Jun":6,"Jul":7,"Aug":8,"Sep":9,"Oct":10,"Nov":11,"Dec":12])
    
    
    override func viewWillDisappear(animated: Bool) {
        appDelegate.shouldRotate = false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.shouldRotate = true
        
        //Set background
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: selectorsBG.frame.size)
        selectorsBG.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
        //Get current year
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year], fromDate: date)
        
        let year =  components.year
        
        for(var i = year ; i > 1979; i--){
            years.append("\(i)")
        }
        
        
        let  requestDoneEx = NSFetchRequest(entityName: "DoneExercise")
        doneEx = (try! appdel.managedObjectContext?.executeFetchRequest(requestDoneEx))  as! [DoneExercise]
        
        //Sort array by date
        doneEx.sortInPlace({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        
        //Get exercises
        var alreadyAddedEx:[String] = []
        for(var i = 0; i < doneEx.count; i++){
            if(!alreadyAddedEx.contains(doneEx[i].name)){
                alreadyAddedEx.append(doneEx[i].name)
                exercises.append(doneEx[i].name)
            }
        }
        
        if(exercises.count < 1){
            exercises.append("No exercises done yet!")
            
        }
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        
        
        pickerData = []
        
        //Setup chartview
        
        chartView.delegate = self;
        
        chartView.descriptionText = ""
        chartView.noDataTextDescription = "No data available for this setup!"
        
        chartView.highlightEnabled = true
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.drawGridBackgroundEnabled = false
        chartView.pinchZoomEnabled = true
        
        chartView.backgroundColor = UIColor.whiteColor()
        
        
        chartView.legend.enabled = true
        chartView.legend.font = UIFont(name:"HelveticaNeue-Light", size:11)!
        chartView.legend.position = ChartLegend.ChartLegendPosition.BelowChartLeft
        
        chartView.legend.xOffset = -10
        
        let xAxis = chartView.xAxis;
        xAxis.labelFont =  UIFont(name:"HelveticaNeue-Light", size:12)!
        xAxis.labelTextColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.spaceBetweenLabels = 1
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
        leftAxis.customAxisMax = 100
        leftAxis.customAxisMin = 0
        leftAxis.drawGridLinesEnabled = false
        
        
        let rightAxis = chartView.rightAxis
        rightAxis.labelTextColor = UIColor.grayColor()
        rightAxis.customAxisMax = 9
        rightAxis.startAtZeroEnabled = false
        rightAxis.customAxisMin = 0
        rightAxis.drawGridLinesEnabled = false
        
        
        chartView.rightAxis.enabled = true
        
        setDataCount()
    }
    
    
    func setDataCount(){
        
        setAmount = 0
        
        setButton.enabled = false
        setButton.setTitleColor(UIColor.lightTextColor(), forState: UIControlState.Disabled)
        
        
        xVals = []
        
        for singleMonth in selectedMonths{
            addEmptyDays(singleMonth)
        }
        
        var yVals:[ChartDataEntry] = []
        var yValsRight:[ChartDataEntry] = []
        var rightMax = 0.0
        var leftMax = 0.0
        
        var weight = 0.0
        
        //Get current day,month and year
        var date = NSDate()
        var calendar = NSCalendar.currentCalendar()
        var components = calendar.components([.Year, .Month,.Day], fromDate: date)
        var month = components.month
        var year = components.year
        var day = components.day
        
        //Loop to show single month or whole year
        for singleMonth in selectedMonths{
            
            var saveDays:[Int] = []
            for singleDoneEx in selectedDoneEx{
                
                //Get day, month and year
                date = singleDoneEx.date
                calendar = NSCalendar.currentCalendar()
                components = calendar.components([.Year, .Month,.Day], fromDate: date)
                month = components.month
                year = components.year
                day = components.day
                
                //Get maximum for axis
                if(singleDoneEx.weight.doubleValue > weight){
                    leftMax = singleDoneEx.weight.doubleValue
                    if(weightUnit == "lbs"){
                        leftMax = leftMax * 2.20462262185
                    }
                    
                }
                
                weight = singleDoneEx.weight.doubleValue
                
                //Only add correct data to chartview
                if(year == Int(selectedYear) && month == monthDateDict.valueForKey(singleMonth) as! Int && weight != 0.0 ){
                    
                    setAmount = singleDoneEx.sets.integerValue
                    
                    //Check unit
                    if(weightUnit == "lbs"){
                        weight = weight * 2.20462262185
                    }
                    
                    if(singleDoneEx.setCounter.stringValue == selectedSet && !saveDays.contains(day)){
                        
                        //Fullfill axis when whole year should show up
                        if(selectedMonths.count > 1){
                            
                            
                            if (((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0) && monthDateDict.valueForKey(singleMonth) as! Int > 2){
                                //leap year
                                
                                day += 1
                            }
                            
                            //Add days to set data to correct day in correct month
                            switch monthDateDict.valueForKey(singleMonth) as! Int{
                            case 2:
                                day += 31
                            case 3:
                                day += 59
                            case 4:
                                day += 90
                            case 5:
                                day += 120
                            case 6:
                                day += 151
                            case 7:
                                day += 181
                            case 8:
                                day += 212
                            case 9:
                                day += 243
                            case 10:
                                day += 273
                            case 11:
                                day += 304
                            case 12:
                                day += 334
                            default:
                                print("Month Error")
                            }
                        }
                        
                        
                        yVals.append(ChartDataEntry(value: weight, xIndex: day - 1))
                        if(singleDoneEx.doneReps.doubleValue > rightMax){
                            rightMax = singleDoneEx.doneReps.doubleValue
                        }
                        
                        yValsRight.append(ChartDataEntry(value: singleDoneEx.doneReps.doubleValue, xIndex: day - 1))
                        saveDays.append(day)
                        
                        //For testing
                        /*
                        for(var i = 0; i < 365 ;i++){
                        let randNr = Double(arc4random_uniform(200))
                        
                        if(randNr > leftMax){
                        leftMax = randNr
                        }
                        let randNrRight =  Double(arc4random_uniform(10))
                        if(randNrRight > rightMax){
                        rightMax = randNrRight
                        }
                        yVals.append(ChartDataEntry(value: randNr, xIndex: i))
                        
                        
                        yValsRight.append(ChartDataEntry(value: randNrRight, xIndex: i))
                        }
                        */
                        
                        
                    }
                    
                }
            }
        }
        
        
        if let checkNumb = Int((self.setButton.titleLabel!.text! as NSString).substringToIndex(1)){
            
            if(checkNumb > self.setAmount){
                self.setButton.setTitle("Set", forState: UIControlState.Normal)
                selectedSet = ""
            }
        }
        
        //Put in some space for better view
        leftMax += (leftMax/100) * 6
        rightMax += rightMax/10
        
        
        if(leftMax == 0){
            leftMax = 1
        }
        if(rightMax == 0){
            rightMax = 1
        }
        
        chartView.leftAxis.customAxisMax = leftMax
        chartView.rightAxis.customAxisMax = rightMax
        
        
        //Setup and show chartview
        if(xVals != [] && yVals != []){
            chartView.leftAxis.enabled = true
            chartView.xAxis.enabled = true
            chartView.rightAxis.enabled = true
            selectedExercise = selectedExercise == "Exercise" ? "-" : selectedExercise
            
            let set1 = LineChartDataSet(yVals: yValsRight, label: "Done Reps")
            set1.setColor(UIColor.lightGrayColor())
            set1.axisDependency = ChartYAxis.AxisDependency.Right
            set1.setCircleColor(UIColor.lightGrayColor())
            set1.lineWidth = 2
            set1.circleRadius = 1.5
            set1.drawCircleHoleEnabled = true
            set1.valueFont = UIFont(name:"HelveticaNeue-Light", size:9)!
            set1.fillAlpha = 255/255.0;
            
            let set2 = LineChartDataSet(yVals: yVals, label: "\(selectedExercise) in \(weightUnit) \(selectedYear)")
            set2.axisDependency = ChartYAxis.AxisDependency.Left
            set2.setColor(UIColor(red:51/255, green:181/255, blue:229/255, alpha:1))
            set2.setCircleColor(UIColor(red:51/255, green:181/255, blue:229/255, alpha:1))
            set2.lineWidth = 2
            set2.circleRadius = 1.5
            set2.drawCircleHoleEnabled = true
            set2.valueFont = UIFont(name:"HelveticaNeue-Light", size:9)!
            set2.fillAlpha = 255/255.0;
            
            
            
            let dataSets = [set1,set2]
            
            let data = LineChartData(xVals: xVals, dataSets: dataSets)
            
            chartView.data = data;
        }else{
            chartView.leftAxis.enabled = false
            chartView.xAxis.enabled = false
            chartView.rightAxis.enabled = false
            selectedValueLabel.hidden = true
            chartView.data?.clearValues()
        }
        chartView.notifyDataSetChanged()
        
        if(setAmount > 0){
            setButton.enabled = true;
            setButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        }
    }
    
    
    //Add correct number of days for x-Axis
    func addEmptyDays(month:String){
        
        self.xVals.append("\(month)")
        
        switch(month){
        case "Jan","Mar","May","Jul","Aug","Oct","Dec":
            
            for(var i = 2; i < 32; i++){
                self.xVals.append(String(i));
            }
        case "Apr","Jun","Sep","Nov":
            
            
            for(var i = 2; i < 31; i++){
                self.xVals.append(String(i));
            }
        case "Feb":
            
            
            for(var i = 2; i < 29; i++){
                self.xVals.append(String(i));
            }
            
            if let year = Int(selectedYear){
                if (((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)){
                    //leap year
                    
                    self.xVals.append(String(29))
                }
            }
            
            
        default:
            print("error addEmptyDay")
        }
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Fit background image to display size
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    
    
    @IBAction func exerciseCL(sender: AnyObject) {
        
        pickerTitle.text = "Exercise"
        pickerData = exercises
        setupPickerView()
        
    }
    
    @IBAction func setCL(sender: AnyObject) {
        
        pickerTitle.text = "Set"
        sets = []
        for(var i = 1; i <= setAmount; i++){
            sets.append("\(i). Set")
        }
        pickerData = sets
        setupPickerView()
        
        
    }
    
    
    @IBAction func monthCL(sender: AnyObject) {
        pickerTitle.text = "Month"
        pickerData = months
        setupPickerView()
    }
    
    
    @IBAction func yearCL(sender: AnyObject) {
        pickerTitle.text = "Year"
        pickerData = years
        setupPickerView()
    }
    
    
    
    func setupPickerView(){
        pickerView.reloadAllComponents()
        
        blurView.frame = pickerBG.bounds
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        if( !pickerBG.subviews.contains(blurView)){
            pickerBG.addSubview(blurView)
            
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: pickerBG, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0.0))
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: pickerBG, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0.0))
            
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: pickerBG, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0.0))
            
            pickerBG.addConstraint(NSLayoutConstraint(item: blurView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: pickerBG, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0.0))
        }
        
        pickerBG.alpha = 0
        pickerBG.hidden = false
        self.view.bringSubviewToFront(pickerBG)
        pickerBG.bringSubviewToFront(pickerView)
        pickerBG.bringSubviewToFront(finishButton)
        pickerBG.bringSubviewToFront(pickerTitle)
        
        
        
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.pickerBG.alpha = 1
            
            
            }, completion: { finished in
                
        })
        
    }
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
        
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        
        let backVal = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, 100))
        
        backVal.font = UIFont(name: "HelveticaNeue-Thin" , size: 22)
        backVal.textColor = UIColor.whiteColor()
        backVal.textAlignment = .Center
        backVal.text =  pickerData[row]
        
        return backVal
    }
    
    
    //Animate the hiding of the pickerview, set data and set titles of the buttons
    @IBAction func finishCL(sender: AnyObject) {
        
        
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.pickerBG.alpha = 0
            
            
            }, completion: { finished in
                self.pickerBG.hidden = true
        })
        
        switch(self.pickerTitle.text!){
        case "Exercise":
            selectedDoneEx.removeAll()
            
            self.exerciseButton.setTitle(self.pickerData[self.pickerView.selectedRowInComponent(0)], forState: UIControlState.Normal)
            selectedExercise = self.pickerData[self.pickerView.selectedRowInComponent(0)]
            
            for(var i = 0; i < doneEx.count ; i++){
                if(doneEx[i].name == selectedExercise){
                    selectedDoneEx.append(doneEx[i])
                }
            }
            
            
        case "Month":
            let selectedText = self.pickerData[self.pickerView.selectedRowInComponent(0)]
            self.monthButton.setTitle(selectedText, forState: UIControlState.Normal)
            
            
            selectedMonths.removeAll()
            
            if(selectedText == "All"){
                selectedMonths = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
            }else{
                selectedMonths.append((selectedText as NSString).substringToIndex(3))
            }
            
        case "Year":
            self.yearButton.setTitle(self.pickerData[self.pickerView.selectedRowInComponent(0)], forState: UIControlState.Normal)
            
            selectedYear = self.pickerData[self.pickerView.selectedRowInComponent(0)]
            
        case "Set":
            
            self.setButton.setTitle(self.pickerData[self.pickerView.selectedRowInComponent(0)], forState: UIControlState.Normal)
            
            selectedSet = (self.pickerData[self.pickerView.selectedRowInComponent(0)] as NSString).substringToIndex(1)
            
        default:
            print("Error PickerChoose")
            
        }
        self.setDataCount()
        
    }
    
    
    
    @IBAction func snapshotCL(sender: AnyObject) {
        let informUserSnapshot = UIAlertController(title: "Snapshot", message: "Do you want to take a snapshot of the chart?", preferredStyle: UIAlertControllerStyle.Alert)
        informUserSnapshot.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        informUserSnapshot.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            self.chartView.saveToCameraRoll()
            
            
        }))
        
        presentViewController(informUserSnapshot, animated: true, completion: nil)
        
        
    }
    
    //Highlight selected value 
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        selectedValueLabel.hidden = false
        if(dataSetIndex == 1){
            selectedValueLabel.textColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
            selectedValueLabel.text = NSString(format: "Val.:%.2f \(weightUnit)",entry.value ) as String
        }else{
            selectedValueLabel.textColor = UIColor.grayColor()
            selectedValueLabel.text = "Val.:\(entry.value) reps"
        }
    }
    
    func chartValueNothingSelected(chartView: ChartViewBase) {
        selectedValueLabel.hidden = true
    }
    
    
    
}
