//----------------------------------------------------------------------------------------------------
// MIDI sound module
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.smf {
    import flash.utils.ByteArray;
    import org.si.sion.*;
    import org.si.sion.sequencer.*;
    import org.si.sion.sequencer.base.*;
    
    
    /** Standard MIDI File converter */
    public class SMFDataConverter extends SiONData
    {
    // variables
    //--------------------------------------------------------------------------------
        private var _smfData:SMFData = null;
        private var _module:MIDIModule = null;
        private var _waitEvent:MMLEvent;
        private var _executors:Vector.<SMFExecutor> = new Vector.<SMFExecutor>();
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** Pass SMFData and MIDIModule */
        function SMFDataConverter(smfData:SMFData, midiModule:MIDIModule)
        {
            super();
            _smfData = smfData;
            _module = midiModule;
            
            bpm = _smfData.bpm;
            
            globalSequence.initialize();
            globalSequence.appendNewCallback(_onMIDIInitialize, 0);
            globalSequence.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
            globalSequence.appendNewCallback(_onMIDIEventCallback, 0);
            _waitEvent = globalSequence.appendNewEvent(MMLEvent.GLOBAL_WAIT, 0, 0);
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        private function _onMIDIInitialize(data:int) : MMLEvent
        {
            var i:int, imax:int;
            
            // initialize module
            _module._initialize();
            
            // initialize executors
            _executors.length = imax = _smfData.tracks.length;
            for (i=0; i<imax; i++) {
                if (!_executors[i]) _executors[i] = new SMFExecutor();
                _executors[i]._initialize(_smfData.tracks[i], _module);
            }
            
            // initialize interval
            _waitEvent.length = 0;
            return null;
        }
        
        
        private function _onMIDIEventCallback(data:int) : MMLEvent
        {
            var i:int, imax:int = _executors.length, exec:SMFExecutor, seq:Vector.<SMFEvent>, 
                ticks:int, deltaTime:int, minDeltaTime:int;
            ticks = _waitEvent.length;
            minDeltaTime = _executors[0]._execute(ticks);
            for (i=1; i<imax; i++) {
                deltaTime = _executors[i]._execute(ticks);
                if (minDeltaTime > deltaTime) minDeltaTime = deltaTime;
            }
            _waitEvent.length = minDeltaTime;
            return null;
        }
    }
}


