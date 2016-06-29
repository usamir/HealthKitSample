//
//  MasterViewController.swift
//  HKTutorial
//
//  Created by samir on 29/06/16.
//  Copyright (c) 2016 samir. All rights reserved.
//

import Foundation

import UIKit


class MasterViewController: UITableViewController {
  
  let kAuthorizeHealthKitSection = 2
  let kProfileSegueIdentifier = "profileSegue"
  let kWorkoutSegueIdentifier = "workoutsSeque"
  
  let healthManager:HealthManager = HealthManager()
  
  // Request healthkit authorization
  func authorizeHealthKit()
  {
    healthManager.authorizeHealthKit{ (authorized, error) -> Void in
      if authorized {
        print ("HealthKit is authorized!!!")
      }
      else {
        print("HealthKit authorization is denied!!!")
      }
      if error != nil {
        print("\(error)")
      }
    }
  }
  
  
  // MARK: - Segues
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier ==  kProfileSegueIdentifier {
      
      if let profileViewController = segue.destinationViewController as? ProfileViewController {
        profileViewController.healthManager = healthManager
      }
    }
    else if segue.identifier == kWorkoutSegueIdentifier {
      if let workoutViewController = segue.destinationViewController.topLayoutGuide as? WorkoutsTableViewController {
        workoutViewController.healthManager = healthManager;
      }
    }
  }
  
  // MARK: - TableView Delegate
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    switch (indexPath.section, indexPath.row)
    {
    case (kAuthorizeHealthKitSection,0):
      authorizeHealthKit()
    default:
      break
    }
    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  
  
}
