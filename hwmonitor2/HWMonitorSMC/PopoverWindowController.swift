//
//  PopoverWindowController.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 26/02/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class PopoverWindowController: NSWindowController, NSWindowDelegate {
  
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = NSAppearance(named: gAppearance )
  }
  
  func windowDidResize(_ notification: Notification) {
    if let win : HWWindow = notification.object as? HWWindow {
      let frame  = win.contentView?.bounds
      var width : CGFloat = (frame?.width)!
      var height : CGFloat = (frame?.height)!
      
      if width < 310 {
        width = 310
      }
      
      if height < 270 {
        height = 270
      }
      
      UserDefaults.standard.set(frame?.width, forKey: "popoverWidth")
      UserDefaults.standard.set(frame?.height, forKey: "popoverHeight")
      UserDefaults.standard.synchronize()
    }
  }
  func windowWillClose(_ notification: Notification) {
    
  }
}
