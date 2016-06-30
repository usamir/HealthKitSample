//
//  HealthManager.swift
//  HKTutorial
//
//  Created by samir on 29/06/16.
//  Copyright (c) 2016 samir. All rights reserved.
//

import HealthKit
import UIKit

class HealthManager {
  
  // core of the health kit framework is hkhealthstore
  let healthKitStore: HKHealthStore = HKHealthStore()
  
  // Authorization of healthKit
  func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!)
  {
    // Set the types you want to read from HK Store
    let healthKitTypesToRead: Set<HKObjectType> = [
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
      HKObjectType.workoutType()
      ]
    
    // Set the types you want to write to HK Store
    let healthKitTypesToWrite: Set<HKSampleType> = [
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!,
      HKQuantityType.workoutType()
      ]
    
    // If the store is not available, return an error and don't go on.
    if !HKHealthStore.isHealthDataAvailable()
    {
      let error = NSError(domain: "com.samir.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
      if( completion != nil )
      {
        completion(success:false, error:error)
      }
      return;
    }
    
    // Request HealthKit authorization
    healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToWrite, readTypes: healthKitTypesToRead) { (success, error) -> Void in
      
      if( completion != nil )
      {
        completion(success:success,error:error)
      }
    }
  }
  
  // Read user's characteristics from HealthKit store
  func readProfile() -> ( age:Int?,  biologicalsex: HKBiologicalSexObject?, bloodtype: HKBloodTypeObject?)
  {
    var age:Int?
    
    // Request birthday and calculate age
    do {
      let birthDay = try healthKitStore.dateOfBirth()
      let today = NSDate()
      let differenceComponents = NSCalendar.currentCalendar().components(.Year, fromDate: birthDay, toDate: today, options: NSCalendarOptions(rawValue: 0) )
      age = differenceComponents.year
    } catch {
      print("Error reading Birthday")
    }
    
    // Read biological sex
    var biologicalSex: HKBiologicalSexObject?
    do {
      biologicalSex = try healthKitStore.biologicalSex()

    } catch {
      print("Error reading Biological Sex")
    }
    
    // Read blood type
    var bloodType: HKBloodTypeObject?
    do {
      bloodType = try healthKitStore.bloodType()
    } catch {
      print("Error reading Blood Type")
    }
    
    // Return the information read in a tuple
    return (age, biologicalSex, bloodType)
  }
  
  // Read samples
  func readMostRecentSample(sampleType: HKSampleType , completion: ((HKSample!, NSError!) -> Void)!)
  {
    
    // Build the Predicate
    let past = NSDate.distantPast() 
    let now   = NSDate()
    let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
    
    // Build the sort descriptor to return the samples in descending order
    let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
    // we want to limit the number of samples returned by the query to just 1 (the most recent)
    let limit = 1
    
    // Build samples query
    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
    { (sampleQuery, results, error ) -> Void in
      
      if error != nil {
        completion(nil,error)
        return;
      }
      
      // Get the first sample
      let mostRecentSample = results!.first as? HKQuantitySample
      
      // Execute the completion closure
      if completion != nil {
        completion(mostRecentSample,nil)
      }
    }
    // Finally. Execute the Query
    self.healthKitStore.executeQuery(sampleQuery)
  }
  
  // Save sample to HealthKit store
  func saveBMISample(bmi: Double, date: NSDate ) {
    
    // Create a BMI Sample
    let bmiType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)
    let bmiQuantity = HKQuantity(unit: HKUnit.countUnit(), doubleValue: bmi)
    let bmiSample = HKQuantitySample(type: bmiType!, quantity: bmiQuantity, startDate: date, endDate: date)
    
    // Save the sample in the store
    healthKitStore.saveObject(bmiSample, withCompletion: { (success, error) -> Void in
      if( error != nil ) {
        print("Error saving BMI sample: \(error!.localizedDescription)")
      } else {
        print("Success. BMI sample saved successfully!!!")
      }
    })
  }
  
  
  func saveRunningWorkout(startDate:NSDate , endDate:NSDate , distance:Double, distanceUnit:HKUnit , kiloCalories:Double,
                          completion: ( (Bool, NSError!) -> Void)!) {
    
    // Create quantities for the distance and energy burned
    let distanceQuantity = HKQuantity(unit: distanceUnit, doubleValue: distance)
    let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kiloCalories)
    
    // Save Running Workout
    let workout = HKWorkout(activityType: HKWorkoutActivityType.Running, startDate: startDate, endDate: endDate, duration: abs(endDate.timeIntervalSinceDate(startDate)), totalEnergyBurned: caloriesQuantity, totalDistance: distanceQuantity, metadata: nil)
    healthKitStore.saveObject(workout, withCompletion: { (success, error) -> Void in
      if( error != nil  ) {
        // Error saving the workout
        completion(success,error)
      }
      else {
        // Workout saved
        //completion(success,nil)
        
        // if success, then save the associated samples so that they appear in the Health Store
        let distanceSample = HKQuantitySample(type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!, quantity: distanceQuantity, startDate: startDate, endDate: endDate)
        let caloriesSample = HKQuantitySample(type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!, quantity: caloriesQuantity, startDate: startDate, endDate: endDate)
        
        self.healthKitStore.addSamples([distanceSample,caloriesSample], toWorkout: workout, completion: { (success, error ) -> Void in
          completion(success, error)
        })
        
      }
    })
  }
  
  // Query workouts
  func readRunningWorkOuts(completion: (([AnyObject]!, NSError!) -> Void)!) {
    // Build the Predicate to read only running workouts
    let predicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.Running)
    
    // Build the sort descriptor to return the samples in descending order
    let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
    
    // Build samples query
    let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
    { (sampleQuery, results, error ) -> Void in
      
      if error != nil {
        print("There was an error while reading the samples: \(error?.localizedDescription)")
      }
      completion(results, error)
    }
    // Finally. Execute the Query
    self.healthKitStore.executeQuery(sampleQuery)
  }
}