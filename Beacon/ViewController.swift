//
//  ViewController.swift
//  HAL
//
//  Created by Thibault Imbert on 7/12/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import UIKit
import HealthKit
import UserNotifications
import Charts
import CoreData
import Reachability

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate
{
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var current: UILabel!
    @IBOutlet weak var difference: UILabel!
    @IBOutlet weak var news: UILabel!
    @IBOutlet weak var myChart: LineChartView!
    @IBOutlet weak var range: UIPickerView!
    
    public var quotes: [String] = ["Diabetics are naturally sweet.",
                                   "You are Type-One-Der-Ful.",
                                   "Watch out, I am a diabadass.",
                                    "Fall asleep and your pancreas is mine!",
                                    "Remember, someone is thinking about you today.",
                                    "I am not ill, my pancreas is just lazy."]
    
    public var hkBridge: HealthKitBridge!
    public var remoteBridge: DexcomBridge!
    private var chartManager: ChartManager!
    private var pickerDataSource = ["24 hours", "48 hours", "3 days", "7 days"];
    private var setupBg: Background!
    private var updateTimer: Timer?
    private var refreshTimer: Timer?
    private var recoverTimer: Timer?
    private var firstTime:DarwinBoolean = true
    private var results: [GlucoseSample]!
    private var bodyFont: UIFont!
    private var quoteFont: UIFont!
    private var quoteText: UILabel!
    private var managedObjectContext: NSManagedObjectContext!
    private var keyChain: KeychainSwift!
    private var size: Float = 0
    private var generator: UIImpactFeedbackGenerator!
    private var gestureRecognizer: UIGestureRecognizer!
    private var reachability: Reachability!
    private var toggle: DarwinBoolean = false
    private var summaryItems: [Summary]! = []
    private var a1cSummary: StatSummary!
    private var bpmSummary: StatSummary!
    private var sdSummary: StatSummary!
    private var avgSummary: StatSummary!
    private var accelSummary: StatSummary!
    private var percentageNormalSummary: StatSummary!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        /*
        let firstNotification = DLNotification(identifier: "firstNotification", alertTitle: "Notification Alert", alertBody: "You have successfully created a notification", date: Date(), repeats: .Minute)
        
        // You can now change the repeat interval here
        firstNotification.repeatInterval = .Yearly
        
        // You can add a launch image name
        firstNotification.launchImageName = "Hello.png"
        
        let scheduler = DLNotificationScheduler()
        scheduler.scheduleNotification(notification: firstNotification)
 */
        
        activityIndicator.startAnimating()
        
        range.dataSource = self;
        range.delegate = self;
        
        // load credentials
        keyChain = KeychainSwift.shared()
        
        // detect connection changes (wifi, cellular, no network)
        reachability = Reachability()!
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: Notification.Name.reachabilityChanged,object: reachability)
        do{
            try reachability.startNotifier()
        }catch {
            print("Could not start reachability notifier")
        }
        
        // handling background and foreground states
        NotificationCenter.default.addObserver(self, selector: #selector(self.resume), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.pause), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        // initialize coredata
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        // disable dimming
        UIApplication.shared.isIdleTimerDisabled = true
        
        // reset UI
        myChart.noDataText = ""
        
        // setup background
        setupBg = Background (parent: self)
        
        quoteText = UILabel()
        quoteText.font = quoteFont
        quoteText.text = getRandomQuote()
        quoteText.center = CGPoint(x: self.view.frame.size.height/2, y: self.view.frame.size.width/2)
        self.view.addSubview(quoteText)
        
        // font setup
        let detailsFont = UIFont(name: ".SFUIText-Semibold", size :12)
        bodyFont = UIFont(name: ".SFUIText-Semibold", size :11)
        quoteFont = UIFont(name: ".SFUIText-Semibold", size :18)
        let headerFont = UIFont(name: ".SFUIText-Semibold", size :26)
        let newsFont = UIFont(name: ".SF-Pro-Display-Thin", size :18)
        
        //detailsL.font = detailsFont
        current.font = headerFont
        difference.font = newsFont
        
        // centers launch quote label
        //news.center = CGPoint(x: view.frame.width/2,y: view.frame.height/2);
        news.text = getRandomQuote()
        
        // charts UI
        chartManager = ChartManager(parent: self, lineChart: myChart)
        let selectionHandler = EventHandler(function: onSelection)
        chartManager.addEventListener(type: EventType.selection, handler: selectionHandler)
        
        // initialize the Dexcom bridge
        remoteBridge = DexcomBridge.shared()
        let glucoseValuesHandler = EventHandler(function: self.onGlucoseValues)
        let refreshedTokenHandler = EventHandler(function: self.onTokenRefreshed)
        let onLoggedInHandler = EventHandler (function: self.onLoggedIn)
        let glucoseIOHandler = EventHandler (function: self.glucoseIOFailed)
        let hkAuthorizedHandler = EventHandler (function: self.onHKAuthorization)
        let hkHeartRateHandler = EventHandler (function: self.onHKHeartRate)
        
        hkBridge = HealthKitBridge.shared()
        hkBridge.getHealthKitPermission()
        hkBridge.addEventListener(type: EventType.authorized, handler: hkAuthorizedHandler)
        hkBridge.addEventListener(type: EventType.heartRate, handler: hkHeartRateHandler)
        
        // wait for Dexcom data
        remoteBridge.addEventListener(type: .glucoseValues, handler: glucoseValuesHandler)
        remoteBridge.addEventListener(type: .refreshToken, handler: refreshedTokenHandler)
        remoteBridge.addEventListener(type: .glucoseIOError, handler: glucoseIOHandler)
        
        // init summary stats
        a1cSummary = StatSummary()
        a1cSummary.center = CGPoint(x: 70,y: 245)
        self.view.addSubview(a1cSummary)
        bpmSummary = StatSummary()
        bpmSummary.center = CGPoint(x: 157,y: 245)
        self.view.addSubview(bpmSummary)
        sdSummary = StatSummary()
        sdSummary.center = CGPoint(x: 70,y: 285)
        self.view.addSubview(sdSummary)
        avgSummary = StatSummary()
        avgSummary.center = CGPoint(x: 157,y: 285)
        self.view.addSubview(avgSummary)
        accelSummary = StatSummary()
        accelSummary.center = CGPoint(x: 244,y: 245)
        self.view.addSubview(accelSummary)
        percentageNormalSummary = StatSummary()
        percentageNormalSummary.center = CGPoint(x: 244,y: 285)
        self.view.addSubview(percentageNormalSummary)
        
        let imageView  = UIImageView(frame: CGRect(x: 20, y: 40, width: 20, height: 17))
        imageView.isUserInteractionEnabled = true
        let image = UIImage(named: "Menu")!
        imageView.image = image
        self.view.addSubview(imageView)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleMenu(recognizer:)))
        imageView.addGestureRecognizer(tapRecognizer)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return summaryItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
        let summary: Summary = summaryItems[indexPath.row]
        cell.displayContent(title: summary.content)
        return cell
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        // use the row to get the selected row from the picker view
        // using the row extract the value from your datasource (array[row])
        let selectedValue = pickerDataSource[pickerView.selectedRow(inComponent: 0)]
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1
        if (selectedValue == "24 hours") {
            remoteBridge.getGlucoseValues(token: DexcomBridge.TOKEN, startDate: "2017-06-19T07:00:00", endDate: "2017-06-19T19:00:00")
        } else if (selectedValue == "48 hours") {
            remoteBridge.getGlucoseValues(token: DexcomBridge.TOKEN, startDate: "2017-06-18T08:00:00", endDate: "2017-06-20T08:00:00")
        } else if (selectedValue == "3 days") {
            remoteBridge.getGlucoseValues(token: DexcomBridge.TOKEN, startDate: "2017-06-17T08:00:00", endDate: "2017-06-20T08:00:00")
        } else if (selectedValue == "7 days") {
            remoteBridge.getGlucoseValues(token: DexcomBridge.TOKEN, startDate: "2017-06-13T08:00:00", endDate: "2017-06-20T08:00:00")
        }
        
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.white
        pickerLabel.text = selectedValue
        pickerLabel.font = UIFont(name: ".SFUIText-Semibold", size :18) // In this use your custom font
        pickerLabel.textAlignment = NSTextAlignment.center
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let titleData = pickerDataSource[row]
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:bodyFont,NSForegroundColorAttributeName:UIColor.white])
        return myTitle
    }
    
    func toggleMenu(recognizer: UITapGestureRecognizer) {
        DispatchQueue.main.async(execute:
        {
            // Now the animation has finished and our image is displayed on screen
            self.performSegue(withIdentifier: "Settings", sender: self)
        })
    }
    
    @IBAction func unwindToMain(sender: UIStoryboardSegue) {}
    
    @objc private func reachabilityChanged(note: Notification)
    {
        let reachability = note.object as! Reachability
        if !reachability.isReachable {
            //self.pause()
            //news.text = "Uh, oh. You seem to have lost network, waiting on network availability..."
            //current.text = "---\n---"
            //difference.text = ""
        } else {
            self.resume()
            //news.text = "Your heart rate has been steady for the past 48 hours, maybe time for a run?"
        }
    }
    
    public func onGlucoseValues(event: Event)
    {
        summaryItems.removeAll()
        activityIndicator.stopAnimating()
        activityIndicator.alpha = 0
        
        // updates background based on current time
        setupBg.updateBackground()
        
        // reposition encouragement label
        //news.center = CGPoint(x: view.frame.width/2,y: -173+view.frame.height/2);
        news.text = "Your heart rate has been steady for the past 48 hours, maybe time for a run?"
        
        // clean past data (debug)
        (UIApplication.shared.delegate as! AppDelegate).deleteSamplesData()
        
        // reference the result (Array of BGSample)
        results = remoteBridge.bloodSamples
        
        /*
        // initiate daily samples records
        let dailySample = DailySamples(context: managedObjectContext)
        dailySample.createdAt = Date() as NSDate
        dailySample.name = "24 hour samples"
        
        var samples: [Any] = []
        
        // fill the results
        for result in results {
            let bgSample = GSample(context: managedObjectContext)
            bgSample.time = result.time
            bgSample.value = Int32(result.value)
            bgSample.trend = result.trend
            samples.append(bgSample)
        }
        
        let data = NSSet(array: samples)
        dailySample.samples = data
        
        do {
            try self.managedObjectContext.save()
            
        } catch { print ("error while saving data") }
        
        let samplesRequest: NSFetchRequest<NSFetchRequestResult> = DailySamples.fetchRequest()
        
        do{
            let samples: [DailySamples] = try managedObjectContext.fetch(samplesRequest) as! [DailySamples]
            let records = samples[0].samples
        } catch { print ("error loading data") }
 */
        
        let sampleDate:String = results[0].time
        current.text = sampleDate + "\n" + String (describing: results[0].value) + " mg/DL " + results[0].trend
        
        // details UI
        var infosLeft: String = ""
        
        let average: Double = round(Math.computeAverage(samples: results))
        let averageHrate: Double = ceil(Math.computeAverage(samples: hkBridge.heartRates))
        let maxSD: Double = average / 3
        
        // update charts UI
        chartManager.setData(data: results, average: average)
        self.onSelection(event: nil)
        
        // display results
        infosLeft +=  "24-hour report"
        let a1C:Summary = Summary (content: String(round(Math.A1C(samples: results))))
        let heartBpm: Summary = Summary (content: String(round(averageHrate)))
        let sd:Summary = Summary(content: String (round(Math.computeSD(samples: results))))
        let avg: Summary = Summary (content: String (average))
        let acceleration: Summary = Summary (content: String (chartManager.curvature.roundTo(places: 2)))
        
        news.alpha = 1
        
        // calculate distribution
        let highs: [GlucoseSample] = Math.computeHighBG(samples: results)
        let lows: [GlucoseSample] = Math.computeLowBG(samples: results)
        let normal: [GlucoseSample] = Math.computeNormalRangeBG(samples: results)
        
        let averageHigh: Double = ceil(Math.computeAverage(samples: highs))
        let averageNormal: Double = ceil(Math.computeAverage(samples: normal))
        let averageLow: Double = ceil(Math.computeAverage(samples: lows))
        
        let avgHigh:Summary = Summary(content: "Avg/High: " + String(describing: averageHigh.roundTo(places: 2)))
        let avgNormal: Summary = Summary (content: "mg/dL \nAvg/Normal: " + String(describing: averageNormal.roundTo(places: 2)) + " mg/dL")
        let avgLow: Summary = Summary (content: "Avg/Low: " + String(describing: averageLow.roundTo(places: 2)) + " mg/dL")
        
        // percentages
        let highsPercentage : Double = Double (highs.count) / Double (results.count)
        let normalRangePercentage : Double = Double (normal.count) / Double (results.count)
        let lowsPercentage : Double = Double (lows.count) / Double(results.count)
        
        let highRatio: Double = (24.0 * highsPercentage).roundTo(places: 2)
        let highsSum:Summary = Summary (content: "Highs: " + String ( highsPercentage.roundTo(places: 2) * 100 ) + "%")
        let normalSum: Summary = Summary (content: String ( normalRangePercentage.roundTo(places: 2) * 100 ))
        let low: Summary = Summary (content: "Lows: " + String ( lowsPercentage.roundTo(places: 2) * 100 ) + "%")
       // infosRight += " "+String(describing: highRatio) + " hours total"
        let normalRatio: Double = (24.0 * normalRangePercentage).roundTo(places: 2)
        //infosLeft += "\nNormal: " + String ( normalRangePercentage.roundTo(places: 2) * 100 ) + "%"
        //infosRight += " "+String(describing: normalRatio) + " hours total"
        let lowRatio: Double = (24.0 * lowsPercentage).roundTo(places: 2)
        //infosLeft += "\nLows: " + String ( lowsPercentage.roundTo(places: 2) * 100 ) + "%"
        //infosRight += " "+String(describing: lowRatio) + " hours total"
        
        // update stats
        a1cSummary.update(icon: "Droplet", text: a1C.content, txtOffsetX: 35, txtOffsetY:3, offsetX: 0, offsetY: 0, width: 28, height: 28)
        bpmSummary.update(icon: "Heart", text: heartBpm.content, txtOffsetX: 35, txtOffsetY:3, offsetX: 0, offsetY: 0, width: 28, height: 28)
        sdSummary.update(icon: "UpArrows", text: sd.content, txtOffsetX: 35, txtOffsetY: 3, offsetX: 0, offsetY: 0, width: 28, height: 28)
        avgSummary.update(icon: "Chart", text: avg.content, txtOffsetX: 35, txtOffsetY:3, offsetX: 0, offsetY: 0, width: 28, height: 28)
        accelSummary.update(icon: "Rising", text: acceleration.content, txtOffsetX: 35, txtOffsetY:3, offsetX: 0, offsetY: 0, width: 28, height: 28)
        percentageNormalSummary.update(icon: "UpArrows", text: normalSum.content, txtOffsetX: 35, txtOffsetY:3, offsetX:0, offsetY: 0, width: 28, height: 28)
    }
    
    public func onSelection(event: Event?)
    {
        let sampleDate:String = chartManager.selectedSample.time
        let position: Int = chartManager.position
        if ( position > 0 ) {
            let delta: Int = chartManager.samples[position].value - chartManager.samples[position-1].value
            var diff: String = String (describing: delta)
            if (delta > 0) {
                diff = "+" + diff
            }
            difference.text = String (describing: diff)
        } else {
            difference.text = ""
        }
        
        if (self.chartManager.selectedSample.trend != "")
        {
            current.text = sampleDate + "\n" + String (describing: chartManager.selectedSample.value) + " mg/DL " + self.chartManager.selectedSample.trend
        } else
        {
            current.text = sampleDate + "\n" + String (describing: chartManager.selectedSample.value) + " mg/DL"
        }
    }
    
    public func pause()
    {
        print("DEBUG:: PAUSING")
        updateTimer?.invalidate()
        refreshTimer?.invalidate()
    }
    
    public func resume()
    {
        print("DEBUG:: RESUMING")
        updateTimer?.invalidate()
        refreshTimer?.invalidate()
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.updateTimer = Timer.scheduledTimer(timeInterval: 180, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            self.refreshTimer = Timer.scheduledTimer(timeInterval: 480, target: self, selector: #selector(self.refresh), userInfo: nil, repeats: true)
            self.updateTimer?.fire()
        }
    }
    
    public func onLoggedIn (event: Event)
    {
        // after login, initiate the first data pull
        resume()
    }
    
    public func onTokenRefreshed (event: Event)
    {
        // once token is refreshed, resume
        resume()
    }
    
    public func glucoseIOFailed (event: Event)
    {
        //pause()
    }
    
    public func onHKAuthorization (event: Event)
    {
        // request heart rate data from HealthKit
        hkBridge.getHeartRate()
    }
    
    public func onHKHeartRate (event: Event)
    {
        print (hkBridge.heartRates)
    }
    
    public func getRandomQuote() -> String
    {
        let randomIndex = Int(arc4random_uniform(UInt32(quotes.count)))
        return quotes[randomIndex]
    }

    @objc func update()
    {
        print("UPDATE:: Pulling latest data")
        remoteBridge.getGlucoseValues(token: DexcomBridge.TOKEN, startDate: "2017-06-19T08:00:00", endDate: "2017-06-20T08:00:00")
        hkBridge.getHeartRate()
    }
    
    @objc func refresh()
    {
        print("REFRESH:: Refreshing token")
        pause()
        remoteBridge.refreshToken()
    }
    
    @IBAction func fullTime(_ sender: Any)
    {
        let button: UIButton = sender as! UIButton
        chartManager.fulltimeView()
    }

    @IBAction func last3Hours(_ sender: Any)
    {
        let button: UIButton = sender as! UIButton
        button.alpha = 0.5
        chartManager.recentView()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
