//
//  PopoverViewController.swift
//  HWMonitorSMC
//
//  Created by Micky1979 on 20/02/18.
//  Copyright © 2018 HWMonitor. All rights reserved.
//

import Cocoa

class HWViewController: NSViewController, NSPopoverDelegate {
  var popover : NSPopover?
  var popoverVC : PopoverViewController?
  var popoverWC : PopoverWindowController?
  var detachableWindow: HWWindow?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.popoverVC =
      self.storyboard?.instantiateController(withIdentifier:
        NSStoryboard.SceneIdentifier(rawValue: "PopoverViewController")) as? PopoverViewController
    
    var height : Float = Float((self.popoverVC?.view.bounds.origin.y)!)
    var width  : Float = Float((self.popoverVC?.view.bounds.origin.x)!)

    if (UserDefaults.standard.object(forKey: "popoverHeight") != nil) {
      height = UserDefaults.standard.float(forKey: "popoverHeight")
    }
    
    if (UserDefaults.standard.object(forKey: "popoverWidth") != nil) {
      width = UserDefaults.standard.float(forKey: "popoverWidth")
    }
    if width < 310 {
      width = 310
    }
    
    if height < 270 {
      height = 270
    }
    self.popoverVC?.view.setFrameSize(NSMakeSize(CGFloat(width), CGFloat(height)))

    let frame : NSRect = (self.popoverVC?.view.bounds)!
    
    let rect  : NSRect = HWWindow.contentRect(forFrameRect: frame,
                                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView])

    self.detachableWindow = HWWindow(contentRect: rect,
                                     styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                                     backing: .buffered,
                                     defer: true)
    //---------------------
    self.popoverWC = PopoverWindowController()
    self.detachableWindow?.windowController = self.popoverWC
    self.popoverWC?.window = self.detachableWindow
    self.detachableWindow?.delegate = self.popoverWC
    //---------------------
    
    self.detachableWindow?.contentViewController = self.popoverVC
    self.detachableWindow?.isReleasedWhenClosed = false
    self.detachableWindow?.titlebarAppearsTransparent = true
    self.detachableWindow?.minSize = NSMakeSize(310, 270)
    
    self.detachableWindow?.appearance = NSAppearance(named: gAppearance)
    
    
    
    let shared = NSApplication.shared.delegate as! AppDelegate
    if let button = shared.statusItem.button {
      button.target = self
      button.action = #selector(self.showPopover(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
  }
  
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  func createPopover() {
    if (self.popover == nil) {
      self.popover = NSPopover()
      self.popover?.animates = true
      self.popover?.contentViewController = self.popoverVC
      self.popover?.behavior = .transient
      self.popover?.delegate = self
      
      // determine the appearance automatically
    }
  }
  
  @objc func showPopover(_ sender: NSStatusBarButton?) {
    if  (self.detachableWindow?.isVisible)! {
      if (self.detachableWindow?.styleMask.contains(.fullScreen))! {
        self.detachableWindow?.toggleFullScreen(self)
        return
      }
    }
  
    self.popoverVC?.attachButton.isEnabled = false
    self.popoverVC?.attachButton.isHidden = true
    self.createPopover()
    self.popoverVC?.updateTitles()
    NSApp.activate(ignoringOtherApps: true)
    self.popover?.show(relativeTo: (sender?.bounds)!, of: sender!, preferredEdge: NSRectEdge.maxY)
  }
  
  func popoverWillShow(_ notification: Notification) {
    if (self.detachableWindow?.isVisible)! {
      self.detachableWindow?.orderOut(self)
    }
  }
  func popoverDidClose(_ notification: Notification) {
    if (notification.userInfo![NSPopover.closeReasonUserInfoKey] != nil) {
      self.popover = nil
    }
  }
  
  func popoverShouldDetach(_ popover: NSPopover) -> Bool {
    return (self.popoverVC!.lock.state == NSControl.StateValue.off)
  }
  
  func detachableWindow(for popover: NSPopover) -> NSWindow? {
    self.popoverVC?.attachButton.isEnabled = true
    self.popoverVC?.attachButton.isHidden = false
    return self.detachableWindow
  }
}

