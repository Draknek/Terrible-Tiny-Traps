//----------------------------------------------------------------------------------------------------
// class for SiOPM samplers wave
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import flash.media.Sound;
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.utils.SiONUtil;
    
    
    /** SiOPM samplers wave data */
    public class SiOPMWaveSamplerData extends SiOPMWaveBase
    {
    // constant
    //----------------------------------------
        /** length borderline for extracting Sound [ms] */
        static public var extractThreshold:int = 4000;
        
        
        
    // valiables
    //----------------------------------------
        /** Is extracted ? */
        public var isExtracted:Boolean;
        /** Sound data */
        public var soundData:Sound;
        /** Wave data */
        public var waveData:Vector.<Number>;
        /** channel count of this data. */
        public var channelCount:int;
        /** pan [-64 - 64] */
        public var pan:int;
        
        // wave starting position in sample count.
        private var _startPoint:int;
        // wave end position in sample count.
        private var _endPoint:int;
        // wave looping position in sample count. -1 means no repeat.
        private var _loopPoint:int;
        // flag to slice after loading
        private var _sliceAfterLoading:Boolean;
        // flag to ignore note off
        private var _ignoreNoteOff:Boolean;
        
        
        
    // properties
    //----------------------------------------
        /** Sammple length */
        public function get length() : int {
            if (isExtracted) return (waveData.length >> (channelCount-1));
            if (soundData) return (soundData.length * 44.1);
            return 0;
        }
        
        
        /** flag to ignore note off. set true to ignore note off (one shot voice). this flag is only available for non-loop samples. */
        public function get ignoreNoteOff() : Boolean { return _ignoreNoteOff; }
        public function set ignoreNoteOff(b:Boolean) : void {
            _ignoreNoteOff = (_loopPoint == -1) && b;
        }
        
        
        /** wave starting position in sample count. you can set this property by slice(). @see #slice() */
        public function get startPoint() : int { return _startPoint; }
        
        /** wave end position in sample count. you can set this property by slice(). @see #slice() */
        public function get endPoint()   : int { return _endPoint; }
        
        /** wave looping position in sample count. -1 means no repeat. you can set this property by slice(). @see #slice() */
        public function get loopPoint()  : int { return _loopPoint; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound is extracted when the length is shorter than SiOPMWaveSamplerData.extractThreshold[msec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param pan pan of this sample [-64 - 64].
         *  @param srcChannelCount channel count of source data, this argument is only available when data type is Vector.<Number>.
         *  @param channelCount channel count of this data, 0 sets same with srcChannelCount
         */
        function SiOPMWaveSamplerData(data:*=null, ignoreNoteOff:Boolean=false, pan:int=0, srcChannelCount:int=2, channelCount:int=0) 
        {
            super(SiMMLTable.MT_SAMPLE);
            if (data) initialize(data, ignoreNoteOff, pan, srcChannelCount, channelCount);
        }
        
        
        
        
    // oprations
    //----------------------------------------
        /** initialize 
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound is extracted when the length is shorter than SiOPMWaveSamplerData.extractThreshold[msec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param pan pan of this sample.
         *  @param srcChannelCount channel count of source data, this argument is only available when data type is Vector.<Number>.
         *  @param channelCount channel count of this data, 0 sets same with srcChannelCount. This argument is ignored when the data is not extracted.
         *  @see #extractThreshold
         *  @return this instance.
         */
        public function initialize(data:*, ignoreNoteOff:Boolean=false, pan:int=0, srcChannelCount:int=2, channelCount:int=0) : SiOPMWaveSamplerData
        {
            _sliceAfterLoading = false;
            srcChannelCount = (srcChannelCount == 1) ? 1 : 2;
            if (channelCount == 0) channelCount = srcChannelCount;
            this.channelCount = (channelCount == 1) ? 1 : 2;
            if (data is Vector.<Number>) {
                this.soundData = null;
                this.waveData = _transChannel(data, srcChannelCount, channelCount);
                isExtracted = true;
            } else if (data is Sound) {
                _listenSoundLoadingEvents(data as Sound)
            } else if (data == null) {
                this.soundData = null;
                this.waveData = null;
                isExtracted = false;
            } else {
                throw new Error("SiOPMWaveSamplerData; not suitable data type");
            }
            
            this._startPoint = 0;
            this._endPoint   = length;
            this._loopPoint  = -1;
            this.ignoreNoteOff = ignoreNoteOff;
            this.pan = pan;
            return this;
        }
        
        
        /** Slicer setting. You can cut samples and set repeating.
         *  @param startPoint slicing point to start data.The negative value skips head silence.
         *  @param endPoint slicing point to end data. The negative value plays whole data.
         *  @param loopPoint slicing point to repeat data. The negative value sets no repeat.
         *  @return this instance.
         */
        public function slice(startPoint:int=-1, endPoint:int=-1, loopPoint:int=-1) : SiOPMWaveSamplerData
        {
            _startPoint = startPoint;
            _endPoint = endPoint;
            _loopPoint = loopPoint;
            if (!_isSoundLoading) _slice();
            else _sliceAfterLoading = true;
            return this;
        }
        
        
        /** Get initial sample index. 
         *  @param phase Starting phase, ratio from start point to end point(0-1).
         */
        public function getInitialSampleIndex(phase:Number=0) : int
        {
            return int(_startPoint*(1-phase) + _endPoint*phase);
        }
        
        
        // seek head silence
        private function _seekHeadSilence() : int
        {
            if (waveData) {
                var i:int=0, imax:int=waveData.length;
                for (i=0; i<imax; i+=channelCount) if (waveData[i] > 0.01) break;
                return i;
            }
            return (soundData) ? SiONUtil.getHeadSilence(soundData) : 0;
        }
        
        
        // seek mp3 end gap
        private function _seekEndGap() : int
        {
            if (waveData) {
                for (var i:int=waveData.length-channelCount; i>=0; i-=channelCount) if (waveData[i] > 0.01) break;
                return i;
            }
            return (soundData) ? SiONUtil.getEndGap(soundData) : 0;
        }
        
        
        private function _transChannel(src:Vector.<Number>, srcChannelCount:int, channelCount:int) : Vector.<Number>
        {
            var i:int, j:int, imax:int, dst:Vector.<Number>;
            if (srcChannelCount == channelCount) return src;
            if (srcChannelCount == 1) { // 1->2
                imax = src.length;
                dst = new Vector.<Number>(imax<<1);
                for (i=0, j=0; i<imax; i++, j+=2) dst[j+1] = dst[j] = src[i];
            } else { // 2->1
                imax = src.length>>1;
                dst = new Vector.<Number>(imax);
                for (i=0, j=0; i<imax; i++, j+=2) dst[i] = (src[j] + src[j+1]) * 0.5;
            }
            return dst;
        }
        
        
        /** @private */
        override protected function _onSoundLoadingComplete(sound:Sound) : void 
        {
            this.soundData = sound;
            if (this.soundData.length <= extractThreshold) {
                this.waveData = SiONUtil.extract(this.soundData, null, channelCount, extractThreshold*45, 0);
                isExtracted = true;
            } else {
                this.waveData = null;
                isExtracted = false;
            }
            if (_sliceAfterLoading) _slice();
            _sliceAfterLoading = false;
        }
        
        
        private function _slice() : void
        {
            if (_startPoint < 0) _startPoint = _seekHeadSilence();
            if (_loopPoint < 0) _loopPoint = -1;
            if (_endPoint < 0) _endPoint = length - 1;
            if (_endPoint < _loopPoint) _loopPoint = -1;
            if (_endPoint < _startPoint) _endPoint = length - 1;
            if (_loopPoint != -1) _ignoreNoteOff = false;
        }
    }
}

