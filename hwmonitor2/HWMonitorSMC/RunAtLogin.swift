//
//  RunAtLogin.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 18/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

extension AppDelegate {
  func applicationIsInStartUpItems() -> Bool {
    let appURL : URL = URL(fileURLWithPath: Bundle.main.bundlePath)
    if let loginItemsRef = LSSharedFileListCreate(nil,
                                                  kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList? {
      
      if let loginItems: [LSSharedFileListItem] = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as? [LSSharedFileListItem] {
        for i in loginItems {
          if let itemURL = LSSharedFileListItemCopyResolvedURL(i, 0, nil) {
            if (itemURL.takeRetainedValue() as URL) == appURL {
              return true
            }
          }
        }
      }
    }
    return false
  }

  
  func addLaunchAtStartup() {
    if !self.applicationIsInStartUpItems() {
      let appURL : URL = URL(fileURLWithPath: Bundle.main.bundlePath)
      
      if let loginItemsRef = LSSharedFileListCreate(nil,
                                                    kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList? {
        
        if let loginItems: [LSSharedFileListItem] = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as? [LSSharedFileListItem] {
          LSSharedFileListInsertItemURL(loginItemsRef, loginItems.last, nil, nil, appURL as CFURL, nil, nil)
          //print("Added to login items")
        }
      }
    }
  }
  
  func removeLaunchAtStartup() {
    if self.applicationIsInStartUpItems() {
      let appURL : URL = URL(fileURLWithPath: Bundle.main.bundlePath)
      
      if let loginItemsRef = LSSharedFileListCreate(nil,
                                                    kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList? {
        
        if let loginItems: [LSSharedFileListItem] = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as? [LSSharedFileListItem] {
          for i in loginItems {
            if let itemURL = LSSharedFileListItemCopyResolvedURL(i, 0, nil) {
              if (itemURL.takeRetainedValue() as URL) == appURL {
                LSSharedFileListItemRemove(loginItemsRef,i);
                //print("Removed from login items")
                break
              }
            }
          }
        }
      }
    }
  }
}
