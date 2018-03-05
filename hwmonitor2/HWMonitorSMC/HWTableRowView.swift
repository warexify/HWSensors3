//
//  HWTableRowView.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 03/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class HWTableRowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {
    if self.selectionHighlightStyle != .none {
      let rect = NSInsetRect(self.bounds, 1.5, 1.5)
      if gAppearance == NSAppearance.Name.vibrantDark {
        NSColor.gray.setStroke()
        NSColor.gray.setFill()
      } else {
        NSColor.controlTextColor.setStroke()
        NSColor.controlTextColor.setFill()
      }
      let bpath = NSBezierPath.init(roundedRect: rect, xRadius: 1, yRadius: 1)
      bpath.fill()
      bpath.stroke()
    }
  }
}
