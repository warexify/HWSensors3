//
//  PopoverViewController.swift
//  HWMonitorSMC
//
//  Created by Micky1979 on 26/07/17.
//  Copyright © 2017 Micky1979. All rights reserved.
//
// https://gist.github.com/Micky1979/4743842c4ec7cb95ea5cbbdd36beedf7
//

import Cocoa

class HWViewController: NSViewController, NSPopoverDelegate {
  var popover           : NSPopover?
  var popoverVC         : PopoverViewController?
  var popoverWC         : PopoverWindowController?
  var detachableWindow  : HWWindow?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.popoverVC =
      self.storyboard?.instantiateController(withIdentifier:
        NSStoryboard.SceneIdentifier(rawValue: "PopoverViewController")) as? PopoverViewController
    
    var height : CGFloat = (self.popoverVC?.view.bounds.origin.y)!
    var width  : CGFloat = (self.popoverVC?.view.bounds.origin.x)!

    if (UserDefaults.standard.object(forKey: kPopoverHeight) != nil) {
      height = CGFloat(UserDefaults.standard.float(forKey: kPopoverHeight))
    }
    
    if (UserDefaults.standard.object(forKey: kPopoverWidth) != nil) {
      width = CGFloat(UserDefaults.standard.float(forKey: kPopoverWidth))
    }
    if width < kMinWidth {
      width = kMinWidth
    }
    
    if height < kMinHeight {
      height = kMinHeight
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
    self.detachableWindow?.minSize = NSMakeSize(CGFloat(kMinWidth), CGFloat(kMinHeight))
    
    self.detachableWindow?.appearance = getAppearance()
    
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

