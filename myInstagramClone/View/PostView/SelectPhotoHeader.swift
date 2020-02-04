//
//  SelectPhotoHeader.swift
//  InstgramClone
//
//  Created by Sheldon on 1/11/20.
//  Copyright © 2020 wentao. All rights reserved.
//

import UIKit

class SelectPhotoHeader: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    // MARK: Properties
    var isZooming = false
    var originalImageCenter:CGPoint?
    
    let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        // If user interaction is not enabled the gestures wont be recognized
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(photoImageView)
        self.clipsToBounds = false
        
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(sender:)))
        pinch.delegate = self
        photoImageView.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlepan(sender:)))
        pan.delegate = self
        photoImageView.addGestureRecognizer(pan)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Handlers
    @objc func handleZoom(sender:UIPinchGestureRecognizer){
        if sender.state == .began {
            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
            let newScale = currentScale*sender.scale
            if newScale > 1 {
                self.isZooming = true
            }
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.photoImageView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            guard let center = self.originalImageCenter else {return}
            UIView.animate(withDuration: 0.3, animations: {
                self.photoImageView.transform = CGAffineTransform.identity
                self.photoImageView.center = center
            }, completion: { _ in
                self.isZooming = false
            })
        }
        
    }
    @objc func handlepan(sender:UIPanGestureRecognizer){
        //  when the gesture state is “.began” we will set the originalImageCenter to the current center of the view, but only if isZooming is true:
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
        }
        else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.photoImageView.superview)
        }
        
    }
    //  if two gesture recognizers should be allowed to recognize gestures simultaneously.
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Note that returning true is guaranteed to allow simultaneous recognition
        return true
    }
    
}



