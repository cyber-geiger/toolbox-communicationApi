//
//  RefreshOperation.swift
//  Runner
//
//  Created by user on 12.05.22.
//

import Foundation
class RefreshOperation: Operation {
  
  //3
  override func main() {
    //4
    if isCancelled {
      return
    }
      
      while(true){
          print("refreshing")
          usleep(1000)
      }
  }
}

