//
//  ReachabilityManager.swift
//
//  Copyright 2019 Raúl Ferrer
//
//  Baseed on a Marco Santa post (https://marcosantadev.com/network-reachability-swift/)
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

// Only for iOS Operating System
#if os(iOS) // TODO: ipadOS

import Foundation
import SystemConfiguration


public class ReachabilityManager {
  /// Internet is reachable via WiFi or WWAN
  public var isReachable: Bool {
    return isReachableViaWWAN || isReachableViaWiFi
  }
  
  /// Internet is reachable via WWAN
  public var isReachableViaWWAN: Bool {
    return reachabilityStatus == .reachable(.wwan)
  }
  
  /// Internet is reachable via WiFi or WWAN
  public var isReachableViaWiFi: Bool {
    return reachabilityStatus == .reachable(.wifi)
  }
  
  /// Internet reachability status.
  public var reachabilityStatus: ReachabilityStatus {
    guard let flags = self.flags else { return .undefined }
    return reachabilityStatusForFlags(flags)
  }
  
  /// Queue where the `SCNetworkReachability` callbacks run
  public var queue: DispatchQueue = DispatchQueue.main
  
  /// A closure executed when the network reachability status changes. The closure takes a single argument: the
  /// network reachability status.
  public typealias Listener = (ReachabilityStatus) -> Void
  public var listener: Listener?
  
  /// Get network state information.
  private var flags: SCNetworkReachabilityFlags? {
    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(reachability, &flags) else { return nil }
    
    return flags
  }
  
  private let reachability: SCNetworkReachability
  private var previousFlags: SCNetworkReachabilityFlags

  
  /// This convenience init creates a `NetworkReachabilityManager` instance
  /// with the specified host.
  /// For example: www.google.com
  public convenience init?(host: String) {
    guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else { return nil }
    self.init(reachability: reachability)
  }
  
  
  /// This convenience init creates a `NetworkReachabilityManager` instance that monitors the address 0.0.0.0.
  public convenience init?() {
    // Initializes the socket IPv4 address struct
    var address = sockaddr_in()
    address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    address.sin_family = sa_family_t(AF_INET)
    // Passes the reference of the struct
    guard let reachability = withUnsafePointer(to: &address, { pointer in
      // Converts to a generic socket address
      return pointer.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size) {
        // $0 is the pointer to `sockaddr`
        return SCNetworkReachabilityCreateWithAddress(nil, $0)
      }
    }) else { return nil }
    
    self.init(reachability: reachability)
  }
  
  
  /// Called from both convenience inits
  private init(reachability: SCNetworkReachability) {
    self.reachability = reachability
    self.previousFlags = SCNetworkReachabilityFlags()
  }
  
  deinit {
    stop()
  }
}


// MARK: Listening
extension ReachabilityManager {
  // Start listening for changes in reachability
  @discardableResult
  public func start() -> Bool {
    // Creates a context
    var context = SCNetworkReachabilityContext(version: 0,
                                               info: nil,
                                               retain: nil,
                                               release: nil,
                                               copyDescription: nil)
    // Sets `self` as listener object
    context.info = Unmanaged.passUnretained(self).toOpaque()
    
    let callbackEnabled = SCNetworkReachabilitySetCallback(reachability, { (_, flags, info) in
      // Gets the `ReachabilityManager` object from the context info
      let reachability = Unmanaged<ReachabilityManager>.fromOpaque(info!).takeUnretainedValue()
      reachability.notifyListener(flags)
    }, &context )
    
    let queueEnabled = SCNetworkReachabilitySetDispatchQueue(reachability, queue)
    
    queue.async {
      guard let flags = self.flags else { return }
      self.notifyListener(flags)
    }
    
    return callbackEnabled && queueEnabled
  }
  
  /// Stop listening for changes in reachability
  public func stop() {
    // Remove callback and dispatch queue
    SCNetworkReachabilitySetCallback(reachability, nil, nil)
    SCNetworkReachabilitySetDispatchQueue(reachability, nil)
  }
  
  func notifyListener(_ flags: SCNetworkReachabilityFlags) {
    guard previousFlags != flags else { return }
    previousFlags = flags
    
    listener?(reachabilityStatusForFlags(flags))
  }
}

// MARK: - Reachability status
extension ReachabilityManager{
  /// Read the content of SCNetworkReachabilityFlags to see if network is reachable
  ///
  /// Types: transientConnection, connectionRequired, connectionOnTraffic, interventionRequired,
  ///        connectionOnDemand, isLocalAddress, isDirect, isWWAN, connectionAutomatic
  ///
  /// - Parameter flags: SCNetworkReachabilityFlags for current reachability status
  func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
    let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
    
    return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
  }
  
  
  /// Return reachability status
  ///
  /// - Parameter flags: SCNetworkReachabilityFlags for current reachability status
  func reachabilityStatusForFlags(_ flags: SCNetworkReachabilityFlags) -> ReachabilityStatus {
    guard isNetworkReachable(with: flags) else { return .notReachable }
    guard flags.contains(.isWWAN) else { return .reachable(.wifi) }
    
    return .reachable(.wwan)
  }
}

#endif
