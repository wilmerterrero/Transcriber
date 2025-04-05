//
//  TranscriberApp.swift
//  Transcriber
//
//  Created by Lou Zell
//

import SwiftUI
import UIKit

// Add AppDelegate to print available fonts
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Print all available fonts for debugging
         print("==== AVAILABLE FONTS ====")
         for family in UIFont.familyNames.sorted() {
             print("Font Family: \(family)")
             for name in UIFont.fontNames(forFamilyName: family).sorted() {
                 print("   Font: \(name)")
             }
         }
        return true
    }
}

@main
@MainActor
struct TranscriberApp: App {
    // Register the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var transcriberManager = TranscriberManager()

    var body: some Scene {
        WindowGroup {
            TranscriberView(transcriberManager: transcriberManager)
        }
    }
}
