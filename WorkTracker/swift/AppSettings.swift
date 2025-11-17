import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("hourlyRate") var hourlyRate: Double = 5.0
}
