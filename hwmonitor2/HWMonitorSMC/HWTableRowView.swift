//
//  HWTableRowView.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 03/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class HWTableRowView: NSTableRowView {

  override var interiorBackgroundStyle: NSView.BackgroundStyle {
    if getAppearance().name == NSAppearance.Name.vibrantDark {
      return .dark
    } else {
      return self.isSelected ? .dark : .light
    }
  }
  
  override func drawSelection(in dirtyRect: NSRect) {
    if self.selectionHighlightStyle != .none {
      if !self.isEmphasized {
        self.isEmphasized = true
      }
      let rect = NSInsetRect(self.bounds, 1.5, 1.5)
      if getAppearance().name == NSAppearance.Name.vibrantDark {
        NSColor.gray.setStroke()
        NSColor.gray.setFill()
      } else {
        NSColor.alternateSelectedControlColor.setStroke()
        NSColor.alternateSelectedControlColor.setFill()
      }
      let bpath = NSBezierPath.init(roundedRect: rect, xRadius: 1, yRadius: 1)
      bpath.fill()
      bpath.stroke()
    }
  }
}
