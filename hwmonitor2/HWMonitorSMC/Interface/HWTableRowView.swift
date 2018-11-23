//
//  HWTableRowView.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 03/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class HWTableRowView: NSTableRowView {
  internal var isDark: Bool = false
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    self.wantsLayer = true
    self.isEmphasized = true
  }
  
  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var interiorBackgroundStyle: NSView.BackgroundStyle {
    if getAppearance().name == NSAppearance.Name.vibrantDark {
      return .dark
    } else {
      return self.isSelected ? .dark : .light
    }
  }
  
  override func drawSelection(in dirtyRect: NSRect) {
    if self.selectionHighlightStyle != .none {
      let roundedRect = NSInsetRect(self.bounds, 1.5, 1.5)
      NSColor(calibratedWhite: 0.65, alpha: 1).setStroke()
      NSColor(calibratedWhite: 0.82, alpha: 1).setFill()
      let selectionPath = NSBezierPath.init(roundedRect: roundedRect, xRadius: 1, yRadius: 1)
      selectionPath.fill()
      selectionPath.stroke()
    }
  }
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    if isSelected == true {
      NSColor.lightGray.set()
      dirtyRect.fill()
    }
  }
}

