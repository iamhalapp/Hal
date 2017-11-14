//
//  InterfaceController.swift
//  Scout Watch App Extension
//
//  Created by Thibault Imbert on 7/12/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var myButton: WKInterfaceButton!
    @IBOutlet var myLabel: WKInterfaceLabel!
    private var isAuthorized: Bool? = false
    let healthKitStore:HKHealthStore = HKHealthStore()
    
    @IBAction func buttonTapped() {
        myLabel.setText ("Tapped baby")
        if ( HKHealthStore.isHealthDataAvailable() ) {
            getHealthKitPermission()
        }
    }
    
    func getHealthKitPermission() {
        
        // Seek authorization in HealthKitManager.swift.
        authorizeHealthKit { (authorized) -> Void in
            if authorized {
                
                // Get blood glucose readings
                
            } else {
                print("Permission denied.")
            }
        }
    }

    func authorizeHealthKit(completion: ((_ success: Bool) -> Void)!) {
        let writableTypes: Set<HKSampleType> = [HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!]
        let readableTypes: Set<HKSampleType> = [HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!]
        
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        // Request Authorization
        healthKitStore.requestAuthorization(toShare: writableTypes, read: readableTypes) { (success, error) in
            
            if success {
                completion(true)
                self.isAuthorized = true
            } else {
                completion(false)
                self.isAuthorized = false
                print("error authorizating HealthStore. You're propably on iPad \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        myLabel.setText ("Whatsup")

    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
