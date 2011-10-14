package
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.SharedObject;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import net.flashpunk.utils.Key;
	
    // Sound stuff
    import org.si.sion.*;
    import org.si.sion.events.*;
    import org.si.sion.effector.*;
    import org.si.sion.sequencer.*;
    import org.si.sion.utils.SiONPresetVoice;
    import org.si.sound.PatternSequencer;
    import org.si.sound.patterns.Note;

	public class Audio
	{
        // Some constants
        private static const TEMPO:int = 100;
        private static const NUM_OF_PATTERNS:int = 6;
        private static const PATTERN_LENGTH:int = 64;
        private static const DEFAULT_VELOCITY:int = 64;

        // Sound driver
        private static var driver:SiONDriver = new SiONDriver();

        // Filter
        //private static var lowPassFilter:SiCtrlFilterLowPass = new SiCtrlFilterLowPass();
        //private static var filterFrequency:Number;
        //private static var filterResonance:Number;

        // Preset sound voices
        private static var presetVoice:SiONPresetVoice = new SiONPresetVoice();

        private static var beatCounter:int;

        private static var musicTensionLevel:int = -1;

        private static var patternChanged:Boolean = false;

        private static var drumsPatternArray:Vector.<SiONData> =
                new Vector.<SiONData>(NUM_OF_PATTERNS, true);
        private static var drumsArePlaying:Boolean = false;

        private static var bassPatternSequencer:PatternSequencer = new PatternSequencer(32);
        private static var bassPatternArray:Vector.<Vector.<Note>> =
                new Vector.<Vector.<Note>>(NUM_OF_PATTERNS, true);

        private static var leadPatternSequencer:PatternSequencer = new PatternSequencer(32);
        private static var leadPatternArray:Vector.<Vector.<Note>> = 
                new Vector.<Vector.<Note>>(NUM_OF_PATTERNS, true);

        private static var _leadSequencerPortamento:Boolean = false;

		private static var jump:SfxrSynth;
		private static var death:SfxrSynth;
		private static var target:SfxrSynth;
		private static var bounce:SfxrSynth;
		
        private static var _enabled:Boolean = true;
		private static var _mute:Boolean = false;
		private static var so:SharedObject;
		private static var menuItem:ContextMenuItem;
		
		public static function init (o:InteractiveObject):void
		{
			// Setup
			
			so = SharedObject.getLocal("audio", "/");
			
			_mute = so.data.mute;

			addContextMenu(o);
			
			if (o.stage) {
				addKeyListener(o.stage);
			} else {
				o.addEventListener(Event.ADDED_TO_STAGE, stageAdd);
			}
			
			// Create sounds
			
			jump = new SfxrSynth()
			jump.setSettingsString("0,,0.19,,0.23,0.347,,0.252,,,,,,0.285,,,,,0.67,,,0.099,,0.15");
			jump.cacheMutations(4);
			
			death = new SfxrSynth();
			death.setSettingsString("3,,0.289,0.42,0.36,0.061,,,,,,,,,,0.491,0.222,-0.086,1,,,,,0.4");
			death.cacheMutations(4);
			
			target = new SfxrSynth();
			//target.setSettingsString("1,0.072,0.009,,0.51,0.374,0.034,0.139,,0.596,0.542,0.013,,0.047,0.015,,0.014,0.021,1,,0.025,,,0.3");
			target.setSettingsString("2,0.072,0.05,,0.51,0.55,0.034,0.08,0.179,0.596,0.542,0.013,,0.047,0.015,,0.014,0.021,0.91,,0.025,,,0.3");
			target.cacheMutations(4);
			
			bounce = new SfxrSynth();
			bounce.setSettingsString("0,,0.031,,0.23,0.26,,-0.35,,,,,,0.493,,,,,0.77,,,0.49,,0.26");
			bounce.cacheMutations(4);

            //---------------------------------
            //       DRUM/RHYTHM TRACK
            //---------------------------------

            var drumsMML:Vector.<String> = new Vector.<String>(NUM_OF_PATTERNS, true);  
            // Pattern one:
            //             Inst|Pan|Vol|Oct|Sequence
            drumsMML[0] =  "%6@1    v15 o3  $c2 c2;";                  // Kick pattern (voice 1)

            // Pattern two:
            //             Inst|Pan|Vol|Oct|Sequence
            drumsMML[1] =  "%6@1    v15 o3  $c4 c4 c4 c4;";            // Kick pattern (voice 1)
            drumsMML[1] += "%6@3 p2 v5      $c8 c8 c8 c8 c8 c8 c8 c8;";   // Closed Hat pattern (voice 3)

            // Pattern three:
            //             Inst|Pan|Vol|Oct|Sequence
            drumsMML[2] =  "%6@1    v15 o3  $c8 c8 c4 c4 c8 c8;";          // Kick pattern (voice 1)
            drumsMML[2] += "%6@3 p2 v5      $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)

            // Pattern four:
            //             Inst|Pan|Vol|Oct|Sequence
            drumsMML[3] =  "%6@1    v15 o3  $c8 c8 c4 c4 c8 c8;";          // Kick pattern (voice 1)
            drumsMML[3] += "%6@3 p2 v5      $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            drumsMML[3] += "%6@4 p6 v7  o3  $r8 c8 r8 c16 c16 c16 r16 r16 c16 r16 r16 c16 r16;"; // Open Hat pattern

            // Pattern five:
            //             Inst|Pan|Vol|Oct|Sequence
            drumsMML[4] =  "%6@1    v15 o3  $c8 c8 c4 c4 c8 c8;";          // Kick pattern (voice 1)
            drumsMML[4] += "%6@2    v15 o3  $r c r c;";                // Snare pattern (voice 2)
            drumsMML[4] += "%6@3 p2 v5      $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            drumsMML[4] += "%6@4 p6 v7  o3  $r8 c8 r8 c16 c16 c16 r16 r16 c16 r16 r16 c16 r16;"; // Open Hat pattern
            drumsMML[4] += "%6@6 p6 v1  o4  $e1 d2 e4 d4;";   // First organ track
            drumsMML[4] += "%6@6 p2 v1  o4  $a1 g2 g4 g4;";   // Second organ track
            drumsMML[4] += "%6@6    v1  o5  $c1>b2 b4 b4<;";   // Second organ track

            // Pattern six:
            //             Inst|Pan|Vol|Oct|Sequence
            drumsMML[5] =  "%6@1    v15 o3  $c16 c16 c16 c16 c4 c16 c16 c16 c16 c4;"; // Kick pattern (voice 1)
            drumsMML[5] += "%6@2    v15 o3  $r c r c;";                               // Snare pattern (voice 2)
            drumsMML[5] += "%6@3 p2 v5      $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            drumsMML[5] += "%6@4 p6 v7  o3  $[r8 c8 r8 c8];";                         // Open Hat pattern (voice 4)
            drumsMML[5] += "%6@5    v11 o4  $[a16 r16 r8 a16 r16 r8];";               // Percussion (voice 5)
            drumsMML[5] += "%6@6 p6 v1  o4  $[r8 e8]4  [r8 d8] r8 e8 r8 d8 ;";        // First organ track
            drumsMML[5] += "%6@6 p2 v1  o4  $[r8 a8]4  [r8 g8] r8 g8 r8 g8 ;";        // Second organ track
            drumsMML[5] += "%6@6    v1  o5  $[r8 c8]4 >[r8 b8] r8 b8 r8 b8<;";        // Third organ track

            // Compile the MML and set the voices for each instrument
            var percusVoices:Array = presetVoice["valsound.percus"];

            for(var i:int = 0; i < drumsPatternArray.length; i++)
            {
                drumsPatternArray[i] = driver.compile(drumsMML[i]);
                drumsPatternArray[i].setVoice(1, percusVoices[1]);  // kick
                drumsPatternArray[i].setVoice(2, percusVoices[27]); // snare
                drumsPatternArray[i].setVoice(3, percusVoices[16]); // closed hihat
                drumsPatternArray[i].setVoice(4, percusVoices[21]); // open hihat
                drumsPatternArray[i].setVoice(5, presetVoice["midi.percus4"]); // some kind of block?
                drumsPatternArray[i].setVoice(6, presetVoice["valsound.lead8"]); // An organ
            }
            trace("drumsPatternArray length is", drumsPatternArray.length);



            //---------------------------------
            //         BASS TRACK
            //---------------------------------
            // The array of different patterns
            for (var bassPatternIndex:int = 0; bassPatternIndex < bassPatternArray.length; bassPatternIndex++)
                bassPatternArray[bassPatternIndex] = new Vector.<Note>(PATTERN_LENGTH/2, true);

            // Pattern 1
            bassPatternArray[0][0]  = new Note(33, DEFAULT_VELOCITY, 31);
            
            // Pattern 2
            bassPatternArray[1][0]  = new Note(33, DEFAULT_VELOCITY, 15);
            bassPatternArray[1][16] = new Note(28, DEFAULT_VELOCITY, 7); 
            bassPatternArray[1][24] = new Note(31, DEFAULT_VELOCITY, 7); 
                                                   
            // Pattern 3
            bassPatternArray[2][0]  = new Note(33, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][1]  = new Note(33, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][3]  = new Note(33, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][4]  = new Note(36, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][5]  = new Note(33, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][6]  = new Note(40, DEFAULT_VELOCITY, 2);             
            bassPatternArray[2][8]  = new Note(33, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][9]  = new Note(33, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][11] = new Note(33, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][12] = new Note(40, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][13] = new Note(33, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][14] = new Note(45, DEFAULT_VELOCITY, 2);             
            bassPatternArray[2][16] = new Note(31, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][17] = new Note(31, DEFAULT_VELOCITY, 1);             
            bassPatternArray[2][31] = new Note(33, DEFAULT_VELOCITY, 1); 

            // Pattern 4
            bassPatternArray[3][0]  = new Note(45, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][1]  = new Note(45, DEFAULT_VELOCITY, 1); 

            bassPatternArray[3][3]  = new Note(45, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][4]  = new Note(43, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][5]  = new Note(43, DEFAULT_VELOCITY, 1); 

            bassPatternArray[3][7]  = new Note(43, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][8]  = new Note(40, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][9]  = new Note(40, DEFAULT_VELOCITY, 1); 

            bassPatternArray[3][11] = new Note(39, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][12] = new Note(38, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][13] = new Note(38, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][14] = new Note(36, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][15] = new Note(35, DEFAULT_VELOCITY, 1); 
            bassPatternArray[3][16] = new Note(33, DEFAULT_VELOCITY, 15); 
            bassPatternArray[3][31] = new Note(33, DEFAULT_VELOCITY, 1); 

            // Pattern 5
            bassPatternArray[4][0]  = new Note(33, DEFAULT_VELOCITY, 2); 
            bassPatternArray[4][2]  = new Note(28, DEFAULT_VELOCITY, 1); 
            bassPatternArray[4][3]  = new Note(31, DEFAULT_VELOCITY, 1); 
            bassPatternArray[4][4]  = new Note(33, DEFAULT_VELOCITY, 2); 
            bassPatternArray[4][6]  = new Note(28, DEFAULT_VELOCITY, 1); 
            bassPatternArray[4][7]  = new Note(31, DEFAULT_VELOCITY, 1); 
            bassPatternArray[4][8]  = new Note(33, DEFAULT_VELOCITY, 2); 
            bassPatternArray[4][16] = new Note(31, DEFAULT_VELOCITY, 2); 
            bassPatternArray[4][24] = new Note(28, DEFAULT_VELOCITY, 4); 
            bassPatternArray[4][26] = new Note(40, DEFAULT_VELOCITY, 2); 
            bassPatternArray[4][27] = new Note(35, DEFAULT_VELOCITY, 2); 
            bassPatternArray[4][28] = new Note(31, DEFAULT_VELOCITY, 4); 
            bassPatternArray[4][30] = new Note(43, DEFAULT_VELOCITY, 2); 
            bassPatternArray[4][31] = new Note(40, DEFAULT_VELOCITY, 2); 

            // Pattern 6
            bassPatternArray[5] = bassPatternArray[4].concat();

            // Set the volume
            bassPatternSequencer.volume = 0.9;

            // Set the voice
            bassPatternSequencer.voice = presetVoice["valsound.bass46"];


            //---------------------------------
            //         LEAD TRACK
            //---------------------------------
            // Pattern Arrays
            for (var leadPatternIndex:int = 0; leadPatternIndex < leadPatternArray.length; leadPatternIndex++)
                leadPatternArray[leadPatternIndex] = new Vector.<Note>(PATTERN_LENGTH, true);

            // Pattern 1
            // Nothing!

            // Pattern 2
            leadPatternArray[1][0]  = new Note(45, DEFAULT_VELOCITY, 4); 
            leadPatternArray[1][16] = new Note(43, DEFAULT_VELOCITY, 4); 

            leadPatternArray[1][32] = new Note(45, DEFAULT_VELOCITY, 4); 
            leadPatternArray[1][44] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][46] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][48] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][50] = new Note(38, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][52] = new Note(39, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][54] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][56] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][58] = new Note(38, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][60] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[1][62] = new Note(44, DEFAULT_VELOCITY, 2); 

            // Pattern 3
            leadPatternArray[2][2]  = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][6]  = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][10] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][20] = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][22] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][24] = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][26] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][28] = new Note(43, DEFAULT_VELOCITY, 4); 

            leadPatternArray[2][34] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][38] = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][42] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][52] = new Note(50, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][54] = new Note(52, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][56] = new Note(55, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][58] = new Note(57, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][60] = new Note(55, DEFAULT_VELOCITY, 4); 

            // pattern 4
            leadPatternArray[3][2]  = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][6]  = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][10] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][14] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][18] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][22] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][26] = new Note(43, DEFAULT_VELOCITY, 6); 

            leadPatternArray[3][34] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][38] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][42] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][46] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][50] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][54] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][58] = new Note(44, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][62] = new Note(44, DEFAULT_VELOCITY, 2); 

            // Pattern 5
            leadPatternArray[4][4]  = new Note(48, DEFAULT_VELOCITY, 4);
            leadPatternArray[4][20] = new Note(47, DEFAULT_VELOCITY, 4);
            leadPatternArray[4][26] = new Note(47, DEFAULT_VELOCITY, 2);
            leadPatternArray[4][30] = new Note(43, DEFAULT_VELOCITY, 2);

            leadPatternArray[4][36] = new Note(48, DEFAULT_VELOCITY, 4);
            leadPatternArray[4][52] = new Note(50, DEFAULT_VELOCITY, 4);
            leadPatternArray[4][58] = new Note(52, DEFAULT_VELOCITY, 2);
            leadPatternArray[4][62] = new Note(55, DEFAULT_VELOCITY, 2);

            // Pattern 6
            leadPatternArray[5][2]  = new Note(51, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][3]  = new Note(50, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][4]  = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][6]  = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][8]  = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][18] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][20] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][22] = new Note(50, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][24] = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][26] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][28] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][30] = new Note(42, DEFAULT_VELOCITY, 2); 

            leadPatternArray[5][32] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][34] = new Note(51, DEFAULT_VELOCITY, 1);
            leadPatternArray[5][35] = new Note(50, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][36] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][38] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][40] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[5][49] = new Note(45, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][50] = new Note(48, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][51] = new Note(50, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][52] = new Note(48, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][53] = new Note(50, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][54] = new Note(53, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][55] = new Note(55, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][56] = new Note(52, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][57] = new Note(55, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][58] = new Note(57, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][59] = new Note(59, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][60] = new Note(55, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][61] = new Note(57, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][62] = new Note(59, DEFAULT_VELOCITY, 1); 
            leadPatternArray[5][63] = new Note(67, DEFAULT_VELOCITY, 1); 

            // Set up the volume
            leadPatternSequencer.volume = 0.8;

            // Set the voice
            leadPatternSequencer.voice = presetVoice["valsound.lead37"];


            //------------------------------
            //      LOW PASS FILTER (currently not working)
            //------------------------------
            // Set default values
            //lowPassFilter.control(1, 0.5);

            // Add the effect to the driver
            //driver.effector.slot0 = [lowPassFilter];

            // Set up listeners for the beat
            driver.setBeatCallbackInterval(1);
            driver.setTimerInterruption(1, onTimerInterruption);
            //driver.addEventListener(SiONEvent.STREAM, onStream);

            //startDriver();
		}
		
		public static function play (sound:String):void
		{
			if (! _mute) {
				Audio[sound].playCachedMutation();
			}
		}

        public static function setTargetsRemaining(newValue:int):void
        {
            var newMusicTensionLevel:int;

            switch (newValue)
            {
                case -1:
                    newMusicTensionLevel = -1;
                    break;
                case 0:
                case 1:
                    newMusicTensionLevel = 0;
                    break;
                case 2:
                case 3:
                case 4:
                    newMusicTensionLevel = 1;
                    break;
                case 5:
                case 6:
                case 7:
                    newMusicTensionLevel = 2;
                    break;
                case 8:
                case 9:
                    newMusicTensionLevel = 3;
                    break;
                case 10:
                    newMusicTensionLevel = 4;
                    break;
                case 11:
                    newMusicTensionLevel = 5;
                    break;
            }

            if (musicTensionLevel == newMusicTensionLevel) return;

            musicTensionLevel = newMusicTensionLevel;

            if (!driver.isPlaying)
                startDriver();

            patternChanged = true;
            trace("music incrementing to ", musicTensionLevel);
        }

        // REMOVE:
        public static function incrementMusicTensionLevel():void
        {
            musicTensionLevel++;

            if (musicTensionLevel > NUM_OF_PATTERNS-1)
                musicTensionLevel = 0;

            if (!driver.isPlaying)
                startDriver();

            patternChanged = true;
            trace("music incrementing to ", musicTensionLevel);
        }

        //public static function setFilterXY(x:Number, y:Number):void
        //{
        //    filterFrequency = x;
        //    filterResonance = y;
        //    trace("filter set to:", x, y);
        //}

        // Getter and setter for portamento property
        public static function get portamento (): Boolean {return _leadSequencerPortamento;}

        public static function set portamento (newValue:Boolean): void
        {
            if (_leadSequencerPortamento == newValue) return;

            _leadSequencerPortamento = newValue;

            // Set portamento
            leadPatternSequencer.portament = _leadSequencerPortamento ? 1: 0;
        }

		
		// Getter and setters for mute and enabled properties

        public static function get enabled ():Boolean { return _enabled;}

        public static function set enabled (newValue:Boolean):void
        {
            if (_enabled == newValue) return;

            _enabled = newValue;

            if (!_enabled)
            {
                stopAllDriverSequences();
                drumsArePlaying = false;
                bassPatternSequencer.stop();
                leadPatternSequencer.stop();
                driver.stop();
            }
            else if (_enabled && !_mute)
            {
                startDriver();
            }

            trace(_enabled ? "Audio enabled!" : "Audio disabled!");
        }
		
		public static function get mute (): Boolean { return _mute; }
		
		public static function set mute (newValue:Boolean): void
		{
			if (_mute == newValue) return;
			
			_mute = newValue;

            if (_mute)
            {
                stopAllDriverSequences();
                drumsArePlaying = false;
                bassPatternSequencer.stop();
                leadPatternSequencer.stop();
                driver.stop();
            }
            else if (!_mute && _enabled)
            {
                startDriver();
            }
			
			menuItem.caption = _mute ? "Unmute" : "Mute";
			
			so.data.mute = _mute;
			so.flush();

            trace(_mute ? "Audio muted!" : "Audio unmuted!");
		}

		
		// Implementation details

        //private static function onStream(e:SiONEvent):void
        //{
        //    lowPassFilter.control(filterFrequency, filterResonance);
        //}

        private static function startDriver():void
        {
            // Start the driver at the right tempo
            beatCounter = 0;
            driver.play("t" + TEMPO.toString() + ";", false);
        }

        // That's right, gentlemen, onBeat is NOT timing-accurate.
        // Instead we use this, whatever this is.
        private static function onTimerInterruption():void
        {
            // This line gets us a 0 to 32 index of the current bar
            var beatIndex:int = beatCounter % 32;
            //trace(beatIndex);

            // Only do this stuff at the start of a pattern.
            if (beatIndex % PATTERN_LENGTH == 0)
            {
                if (patternChanged)
                {
                    patternChanged = false;

                    if (musicTensionLevel == -1) // no targets got yet
                    {
                        stopAllDriverSequences();
                        driver.sequenceOn(new SiONData());
                        drumsArePlaying = true;
                        bassPatternSequencer.sequencer.pattern = new Vector.<Note>(32, false);
                        leadPatternSequencer.sequencer.pattern = new Vector.<Note>(32, false);
                    }
                    else
                    {
                        stopAllDriverSequences();
                        driver.sequenceOn(drumsPatternArray[musicTensionLevel]);
                        drumsArePlaying = true;
                        bassPatternSequencer.sequencer.pattern = bassPatternArray[musicTensionLevel];
                        leadPatternSequencer.sequencer.pattern = leadPatternArray[musicTensionLevel];
                    }
                    trace("pattern changed!");
                }

                // Play if necessary and not muted
                if (!_mute && _enabled)
                {
                    if (!bassPatternSequencer.isPlaying)
                    {
                        bassPatternSequencer.play();
                    }

                    if (!leadPatternSequencer.isPlaying)
                        leadPatternSequencer.play();

                    if (!drumsArePlaying)
                    {
                        stopAllDriverSequences();
                        if (musicTensionLevel == -1) // no targets got yet
                            driver.sequenceOn(new SiONData());
                        else
                            driver.sequenceOn(drumsPatternArray[musicTensionLevel]);
                        drumsArePlaying = true;
                        trace("drumsArePlaying =", drumsArePlaying);
                    }
                }
            }
            beatCounter++;
        }

        private static function stopAllDriverSequences():void
        {
            // Waarrgh kill all the sequences
            // I can't find a good way to know what's going on,
            // so I'm hacking it and killing everything (it is
            // half 3 in the AM, you know)
            for(var i:int = 0; i < 64; i++)
            {
                driver.sequenceOff(i);
            }
        }

		private static function stageAdd (e:Event):void
		{
			addKeyListener(e.target.stage);
		}
		
		private static function addContextMenu (o:InteractiveObject):void
		{
			var menu:ContextMenu = o.contextMenu || new ContextMenu;
			
			menu.hideBuiltInItems();
			
			menuItem = new ContextMenuItem(_mute ? "Unmute" : "Mute");
			
			menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuListener);
			
			menu.customItems.push(menuItem);
			
			o.contextMenu = menu;
		}
		
		private static function addKeyListener (stage:Stage):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
		}
		
		private static function keyListener (e:KeyboardEvent):void
		{
			if (e.keyCode == Key.M) {
				mute = ! mute;
			}
		}
		
		private static function menuListener (e:ContextMenuEvent):void
		{
			mute = ! mute;
		}
	}
}

