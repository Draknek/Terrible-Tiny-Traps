//----------------------------------------------------------------------------------------------------
// MIDI sound module
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.smf {
    import org.si.sion.*;
    import org.si.sion.sequencer.base.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    import org.si.sion.module.channels.SiOPMChannelBase;
    
    
    /** MIDI sound module */
    public class MIDIModule
    {
    // variables
    //--------------------------------------------------------------------------------
        /** voice set */
        public var voiceSet:Vector.<SiONVoice>;
        /** drum voice set */
        public var drumVoiceSet:Vector.<SiONVoice>;
        /** NRPN callback, should be function(channelNum:int, nrpn:int, dataEntry:int) : void. */
        public var onNRPN:Function = null;
        
        private var _polyphony:int;
        private var _midiChannels:Vector.<MIDIModuleChannel>;
        
        private var _freeOperators:MIDIModuleOperator;
        private var _activeOperators:MIDIModuleOperator;
        
        private var _dataEntry:int;
        private var _rpnNumber:int;
        private var _isNRPN:Boolean;
        private var _portOffset:int;
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** polyphony */
        public function get polyphony() : int { return _polyphony; }
        /** MIDI channel count */
        public function get midiChannelCount() : int { return _midiChannels.length; }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** MIDI sound module emulator
         *  @param polyphony polyphony
         *  @param midiChannelCount MIDI channel count
         */
        function MIDIModule(polyphony:int=32, midiChannelCount:int=16)
        {
            _polyphony = polyphony;
            _freeOperators = new MIDIModuleOperator(null);
            _activeOperators = new MIDIModuleOperator(null);
            _midiChannels = new Vector.<MIDIModuleChannel>(midiChannelCount, true);
            for (var ch:int=0; ch<midiChannelCount; ch++) {
                _midiChannels[ch] = new MIDIModuleChannel();
            }
            voiceSet = new Vector.<SiONVoice>(128);
            drumVoiceSet = new Vector.<SiONVoice>(128);
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** @private */
        internal function _initialize() : Boolean
        {
            var driver:SiONDriver = SiONDriver.mutex;
            if (!driver) return false;
            
            resetAllChannels();
            _freeOperators.clear();
            _activeOperators.clear();
            for (var i:int=0; i<_polyphony; i++) {
                _freeOperators.push(new MIDIModuleOperator(driver.newUserControlableTrack(i)));
            }
            
            _dataEntry = 0;
            _rpnNumber = 0;
            _isNRPN = false;
            _portOffset = 0;
            
            return true;
        }
        
        
        /** Set drum voice by sampler table 
         *  @param table sampler table class, ussualy get from SiONSoundFont
         *  @see SiONSoundFont
         */
        public function setDrumSamplerTable(table:SiOPMWaveSamplerTable) : void
        {
            var voice:SiONVoice = new SiONVoice(), i:int;
            voice.setSamplerTable(table);
            for (i=0; i<128; i++) drumVoiceSet[i] = voice;
        }
        
        
        /** set event trigger on all channels. The channel number sets as eventTriggerID.
         *  @param noteOnType Dispatching event type at note on. 0=no events, 1=NOTE_ON_FRAME, 2=NOTE_ON_STREAM, 3=both.
         *  @param noteOffType Dispatching event type at note off. 0=no events, 1=NOTE_OFF_FRAME, 2=NOTE_OFF_STREAM, 3=both.
         */
        public function setEventTrigger(noteOnType:int=1, noteOffType:int=0) : void
        {
            for (var ch:int=0; ch<_midiChannels.length; ch++) {
                _midiChannels[ch].setEventTrigger(ch, noteOnType, noteOffType);
            }
        }
        
        
        /** reset all channels */
        public function resetAllChannels() : void
        {
            for (var ch:int=0; ch<_midiChannels.length; ch++) {
                _midiChannels[ch].reset();
            }
            _midiChannels[9].drumMode = 1;
        }
        
        
        /** get MIDI channel instance */
        public function getMIDIModuleChannel(channelNum:int) : MIDIModuleChannel
        {
            return _midiChannels[channelNum+_portOffset];
        }
        
        
        /** change MIDI port */
        public function changePort(portNum:int) : void
        {
            if (_midiChannels.length > (portNum<<4)+15) _portOffset = portNum<<4;
            
        }
        
        
        /** note on */
        public function noteOn(channelNum:int, note:int, velocity:int=64) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = _midiChannels[channelNum], voice:SiONVoice, 
                ope:MIDIModuleOperator, track:SiMMLTrack, channel:SiOPMChannelBase;
            
            if (midiChannel.mute) return;
            
            // get operator
            if (midiChannel.activeOperatorCount >= midiChannel.maxOperatorCount) {
                for (ope=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                    if (ope.channel == channelNum) {
                        _activeOperators.remove(ope);
                        break;
                    }
                }
            } else {
                ope = _freeOperators.shift() || _activeOperators.shift();
            }
            
            if (ope.isNoteOn) {
                ope.sionTrack.dispatchEventTrigger(false);
                _midiChannels[ope.channel].activeOperatorCount--;
            }
            
            // voice setting
            if (midiChannel.drumMode == 0) {
                if (ope.programNumber != midiChannel.programNumber) {
                    ope.programNumber = midiChannel.programNumber;
                    voice = voiceSet[ope.programNumber];
                    if (voice) {
                        voice.updateTrackVoice(ope.sionTrack);
                    } else {
                        _freeOperators.push(ope);
                        return;
                    }
                }
            } else {
                if (drumVoiceSet[note]) {
                    drumVoiceSet[note].updateTrackVoice(ope.sionTrack);
                } else {
                    _freeOperators.push(ope);
                    return;
                }
            }
            
            // operator settings
            track = ope.sionTrack;
            channel = track.channel;
            
            track.keyOn(note);
            track.noteShift = midiChannel.masterCoarseTune;
            track.pitchShift = midiChannel.masterFineTune;
            track.pitchBend = (midiChannel.pitchBend * midiChannel.pitchBendSensitivity) >> 7; //(*64/8192)
            track.setPortament(midiChannel.portamentoTime);
            track.setEventTrigger(midiChannel.eventTriggerID, midiChannel.eventTriggerTypeOn, midiChannel.eventTriggerTypeOff);
            channel.setAllStreamSendLevels(midiChannel._sionVolumes);
            channel.offsetVolume(midiChannel.expression, velocity);
            channel.pan = midiChannel.pan;
            channel.setPitchModulation(midiChannel.modulation>>2);            // width = 32
            channel.setAmplitudeModulation(midiChannel.channelAfterTouch>>2); // width = 32
            
            ope.isNoteOn = true;
            ope.note = note;
            ope.channel = channelNum;
            _activeOperators.push(ope);
            midiChannel.activeOperatorCount++;
        }
        
        
        /** note off */
        public function noteOff(channelNum:int, note:int, velocity:int=0) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = _midiChannels[channelNum];
            if (midiChannel.mute) return;
            
            var ope:MIDIModuleOperator, i:int=0;
            for (ope=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                if (ope.note == note && ope.channel == channelNum) {
                    if (midiChannel.sustainPedal) ope.sionTrack.dispatchEventTrigger(false);
                    else ope.sionTrack.keyOff();
                    ope.isNoteOn = false;
                    midiChannel.activeOperatorCount--;
                    _activeOperators.remove(ope);
                    _freeOperators.push(ope);
                    return;
                }
            }
        }
        
        
        /** program change */
        public function programChange(channelNum:int, programNumber:int) : void
        {
            _midiChannels[channelNum + _portOffset].programNumber = programNumber;
        }
        
        
        /** channel after touch */
        public function channelAfterTouch(channelNum:int, value:int) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = _midiChannels[channelNum];
            midiChannel.channelAfterTouch = value;
            
            for (var ope:MIDIModuleOperator=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                if (ope.channel == channelNum) {
                    ope.sionTrack.channel.setAmplitudeModulation(midiChannel.channelAfterTouch>>2);
                }
            }
        }
        
        
        /** pitch bned */
        public function pitchBend(channelNum:int, bend:int) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = _midiChannels[channelNum];
            midiChannel.pitchBend = bend;
            
            for (var ope:MIDIModuleOperator=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                if (ope.channel == channelNum) {
                    ope.sionTrack.pitchBend = (midiChannel.pitchBend * midiChannel.pitchBendSensitivity) >> 7; //(*64/8192)
                }
            }
        }
        
        
        /** control change */
        public function controlChange(channelNum:int, controlerNumber:int, data:int) : void
        {
            channelNum += _portOffset;
            var midiChannel:MIDIModuleChannel = _midiChannels[channelNum];
            
            switch (controlerNumber) {
            case SMFEvent.CC_BANK_SELECT_MSB:
                midiChannel.bankNumber = (data & 0x7f) << 7;
                break;
            case SMFEvent.CC_BANK_SELECT_LSB:
                midiChannel.bankNumber |= data & 0x7f;
                break;
                
            case SMFEvent.CC_MODULATION:
                midiChannel.modulation = data;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setPitchModulation(midiChannel.modulation>>2); });
                break;
            case SMFEvent.CC_PORTAMENTO_TIME:
                midiChannel.portamentoTime = data;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.setPortament(midiChannel.portamentoTime); });
                break;

            case SMFEvent.CC_VOLUME:
                midiChannel.masterVolume = data;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
            //case SMFEvent.CC_BALANCE:
            case SMFEvent.CC_PANPOD:
                midiChannel.pan = data - 64;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.pan = midiChannel.pan; });
                break;
            case SMFEvent.CC_EXPRESSION:
                midiChannel.expression = data;
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.expression = midiChannel.expression; });
                break;
                
            case SMFEvent.CC_SUSTAIN_PEDAL:
                midiChannel.sustainPedal = (data > 64);
                break;
            case SMFEvent.CC_PORTAMENTO:
                midiChannel.portamento = (data > 64);
                break;
            //case SMFEvent.CC_SOSTENUTO_PEDAL:
            //case SMFEvent.CC_SOFT_PEDAL:
            //case SMFEvent.CC_RESONANCE:
            //case SMFEvent.CC_RELEASE_TIME:
            //case SMFEvent.CC_ATTACK_TIME:
            //case SMFEvent.CC_CUTOFF_FREQ:
            //case SMFEvent.CC_DECAY_TIME:
            //case SMFEvent.CC_PROTAMENTO_CONTROL:
            case SMFEvent.CC_REBERV_SEND:
                midiChannel.setEffectSendLevel(1, data);
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
            case SMFEvent.CC_CHORUS_SEND:
                midiChannel.setEffectSendLevel(2, data);
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
            case SMFEvent.CC_DELAY_SEND:
                midiChannel.setEffectSendLevel(3, data);
                $(function(ope:MIDIModuleOperator):void { ope.sionTrack.channel.setAllStreamSendLevels(midiChannel._sionVolumes); });
                break;
                
            case SMFEvent.CC_NRPN_MSB: _rpnNumber =  (data & 0x7f) << 7;  break;
            case SMFEvent.CC_NRPN_LSB: _rpnNumber |= (data & 0x7f); _isNRPN = true;  break;
            case SMFEvent.CC_RPN_MSB:  _rpnNumber  =  (data & 0x7f) << 7;  break;
            case SMFEvent.CC_RPN_LSB:  _rpnNumber  |= (data & 0x7f); _isNRPN = false; break;
            case SMFEvent.CC_DATA_ENTRY_MSB: _dataEntry = (data & 0x7f) << 7; break;
            case SMFEvent.CC_DATA_ENTRY_LSB:
                _dataEntry |= (data & 0x7f);
                if (_isNRPN) {
                    if (onNRPN != null) onNRPN(channelNum, _rpnNumber, _dataEntry);
                } else _onNRPN(midiChannel);
                break;
            }
            
            function $(func:Function) : void {
                for (var ope:MIDIModuleOperator=_activeOperators.next; ope!=_activeOperators; ope=ope.next) {
                    if (ope.channel == channelNum) func(ope);
                }
            }
        }
        
        
        private function _onNRPN(midiChannel:MIDIModuleChannel) : void
        {
            switch (_rpnNumber) {
            case SMFEvent.RPN_PITCHBEND_SENCE:
                midiChannel.pitchBendSensitivity = _dataEntry >> 7;
                break;
            case SMFEvent.RPN_FINE_TUNE:
                midiChannel.masterFineTune = (_dataEntry >> 7) - 64;
                break;
            case SMFEvent.RPN_COARSE_TUNE:
                midiChannel.masterCoarseTune = (_dataEntry >> 7) - 64;
                break;
            }
        }
    }
}

