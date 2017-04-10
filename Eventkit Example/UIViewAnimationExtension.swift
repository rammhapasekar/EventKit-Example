//
//  UIViewAnimationExtension.swift
//  Eventkit Example
//
//  Created by Ram Mhapasekar on 10/04/17.
//  Copyright © 2017 rammhapasekar. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func fadeIn(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: completion)  }
    
    func fadeOut(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }
    
    func ScaleViewWithSpringDamping(){
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            
            self.transform = .identity
        }){ (success) in
            
        }
    }
}
