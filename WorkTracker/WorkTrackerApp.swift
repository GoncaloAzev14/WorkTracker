//
//  WorkTrackerApp.swift
//  WorkTracker
//
//  Created by Gonçalo Azevedo on 24/06/2025.
//

import SwiftUI


@main
struct WorkTrackerApp: App {
    @StateObject var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
