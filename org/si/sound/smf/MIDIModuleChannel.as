//----------------------------------------------------------------------------------------------------
// MIDI sound module operator
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.smf {
    import org.si.sion.*;
    import org.si.sion.sequencer.*;
    
    
    /** MIDI sound module channel */
    public class MIDIModuleChannel
    {
    // variables
    //--------------------------------------------------------------------------------
        /** active operator count of this channel */
        public var activeOperatorCount:int;
        /** maximum operator limit of this channel */
        public var maxOperatorCount:int;
        
        public var drumMode:int;
        public var mute:Boolean;
        public var programNumber:int;
        public var expression:int;
        public var pan:int;
        public var modulation:int;
        public var pitchBend:int;
        public var channelAfterTouch:int;
        public var sustainPedal:Boolean;
        public var portamento:Boolean;
        public var portamentoTime:int;
        public var masterFineTune:int;
        public var masterCoarseTune:int;
        public var pitchBendSensitivity:int;
        
        public var bankNumber:int;
        
        /** @private */
        internal var _sionVolumes:Vector.<int> = new Vector.<int>(8);
        /** @private */
        internal var _effectSendLevels:Vector.<int> = new Vector.<int>(8);
        
        public var eventTriggerID:int;
        public var eventTriggerTypeOn:int;
        public var eventTriggerTypeOff:int;
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** master volume (0-127) */
        public function get masterVolume() : int { return _effectSendLevels[0]; }
        public function set masterVolume(v:int) : void {
            _sionVolumes[0] = _effectSendLevels[0] = v;
            for (var i:int =1; i<8; i++) {
                _sionVolumes[i] = (v * _effectSendLevels[i] + 64) >> 7;
            }
        }
        
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** @private */
        function MIDIModuleChannel()
        {
            reset();
            eventTriggerID = 0;
            eventTriggerTypeOn = 0;
            eventTriggerTypeOff = 0;
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** reset this channel */
        public function reset() : void
        {
            activeOperatorCount = 0;
            maxOperatorCount = 1024;
            
            mute = false;
            drumMode = 0;
            programNumber = 0;
            expression = 128;
            pan = 0;
            modulation = 0;
            pitchBend = 0;
            channelAfterTouch = 0;
            sustainPedal = false;
            portamento = false;
            portamentoTime = 0;
            masterFineTune = 0;
            masterCoarseTune = 0;
            pitchBendSensitivity = 2;
            
            bankNumber = 0;
            
            _sionVolumes[0] = 64;
            _effectSendLevels[0] = 64;
            for (var i:int = 1; i<8; i++) {
                _sionVolumes[i] = 0;
                _effectSendLevels[i] = 0;
            }
        }
        
        
        /** set event trigger
         *  @param id Event trigger ID of this track. This value can be refered from SiONTrackEvent.eventTriggerID.
         *  @param noteOnType Dispatching event type at note on. 0=no events, 1=NOTE_ON_FRAME, 2=NOTE_ON_STREAM, 3=both.
         *  @param noteOffType Dispatching event type at note off. 0=no events, 1=NOTE_OFF_FRAME, 2=NOTE_OFF_STREAM, 3=both.
         *  @see org.si.sion.events.SiONTrackEvent
         */
        public function setEventTrigger(id:int, noteOnType:int=1, noteOffType:int=0) : void
        {
            eventTriggerID = id;
            eventTriggerTypeOn = noteOnType;
            eventTriggerTypeOff = noteOffType;
        }
        
        
        /** get effect send level 
         *  @param slotNumber effect slot number (1-8)
         *  @return effect send level
         */
        public function getEffectSendLevel(slotNumber:int) : int { 
            return _effectSendLevels[slotNumber];
        }
        
        
        /** set effect send level 
         *  @param slotNumber effect slot number (1-8)
         *  @param level effect send level (0-127)
         */
        public function setEffectSendLevel(slotNumber:int, level:int) : void {
            _effectSendLevels[slotNumber] = level;
            _sionVolumes[slotNumber] = (_effectSendLevels[0] * _effectSendLevels[slotNumber] + 64) >> 7;
        }
    }
}

