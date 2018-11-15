//
//  HWVisualEffectView.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 04/11/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class HWVisualEffectView: NSVisualEffectView {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    self.customize()
  }
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    self.customize()
  }
  
  fileprivate func customize() {
    self.wantsLayer = true
    self.blendingMode = NSVisualEffectView.BlendingMode.withinWindow
    
    if #available(OSX 10.14, *) {
      self.material = .popover
    }
    
    self.state = NSVisualEffectView.State.followsWindowActiveState
    
    if #available(OSX 10.12, *) {
      self.isEmphasized = true
    } else {
      // Fallback on earlier versions
    }
  }
  
  override func viewDidEndLiveResize() {
    if (self.window != nil) && (self.window?.isSheet)! {
      /*
       Why do that here?
       If the windows is sheet the Visual Effect View looks "highlighted",
       the material goes crazy after a resize and must be set again.
       */
      self.customize()
    }
  }
}
