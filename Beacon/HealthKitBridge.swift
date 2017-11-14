//
//  HKManager.swift
//  HAL
//
//  Created by Thibault Imbert on 7/13/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitBridge: EventDispatcher
{
    
    private var isAuthorized: Bool? = false
    private var sampleType: HKQuantityType?
    public var bloodSamples: [HKQuantitySample]?
    public var heartRates: [HeartRateSample] = []
    let healthKitStore:HKHealthStore = HKHealthStore()
    
    private static var sharedHKManager: HealthKitBridge =
    {
        let hkManager = HealthKitBridge()
        return hkManager
    }()
    
    func getHealthKitPermission()
    {
        // we want blood glucose levels
        let writableTypes: Set<HKSampleType> = [HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!, HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
        let readableTypes: Set<HKSampleType> = [HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!, HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
        
        // Request Authorization
        healthKitStore.requestAuthorization(toShare: writableTypes, read: readableTypes) { (success, error) in
            
            if success {
                self.isAuthorized = true
                DispatchQueue.main.async(execute:
                {
                    self.dispatchEvent(event: Event(type: EventType.authorized, target: self))
                })
            } else {
                self.isAuthorized = false
                print("error authorizating HealthStore. You're propably on iPad \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    func getBloodSamples(fromDay: Int = -1, to: Date = Date())
    {
        if isAuthorized!
        {
            // Get blood glucose readings
            let now = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            
            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: fromDay, to: to)
            
            //let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
            let allreadings = HKQuery.predicateForSamples(withStart: yesterday, end: now as Date)
            
            // 2. Build the sort descriptor to return the samples in descending order
            let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: true)
            
            // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
            let limit = Int.max
            
            let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)
            
            // 4. Build samples query
            let sampleQuery = HKSampleQuery(sampleType: sampleType!, predicate: allreadings, limit: limit, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                
                if error != nil
                {
                    print(error)
                    return;
                }
                
                // Get the first sample
                self.bloodSamples = results as? [HKQuantitySample]
                DispatchQueue.main.async(execute:
                    {
                        self.dispatchEvent(event: Event(type: EventType.glucoseValues, target: self))
                })
            }
            // 5. Execute the Query
            self.healthKitStore.execute(sampleQuery)
            
        } else
        {
            print("Permission denied.")
        }
    }
    
    func getHeartRate(fromDay: Int = -1, to: Date = Date())
    {
        if isAuthorized!
        {
            // Get blood glucose readings
            let now = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            
            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: fromDay, to: to)
            
            let mostRecentPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: now as Date)
            
            // 2. Build the sort descriptor to return the samples in descending order
            let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: true)
            
            // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
            let limit = Int.max
            
            let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
            
            // 4. Build samples query
            let sampleQuery = HKSampleQuery(sampleType: sampleType!, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                
                print ( error )
                if error != nil {
                    return;
                }
                
                self.heartRates.removeAll()
                let bpmUnit:HKUnit = HKUnit(from: "count/min")
                DispatchQueue.main.async(execute:
                    {
                    let bpmResults: [HKQuantitySample] = (results as? [HKQuantitySample])!
                    for sample in bpmResults
                    {
                        let value = sample.quantity.doubleValue(for: bpmUnit)
                        self.heartRates.append(HeartRateSample(pValue: Int(value), pDate: "", pTime: "", pTrend: ""))
                    }
                    self.dispatchEvent(event: Event(type: EventType.heartRate, target: self))
                })
            }
            // 5. Execute the Query
            self.healthKitStore.execute(sampleQuery)
            
        } else
        {
            print("Permission denied.")
        }
    }
    
    class func shared() -> HealthKitBridge
    {
        return sharedHKManager
    }
}
