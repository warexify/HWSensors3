//
//  PopoverWindowController.swift
//  HWTest
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class HWWindowController: NSWindowController, NSWindowDelegate {
  
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = NSAppearance(named: gAppearance )
  }
  
  class func loadFromNib() -> HWWindowController {
    let wc = (NSStoryboard(name: NSStoryboard.Name(rawValue: "Popover"),
                           bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Popover")) as! HWWindowController)
    return wc
  }
  
  func windowWillClose(_ notification: Notification) {
    
  }
}
