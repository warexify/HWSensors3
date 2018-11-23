//
//  Themes.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 21/11/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

public enum Theme : String {
  case Default    = "Default"
  case DashedH    = "Dashed Horizontally"
  case NoGrid     = "No Grid"
  case NoGridCB   = "No Grid, clear background"
  case GridClear  = "With Grid, clear background"
}

public struct Themes {
  
  init(theme: Theme, outline: HWOulineView) {
    let dark = getAppearance().name == .vibrantDark
    switch theme {
    case .Default:
      outline.enclosingScrollView?.borderType = NSBorderType.noBorder
      outline.enclosingScrollView?.drawsBackground = true
      outline.enclosingScrollView?.contentView.drawsBackground = false
      outline.enclosingScrollView?.backgroundColor = NSColor.clear
      outline.usesAlternatingRowBackgroundColors = true
      outline.backgroundColor = (dark ? NSColor.black : NSColor.white)
      outline.gridColor = NSColor.gridColor
      outline.gridStyleMask = [.solidVerticalGridLineMask, .dashedHorizontalGridLineMask ]
    case .DashedH:
      outline.enclosingScrollView?.borderType = NSBorderType.lineBorder
      outline.enclosingScrollView?.drawsBackground = true
      outline.enclosingScrollView?.contentView.drawsBackground = true
      outline.enclosingScrollView?.backgroundColor = NSColor.clear
      outline.usesAlternatingRowBackgroundColors = true
      outline.backgroundColor = (dark ? NSColor.black : NSColor.white)
      outline.gridColor = NSColor.gridColor
      outline.gridStyleMask = [.dashedHorizontalGridLineMask]
    case .NoGrid:
      outline.enclosingScrollView?.borderType = NSBorderType.lineBorder
      outline.enclosingScrollView?.drawsBackground = true
      outline.enclosingScrollView?.contentView.drawsBackground = true
      outline.usesAlternatingRowBackgroundColors = true
      outline.backgroundColor = (dark ? NSColor.black : NSColor.white)
    case .NoGridCB:
      outline.enclosingScrollView?.borderType = NSBorderType.noBorder
      outline.enclosingScrollView?.drawsBackground = false
      outline.usesAlternatingRowBackgroundColors = false
      if #available(OSX 10.14, *) {
        outline.enclosingScrollView?.contentView.drawsBackground = false
        outline.enclosingScrollView?.backgroundColor = NSColor.clear
        outline.backgroundColor = NSColor.clear
      } else {
        outline.enclosingScrollView?.contentView.drawsBackground = false
        outline.enclosingScrollView?.backgroundColor = /*(dark ? NSColor.black : NSColor.white)*/ NSColor.clear
        outline.backgroundColor = /*(dark ? NSColor.black : NSColor.white)*/ NSColor.clear
      }
      break
    case .GridClear:
      outline.enclosingScrollView?.borderType = NSBorderType.lineBorder
      outline.enclosingScrollView?.drawsBackground = false
      outline.usesAlternatingRowBackgroundColors = false
      if #available(OSX 10.14, *) {
        outline.enclosingScrollView?.contentView.drawsBackground = false
        outline.enclosingScrollView?.backgroundColor = NSColor.clear
        outline.backgroundColor = NSColor.clear
      } else {
        outline.enclosingScrollView?.contentView.drawsBackground = false
        outline.enclosingScrollView?.backgroundColor = /*(dark ? NSColor.black : NSColor.white)*/ NSColor.clear
        outline.backgroundColor = /*(dark ? NSColor.black : NSColor.white)*/ NSColor.clear
      }
      outline.gridColor = NSColor.gridColor
      outline.gridStyleMask = [.dashedHorizontalGridLineMask, .solidVerticalGridLineMask]
    }
  }
}
