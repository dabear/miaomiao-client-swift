//
//  SnoozeView.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 04/06/2019.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import UIKit
class View: UIView {
    
    init() {
        super.init(frame: .zero)
        
        self.initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    func initialize() {
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}

class SnoozeView: View {

    
    
    
    // this is going to be our container object
    @IBOutlet weak var containerView: UIView!
    
    
    @IBOutlet weak var snoozeDescription: UITextField!
    
    @IBOutlet weak var snoozePicker: UIPickerView!
    
    @IBOutlet weak var snoozeButton: UIButton!
    
    
    
    override func initialize() {
        super.initialize()
        
        // first: load the view hierarchy to get proper outlets
        /*let name = String(describing: type(of: self))
        let nib = UINib(nibName: name, bundle: .main)
        nib.instantiate(withOwner: self, options: nil)*/
        let nib = SnoozeView.nib()
        print("nib is \(nib)")
        nib.instantiate(withOwner: self, options: nil)
        
        // next: append the container to our view
        self.addSubview(self.containerView)
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.containerView.topAnchor.constraint(equalTo: self.topAnchor),
            self.containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
        
        snoozeButton.setTitle("Test1", for: .normal)
        
    }

    /*
     let stackView = HUDView.nib().instantiate(withOwner: self, options: nil)[0] as! UIStackView
     self.addSubview(stackView)
     
     */
    /*private func commonInit() {
        print("SnoozeView initialized")
        //Bundle.main.loadNibNamed("SnoozeView", owner: self, options: nil)
        contentView = SnoozeView.nib().instantiate(withOwner: self, options: nil)[0] as! SnoozeView
        addSubview(contentView)
        
        contentView.fixInView(self)
    }*/
}

extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}
