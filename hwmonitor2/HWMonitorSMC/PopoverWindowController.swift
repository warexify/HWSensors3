//
//  PopoverWindowController.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 26/02/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//
// https://gist.github.com/Micky1979/4743842c4ec7cb95ea5cbbdd36beedf7
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
      
      UserDefaults.standard.set(frame?.width, forKey: kPopoverWidth)
      UserDefaults.standard.set(frame?.height, forKey: kPopoverHeight)
      UserDefaults.standard.synchronize()
    }
  }
  func windowWillClose(_ notification: Notification) {
    
  }
}
