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
    self.statusField.autoHeight()
  }
}

class GadgetField: NSTextField {
  func autoHeight() {
    let h : CGFloat = self.window?.frame.height ?? 17
    let fs : CGFloat = (13 * h) / 17
    self.font  = NSFont.systemFont(ofSize: fs)
  }
  override func viewDidEndLiveResize() {
    self.autoHeight()
  }
  
  override var intrinsicContentSize:NSSize {
    let h : CGFloat = self.window?.frame.height ?? 17
    return NSMakeSize(-1, h)
  }
}
