//
//  SlideInTransition.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 21.09.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit

class SlideInTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var isPresenting = false
    let dimmingView = UIView()
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.05
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let toViewController = transitionContext.viewController(forKey: .to), let fromViewController = transitionContext.viewController(forKey: .from) else { return }
        
        let containerView = transitionContext.containerView
        
        let finalWidth = toViewController.view.bounds.width * 0.6
        let finalHeight = toViewController.view.bounds.height
        
        if isPresenting {
            let tapGesture = UITapGestureRecognizer(target: toViewController, action: #selector(UIViewController.dismissControllerAnimated))
                        dimmingView.addGestureRecognizer(tapGesture)
            
            // Add dimming view
            dimmingView.backgroundColor = .black
            dimmingView.alpha = 0.0
            containerView.addSubview(dimmingView)
            dimmingView.frame = containerView.bounds
            // Add menu view controller to container
            containerView.addSubview(toViewController.view)
            
            // Init frame off the screen
            toViewController.view.frame = CGRect(x: finalWidth*1.70, y: 0, width: finalWidth, height: finalHeight)
            
        }
        
        // Animate on screen
        let transform = {
            self.dimmingView.alpha = 0.5
            toViewController.view.transform = CGAffineTransform(translationX: -finalWidth, y: 0)
        }
        
        // Animate back off screen
        let identity = {
            self.dimmingView.alpha = 0.0
            fromViewController.view.transform = .identity
        }
        
        // Animation of the transition
        let duration = transitionDuration(using: transitionContext)
        let isCancelled = transitionContext.transitionWasCancelled
        UIView.animate(withDuration: duration) {
            self.isPresenting ? transform() : identity()
        } completion: { (_) in
            transitionContext.completeTransition(!isCancelled)
            if !self.isPresenting {
                            self.dimmingView.removeFromSuperview()
            }
        }

    }
}
extension UIViewController {
    @IBAction func dismissControllerAnimated() {
        dismiss(animated: true)
    }
}
