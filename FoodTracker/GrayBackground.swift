//
//  GrayBackground.swift
//  FoodTracker
//
//  Created by Joey Lim on 15/04/2019.
//  Copyright © 2019 Joey Lim. All rights reserved.
//

import Foundation

class GrayBackground: NSObject {
    
    func registerSettingsBundle() {
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
    }
    
}
