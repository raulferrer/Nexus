//
//  ReachabilityStatus.swift
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

public enum ReachabilityStatus: Equatable {
  case undefined
  case notReachable
  case reachable(ConnectionType)
  
  /// Returns whether the two network reachability status values are equal.
  ///
  /// - parameter lhs: The left-hand side value to compare.
  /// - parameter rhs: The right-hand side value to compare.
  ///
  /// - returns: `true` if the two values are equal, `false` otherwise.
  public static func ==(lhs: ReachabilityStatus,
                 rhs: ReachabilityStatus) -> Bool {
    switch (lhs, rhs) {
    case (.undefined, .undefined):
      return true
    case (.notReachable, .notReachable):
      return true
    case let (.reachable(lhsConnectionType), .reachable(rhsConnectionType)):
      return lhsConnectionType == rhsConnectionType
    default:
      return false
    }
  }
}
