//
//  HWVisualEffectView.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 04/11/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class HWVisualEffectView: NSVisualEffectView {
  private var appearanceObserver: NSKeyValueObservation?

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    self.customize()
  }
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    self.wantsLayer = true
    
    self.blendingMode = NSVisualEffectView.BlendingMode.withinWindow
    
    if #available(OSX 10.14, *) {
      // self.material = .popover
    }
    
    self.state = NSVisualEffectView.State.active
    
    if #available(OSX 10.12, *) {
      self.isEmphasized = true
    } else {
      // Fallback on earlier versions
    }
    self.customize()
    if #available(OSX 10.14, *) {
      self.appearanceObserver = self.observe(\.effectiveAppearance) { [weak self] _, _  in
        self?.customize()
      }
    }
  }
  
  deinit {
    if self.appearanceObserver != nil {
      self.appearanceObserver!.invalidate()
      self.appearanceObserver = nil
    }
  }
  
  override func viewDidMoveToWindow() {
    self.customize()
  }
  func customize() {
    self.appearance = getAppearance()
  }
}
