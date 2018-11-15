//
//  PopoverWindowController.swift
//  HWMonitorSMC
//
//  Created by Micky1979 on 26/07/17.
//  Copyright © 2017 Micky1979. All rights reserved.
//
// https://gist.github.com/Micky1979/4743842c4ec7cb95ea5cbbdd36beedf7
//

import Cocoa

class PopoverWindowController: NSWindowController, NSWindowDelegate {
  
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = getAppearance()
  }
  
  func windowDidResize(_ notification: Notification) {
    if let win : HWWindow = notification.object as? HWWindow {
      let frame  = win.contentView?.bounds
      var width : CGFloat = (frame?.width)!
      var height : CGFloat = (frame?.height)!
      
      if width < kMinWidth {
        width = kMinWidth
      }
      
      if height < kMinHeight {
        height = kMinHeight
      }
      
      UserDefaults.standard.set(frame?.width, forKey: kPopoverWidth)
      UserDefaults.standard.set(frame?.height, forKey: kPopoverHeight)
      UserDefaults.standard.synchronize()
    }
  }
  func windowWillClose(_ notification: Notification) {
    
  }
}
