//
//  MidiManager.swift
//  ReactiveController
//
//  Created by Thom Jordan on 6/9/17.
//  Copyright © 2017 Thom Jordan. All rights reserved.
//

import Cocoa
import VVMIDI


// public typealias MidiMessage = VVMIDIMessage

public class MidiMessage : VVMIDIMessage {
    
    public override init() {
        super.init() 
    }
    
    public override init(fromVals t:UInt8, _ c:UInt8, _ d1:UInt8, _ d2:UInt8) {
        super.init(fromVals: t, c, d1, d2)
    }
    
    public override init(fromVals t:UInt8, _ c:UInt8, _ d1:UInt8, _ d2:UInt8, _ d3:UInt8) {
        super.init(fromVals: t, c, d1, d2, d3)
    }
    
    public override init(fromVals t:UInt8, _ c:UInt8, _ d1:UInt8, _ d2:UInt8, _ d3:UInt8, _ time:UInt64) {
        super.init(fromVals: t, c, d1, d2, d3, time)
    }
}


public class MidiNode : VVMIDINode {
    
    public override init?(senderWithEndpoint: MIDIEndpointRef) {
        super.init(senderWithEndpoint: senderWithEndpoint)
    }
    
    public override init?(receiverWithEndpoint: MIDIEndpointRef) {
        super.init(receiverWithEndpoint: receiverWithEndpoint)
    }
    
    public override init?(senderWithName: String) {
        super.init(senderWithName: senderWithName)
    }
    
    public override init?(receiverWithName: String) {
        super.init(receiverWithName: receiverWithName)
    }
}



// MARK: - Managers

class Managers {
    static var midiManager = VVMIDIManager()
}



// MARK: - struct: MidiNodeMessage


public struct MidiNodeMessage {
    
    public var midi : MidiMessage = MidiMessage()
    
    public var node : String = ""
    
    
    public init(midi: MidiMessage = MidiMessage(), node: String = "") {
        
        self.midi = midi
        
        self.node = node
    }
}


// MARK: - protocol: VVMIDIDelegateSwift


protocol VVMIDIDelegateSwift : VVMIDIDelegateProtocol {
    
    var midiManager     : VVMIDIManager! { get set }
    var midiSources     : [VVMIDINode]   { get }
    var midiSourceNames : [String]       { get }
    
    func enableAllMidiSources()
}


// MARK: - MidiCenter (singleton)


@objc public final class MidiCenter : NSObject, VVMIDIDelegateSwift {
    
    static public let shared = MidiCenter()
    
    public var midiReceiveCallbacks : [(MidiNodeMessage) -> ()] = []
    
    public var setupChangeCallbacks : [(String) -> ()] = []
    
    public var midiManager : VVMIDIManager! = Managers.midiManager
    
    
    @objc public func setupChanged() {
        
        //  midiSources.next(midiSourceNames)
        //  updateMenuItems( "device", midiSourceNames )
    }
    
    
    @objc public func receivedMIDI(_ a: [Any]!, from n: VVMIDINode!) {
        
        if let msg = a[0] as? VVMIDIMessage {
            
            let midiMsg = MidiMessage(fromVals: msg.type(), msg.channel(), msg.data1(), msg.data2(), msg.data3(), msg.timestamp())
            
            let currmsg = MidiNodeMessage( midi: midiMsg, node: n.name() )
            
            for midiInPipe in midiReceiveCallbacks {
                
                midiInPipe(currmsg)
                
            }
        }
    }
    
    
    @objc public required override init() {
        
        super.init()
        
        midiManager.setDelegate(self)
        
        enableAllMidiSources()
        
        NSLog("MIDI_CENTRAL singleton successfully created.")
        
    }
    
    
    public func addMidiReceiveCallback( _ callback: @escaping (MidiNodeMessage) -> () ) {
        
        midiReceiveCallbacks.append(callback)
        
    }
    
    
    public func addSetupChangeCallback( _ callback: @escaping (String) -> () ) {
        
        setupChangeCallbacks.append(callback)
        
    }
    
    public func sendMsg(_ m: MidiMessage, toTargetIndex: Int) {
            
        midiTargets[toTargetIndex].sendMsg( m )
    }
    
    public func sendMsg(_ m: MidiMessage, toTargetNamed: String) {
        for dest in midiTargets {
            if dest.name() == toTargetNamed {
                dest.sendMsg(m)
                return
            }
        }
    }
    
}


//  VVMIDIDelegateProtocol:
//
//     setupChanged()
//     receivedMIDI(a: NSArray, fromNode: VVMIDINode)
//
//

// MARK: extension: VVMIDIDelegateSwift


extension VVMIDIDelegateSwift {
    
    
    public var midiManager : VVMIDIManager!  {
        
        get { return Managers.midiManager     }
        
        set { Managers.midiManager = newValue }
        
    }
    
    
    internal var midiSources : [VVMIDINode] {
        
        if let mm = midiManager {
            
            var sources = [VVMIDINode]()
            
            for i in 0...mm.sourceArray().count()-1 {
                
                let vvnode = mm.sourceArray().lockObject(at: i) as! VVMIDINode
                
                sources.append( vvnode )
            }
            
            return sources
            
        }
            
        else {
            
            printLog("Couldn't access midiSource names.")
            
            return []
            
        }
        
    }
    
    
    internal var midiTargets : [VVMIDINode] {
        
        if let mm = midiManager {
            
            var targets = [VVMIDINode]()
            
            for i in 0...mm.destArray().count()-1 {
                
                let vvnode = mm.destArray().lockObject(at: i) as! VVMIDINode
                
                targets.append( vvnode )
                
              //  let node = MidiNode(receiverWithName: vvnode.name())
                
              //  if let node = MidiNode(senderWithName: vvnode.name()) {
                    
              //      targets.append( node )
                    
              //      printLog("MidiPlex:MidiManager successfully created MidiNode \(vvnode.name) from VVMIDINode object.")
              //  }
                
            }
            
            return targets
            
        }
            
        else {
            
            printLog("Couldn't access midiTarget names.")
            
            return []
            
        }
        
    }
    
    
    public var midiSourceNames : [String] { return midiSources.map { $0.name() } }
    
    public var midiTargetNames : [String] { return midiTargets.map { $0.name() } }
    
    
    
    public func enableAllMidiSources() {
        
        for i in 0..<midiSources.count {
            
            midiSources[i].setEnabled(true)
            
        }
        
        // for sourcenode in midiSources { sourcenode.setEnabled(true) }
        
    }
    
    public func enableAllMidiTargets() {
        
        for i in 0..<midiTargets.count {
            
            midiTargets[i].setEnabled(true)
            
        }
        
    }
    
}


//   printLog("MIDI message: \(msg.type) :: \(msg.lengthyDescription()) received from \(n.deviceName()) : \(n.name())")
//   printLog("MIDI message: \(msg.type) :: \(msg.lengthyDescription()) received from \(n.fullName())")

