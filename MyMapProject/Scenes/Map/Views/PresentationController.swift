//
//  PresentationController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 4.04.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit

class PresentationController: UIPresentationController {
    
    //let blurEffectView: UIVisualEffectView!
    var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissController))
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        let finalWidth = self.containerView!.frame.width
        let finalHeight = self.containerView!.frame.height

        return CGRect(x: 0, y: finalHeight * 0.6, width: finalWidth, height: finalHeight * 0.4)
        
    }
    
    override func presentationTransitionWillBegin() {
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [self] (UIViewControllerTransitionCoordinatorContext) in
            
            presentedView?.frame = frameOfPresentedViewInContainerView
            //self.blurEffectView.alpha = 0.5
            
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in })
    }
    
    override func dismissalTransitionWillBegin() {
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            //self.blurEffectView.alpha = 0
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            //self.blurEffectView.removeFromSuperview()
        })
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView!.roundCorners([.topLeft, .topRight], radius: 22)
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        //blurEffectView.frame = containerView!.bounds
    }
    
    
    @objc func dismissController(){
        self.presentedViewController.dismiss(animated: true, completion: nil)
    }
}
