//
//  RestAlert.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import AudioToolbox
import UIKit

enum RestAlert {
    /// System sound ID for a short, unobtrusive chime (undocumented but widely used Apple system sound).
    private static let restEndSoundID: SystemSoundID = 1005

    static func playRestEndAlert() {
        AudioServicesPlaySystemSound(restEndSoundID)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
