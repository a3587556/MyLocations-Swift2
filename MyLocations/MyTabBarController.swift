//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by xyy on 16/3/1.
//  Copyright © 2016年 Razeware. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}
