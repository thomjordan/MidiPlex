//
//  Globals.swift
//  MidiPlex
//
//  Created by Thom Jordan on 6/23/17.
//  Copyright © 2017 Thom Jordan. All rights reserved.
//

import Foundation


public var verbose : Bool = true

public func printLine<T>(_ x: T) {Swift.print(x)} // Global print function to use from NSView

public func printLog(_ s: String) { verbose ? printLine(s) : () }


