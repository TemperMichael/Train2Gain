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
    
    @IBOutlet weak var pickerTitle: UILabel!
    
    
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
    
    var xVals:[String] = []
    
    var pickerData: [String] = [String]()
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var months = ["All","January","February","March","April","May","Juny","July","August","September","October","November","December"]
    
    var years:[String] = []
    
    var exercises:[String] = []
    
    var appdel = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var doneEx:[DoneExercise] = []
    
    var selectedMonths:[String] = []
    
    var selectedExercise = "Exercise"
    
    var selectedYear = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.shouldRotate = true
        
        var backgroundIMG = UIImage(named: "Background2.png")
        backgroundIMG = imageResize(backgroundIMG!, sizeChange: selectorsBG.frame.size)
        selectorsBG.backgroundColor = UIColor(patternImage: backgroundIMG!)
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(NSCalendarUnit.NSYearCalendarUnit, fromDate: date)
        
        let year =  components.year
        
        for(var i = year ; i > 1979; i--){
            years.append("\(i)")
        }
        
        
        let  requestDoneEx = NSFetchRequest(entityName: "DoneExercise")
        doneEx = (try! appdel.managedObjectContext?.executeFetchRequest(requestDoneEx))  as! [DoneExercise]
        
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
        
       
        
         pickerData = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6","Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6"]

        chartView.delegate = self;
        
        chartView.descriptionText = ""
        chartView.noDataTextDescription = "You need to provide data for the chart."
    
        chartView.highlightEnabled = true
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.drawGridBackgroundEnabled = false
        chartView.pinchZoomEnabled = true
        
        chartView.backgroundColor = UIColor.whiteColor()
        
        
        chartView.legend.enabled = true
        chartView.legend.font = UIFont(name:"HelveticaNeue-Light", size:11)!
        chartView.legend.textColor = UIColor.whiteColor()
        chartView.legend.position = ChartLegend.ChartLegendPosition.BelowChartLeft
        chartView.legend.textColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
        
       
        let xAxis = chartView.xAxis;
        xAxis.labelFont =  UIFont(name:"HelveticaNeue-Light", size:12)!
        xAxis.labelTextColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.spaceBetweenLabels = 1
    
       
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
        leftAxis.customAxisMax = 999
        leftAxis.customAxisMin = 0
        leftAxis.drawGridLinesEnabled = false
      /*
        
        let rightAxis = chartView.rightAxis
        rightAxis.labelTextColor = UIColor(red:51/255, green:181/255, blue:229/255, alpha:1)
     //   rightAxis.customAxisMax = 100
        rightAxis.startAtZeroEnabled = false
      //  rightAxis.customAxisMin = 100
        rightAxis.drawGridLinesEnabled = false
        */
        
        chartView.rightAxis.enabled = false
        
        
        setDataCount()
      //  chartView.animate(xAxisDuration: )

        // Do any additional setup after loading the view.
    }

    
    func setDataCount(){
        
        xVals = []
    
        for singleMonth in selectedMonths{
            addEmptyDays(singleMonth)
        }
        
        
        var yVals:[ChartDataEntry] = []
    
        
        while(yVals.count < 365){
            yVals.append(ChartDataEntry(value:Double( (arc4random() % 900)), xIndex:yVals.count))
        }
        
        if(xVals != [] && yVals != []){
        selectedExercise = selectedExercise == "Exercise" ? "-" : selectedExercise
        
        let set1 = LineChartDataSet(yVals: yVals, label: "\(selectedExercise) \(selectedYear)")
    
  //  set1.lineDashLengths = [100, 50]
   // set1.highlightLineDashLengths = [100, 50]
    set1.setColor(UIColor(red:51/255, green:181/255, blue:229/255, alpha:1))
    set1.setCircleColor(UIColor(red:51/255, green:181/255, blue:229/255, alpha:1))
    set1.lineWidth = 2
    set1.circleRadius = 2
    set1.drawCircleHoleEnabled = true
    set1.valueFont = UIFont(name:"HelveticaNeue-Light", size:9)!
    set1.fillAlpha = 255/255.0;
    set1.fillColor = UIColor.greenColor()
        
    let dataSets = [set1]
    
    let data = LineChartData(xVals: xVals, dataSets: dataSets)
    
    chartView.data = data;
        }
    }
    
    
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
            
        default:
            print("error addEmptyDay")
        }
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        // 3
        
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
                // Fill the label text here
                backVal.text =  pickerData[row]
            
        
       return backVal
    }
    
    
    @IBAction func finishCL(sender: AnyObject) {
        
        
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.pickerBG.alpha = 0
            
            
            }, completion: { finished in
                self.pickerBG.hidden = true
                        })

        switch(self.pickerTitle.text!){
        case "Exercise":
            
            self.exerciseButton.setTitle(self.pickerData[self.pickerView.selectedRowInComponent(0)], forState: UIControlState.Normal)
            selectedExercise = self.pickerData[self.pickerView.selectedRowInComponent(0)]
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


}
