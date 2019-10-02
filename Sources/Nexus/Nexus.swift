//  RxReachability.swift
//
//  Copyright 2019 Raúl Ferrer
//
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
//  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import RxSwift
import RxCocoa

public class RxReachability {
  private let connectivity: BehaviorRelay<ReachabilityStatus> = BehaviorRelay(value: .notReachable)
  private let reachabilityManager = ReachabilityManager()
  
  static public let shared = RxReachability()
  private init() { }
  
  
  /// Connectivity as Observable
  public func networkWatch() -> Observable<ReachabilityStatus> {
    return self.connectivity.asObservable()
  }

    
  /// Starts monitoring the network availability status
  public func startMonitoring() {
    self.reachabilityManager?.listener = { status in
      switch status {
      case .notReachable:
        self.connectivity.accept(.notReachable)
      case .undefined :
        self.connectivity.accept(.notReachable)
      case .reachable(.wifi):
        self.connectivity.accept(.reachable(.wifi))
      case .reachable(.wwan):
        self.connectivity.accept(.reachable(.wwan))
        self.connectivity.accept(.notReachable)
      }
    }
    
    self.reachabilityManager?.start()
  }
  
  
  /// Stops monitoring the network availability status
  public func stopMonitoring(){
    self.reachabilityManager?.stop()
  }
}
