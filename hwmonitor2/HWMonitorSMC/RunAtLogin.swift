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
      
      let loginItems: [LSSharedFileListItem] = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as! [LSSharedFileListItem]
      for i in loginItems {
        let itemURL = LSSharedFileListItemCopyResolvedURL(i, 0, nil).takeRetainedValue()
        if appURL == itemURL as URL {
          return true
        }
      }
    }
    return false
  }

  
  func addLaunchAtStartup() {
    if !self.applicationIsInStartUpItems() {
      if let loginItemsRef = LSSharedFileListCreate( nil,
                                                     kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList? {
        let appUrl : URL = URL(fileURLWithPath: Bundle.main.bundlePath)
        let loginItems: [LSSharedFileListItem] = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as! [LSSharedFileListItem]
        LSSharedFileListInsertItemURL(loginItemsRef, loginItems.last, nil, nil, appUrl as CFURL, nil, nil)
        //print("Added to login items")
      }
    }
  }
  
  func removeLaunchAtStartup() {
    if self.applicationIsInStartUpItems() {
      let appURL : URL = URL(fileURLWithPath: Bundle.main.bundlePath)
      if let loginItemsRef = LSSharedFileListCreate( nil,
                                                     kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList? {
        let loginItems: [LSSharedFileListItem] = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as! [LSSharedFileListItem]
        for i in loginItems {
          let itemURL = LSSharedFileListItemCopyResolvedURL(i, 0, nil).takeRetainedValue()
          if appURL == itemURL as URL {
            LSSharedFileListItemRemove(loginItemsRef,i);
            //print("Removed from login items")
            break
          }
        }
        
      }
    }
    
  }


}
