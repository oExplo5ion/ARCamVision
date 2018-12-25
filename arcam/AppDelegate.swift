//
//  AppDelegate.swift
//  arcam
//
//  Created by Mac on 12/22/18.
//  Copyright © 2018 alekseyrobul. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.isStatusBarHidden = true
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = CameraViewController()
        window?.makeKeyAndVisible()
        return true
    }

}

