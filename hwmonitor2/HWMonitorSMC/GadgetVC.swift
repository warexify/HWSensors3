//
//  GadgetVC.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 30/10/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class GadgetVC: NSViewController {
  @IBOutlet var statusField : GadgetField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.statusField.stringValue = ""
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
  }
}

class GadgetField: NSTextField {
  override var intrinsicContentSize:NSSize{
    return NSMakeSize(-1, 17)
  }
}
