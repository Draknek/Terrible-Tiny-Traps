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
        private static const NUM_OF_PATTERNS:int = 7;
        private static const PATTERN_LENGTH:int = 64;
        private static const DEFAULT_VELOCITY:int = 64;

        private static var prevTargetsRemaining:int = -1;

        // Sound driver
        private static var driver:SiONDriver = new SiONDriver();

        // Preset sound voices
        private static var presetVoice:SiONPresetVoice = new SiONPresetVoice();

        private static var beatCounter:int;

        private static var musicTensionLevel:int = 0;

        private static var patternChanged:Boolean = false;
        private static var rhythmToChange:Boolean = false;
        private static var leadToUnmute:Boolean = false;

        private static var rhythmPatternArray:Vector.<SiONData> =
                new Vector.<SiONData>(NUM_OF_PATTERNS, true);
        private static var rhythmIsPlaying:Boolean = false;

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
            //       RHYTHM TRACK
            //---------------------------------

            var rhythmMML:Vector.<String> = new Vector.<String>(NUM_OF_PATTERNS, true);  
            // Pattern one:
            //              Inst|Pan|Vol|Oct|Sequence
            //rhythmMML[0] =  "%6@1    v15 o3  $c2 c2;";                  // Kick pattern (voice 1)
            rhythmMML[0]  = "%6@7    v10 o2  $a1&a1 r1 r1;";              // Bass pattern (voice 7)

            // Pattern two:
            //              Inst|Pan|Vol|Oct|Sequence
            rhythmMML[1] =  "%6@1    v15 o3  $c2 c2;";            // Kick pattern (voice 1)
            //rhythmMML[1] += "%6@3 p2 v5      $c8 c8 c8 c8 c8 c8 c8 c8;";// Closed Hat pattern (voice 3)
            rhythmMML[1] += "%6@7    v10 o2  $a1 e2 g2;";               // Bass pattern (voice 7)

            // Pattern three:
            //              Inst|Pan|Vol|Oct|Sequence
            rhythmMML[2] =  "%6@1    v15 o3  $c8 c8 c4 c4 c8 c8;";               // Kick pattern (voice 1)
            rhythmMML[2] += "%6@3 p2 v5      $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            rhythmMML[2] += "%6@7    v10 o2  $a16 a16 r16 a16<c16>a16<e8>a16 a16 r16 a16<e16>a16<a8>"; // bar one
            rhythmMML[2] +=                  "g16 g16 r8^2 g16 g16 r8";         // bar two -- Bass pattern (voice 7)
            rhythmMML[2] +=                  "a16 a16 r16 a16<c16>a16<e8>a16 a16 r16 a16<e16>a16<a8>"; // bar three 
            rhythmMML[2] +=                  "g16 g16 r8 g16 g16 r8 g16 g16 r8 g16 g16 r8;"; // bar four

            // Pattern four:
            //              Inst|Pan|Vol|Oct|Sequence
            rhythmMML[3] =  "%6@1    v15 o3  $c8 c8 c4 c4 c8 c8;";               // Kick pattern (voice 1)
            rhythmMML[3] += "%6@2 p3 v5  o3  $r1^2^4^8 c8;";         // Snare (voice 2)
            rhythmMML[3] += "%6@3 p2 v5      $[c8 c8 c8 c8];";   // Closed Hat pattern (voice 3)
            rhythmMML[3] += "%6@4 p6 v7  o3  $r8 c8 r8 c16 c16 c16 r16 r16 c16 r16 r16 c16 r16;"; // Open Hat pattern
            rhythmMML[3] += "%6@7    v10 o2  $a16<a16 r16 a16>g16<g16 r16 g16>e16<e16 r16 e-16>d16<d16>c16<c16";
            rhythmMML[3] +=                  ">a2^4 g16 g16 r16 a16";          // Bass pattern (voice 7)
            rhythmMML[3] +=                  "a16<a16 r16 a16>g16<g16 r16 g16>e16<e16 r16 e-16>d16<d16>e-16<e-16";
            rhythmMML[3] +=                  ">e2 e8<e8>g8<g8>;";          // Bass pattern (voice 7)

            // Pattern five:
            //              Inst|Pan|Vol|Oct|Sequence
            rhythmMML[4] =  "%6@1    v15 o3  $c8 c8 c4 c4 c8 c8;";               // Kick pattern (voice 1)
            rhythmMML[4] += "%6@2    v15 o3  $r4 c4 r4 c4;";                     // Snare pattern (voice 2)
            rhythmMML[4] += "%6@3 p2 v5      $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            rhythmMML[4] += "%6@4 p6 v7  o3  $r8 c8 r8 c16 c16 c16 r16 r16 c16 r16 r16 c16 r16;"; // Open Hat pattern
            rhythmMML[4] += "%6@6 p6 v1  o4  $e1 d2 e4 d4;";                     // First organ track
            rhythmMML[4] += "%6@6 p2 v1  o4  $a1 g2 g4 g4;";                     // Second organ track
            rhythmMML[4] += "%6@6    v1  o5  $c1>b2 b4 b4<;";                    // Third organ track
            rhythmMML[4] += "%6@7    v10 o2  $a8 e16 g16 a8 e16 g16 a8 r8^4";    // bar one -- Bass pattern (voice 7)
            rhythmMML[4] +=                  "g8 r8^4 e8<e16>b16 g8<g16 e16>;";  // bar two -- Bass pattern (voice 7)

            // Pattern six:
            //              Inst|Pan|Vol|Oct|Sequence
            rhythmMML[5] =  "%6@1    v15 o3  $c16 c16 r16 c16 r16 c16 c16 r16 c16 c16 r16 c16 r16 c16 r8;"; // Kick
            rhythmMML[5] += "%6@2    v15 o3  $r4 c4 r4 c8 c8;";               // Snare pattern (voice 2)
            rhythmMML[5] += "%6@3 p2 v3      $c4 c4 c4 c4;";               // Closed Hat pattern (voice 3)
            rhythmMML[5] += "%6@4 p6 v7  o3  $r2^4 c8;";               // Open Hat pattern (voice 4)
            rhythmMML[5] += "%6@6 p6 v2  o4  $a1 a1 g1 g1 a1 a1 g+1 g+1;"; // First organ track
            rhythmMML[5] += "%6@6 p2 v2  o5  $d1 d1 c1 c1 c1 c1 c1  c1;";  // Second organ track
            rhythmMML[5] += "%6@6    v2  o5r4$  e1 e1 d1 d1 d4 e1 e1 d1 d1 d4;";// Third organ track (overrun bar)
            rhythmMML[5] += "%6@7    v9  o2  $a16 g16 a16 r16^4 a16 g16 a16 r16<e16 d16 e16>r16";      // bar one-1
            rhythmMML[5] +=                  "a16 g16 a16 r16<a8>r8 a16 g16 a16 r16<e16 d16 e16>r16";  // bar one-2
            rhythmMML[5] +=                  "g16 f16 g16 r16^4 g16 f16 g16 r16<d16 c16 d16>r16";      // bar two-1
            rhythmMML[5] +=                  "g16 f16 g16 r16<g8>r8 g16 f16 g16 r16<d16 c16 d16>r16";  // bar two-2
            rhythmMML[5] +=                  "f16 e-16 f16 r16^4 f16 e-16 f16 r16<c16>b-16<c16>r16";   // bar three-1
            rhythmMML[5] +=                  "f16 e-16 f16 r16<f8>r8 f16 e-16 f16 r16<c16>b-16<c16>r16";// bar three-2
            rhythmMML[5] +=                  "e16 d16 e16 r16^4 e16 d16 e16 r16 b16 a16 b16 r16";      // bar four-1
            rhythmMML[5] +=                  "e16 d16 e16 r16<e8>r8 e16 d16 e16 r16 b16 a16 b16 r16;"; // bar four-1

            // Pattern seven:
            //              Inst|Pan|Vol|Oct|Sequence
            rhythmMML[6] =  "%6@1    v15 o3  $c16 c16 c16 c16 r8 c16 c16 r8 c16 c16 r4;"; // Kick pattern (voice 1)
            rhythmMML[6] += "%6@2    v15 o3  $r4 c4 r4 c4;";                     // Snare pattern (voice 2)
            rhythmMML[6] += "%6@3 p2 v5      $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            rhythmMML[6] += "%6@4 p6 v7  o3  $[r8 c8 r8 c8];";                   // Open Hat pattern (voice 4)
            rhythmMML[6] += "%6@5    v11 o4  $[a16 r16 r8 a16 r16 r8];";         // Percussion (voice 5)
            rhythmMML[6] += "%6@6 p6 v1  o4  $[r8 e8]4  [r8 d8] r8 e8 r8 d8 ;";  // First organ track (voice 6)
            rhythmMML[6] += "%6@6 p2 v1  o4  $[r8 a8]4  [r8 g8] r8 g8 r8 g8 ;";  // Second organ track "
            rhythmMML[6] += "%6@6    v1  o5  $[r8 c8]4 >[r8 b8] r8 b8 r8 b8<;";  // Third organ track "
            rhythmMML[6] += "%6@7    v10 o2  $a8 e16 g16 a8 e16 g16 a8 r8^4";    // bar one -- Bass pattern (voice 7)
            rhythmMML[6] +=                  "g8 r8^4 e8<e16>b16 g8<g16 e16>;";  // bar two -- Bass pattern (voice 7)

            // Compile the MML and set the voices for each instrument
            var percusVoices:Array = presetVoice["valsound.percus"];

            for(var i:int = 0; i < rhythmPatternArray.length; i++)
            {
                rhythmPatternArray[i] = driver.compile(rhythmMML[i]);
                rhythmPatternArray[i].setVoice(1, percusVoices[1]);  // kick
                rhythmPatternArray[i].setVoice(2, percusVoices[27]); // snare
                rhythmPatternArray[i].setVoice(3, percusVoices[16]); // closed hihat
                rhythmPatternArray[i].setVoice(4, percusVoices[21]); // open hihat
                rhythmPatternArray[i].setVoice(5, presetVoice["midi.percus4"]); // some kind of block?
                rhythmPatternArray[i].setVoice(6, presetVoice["valsound.lead8"]); // An organ
                rhythmPatternArray[i].setVoice(7, presetVoice["valsound.bass46"]); // A bass
            }
            trace("rhythmPatternArray length is", rhythmPatternArray.length);

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
            leadPatternArray[2][14] = new Note(50, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][20] = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][22] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][24] = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][26] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][28] = new Note(43, DEFAULT_VELOCITY, 4); 

            leadPatternArray[2][34] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][38] = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][42] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][46] = new Note(52, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][48] = new Note(55, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][52] = new Note(50, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][54] = new Note(52, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][56] = new Note(55, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][58] = new Note(57, DEFAULT_VELOCITY, 2); 
            leadPatternArray[2][60] = new Note(55, DEFAULT_VELOCITY, 4); 

            // pattern 4
            leadPatternArray[3][0]  = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][2]  = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][6]  = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][8]  = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][10] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][12] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][14] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][16] = new Note(45, DEFAULT_VELOCITY, 8); 

            leadPatternArray[3][32] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][34] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][38] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][40] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][42] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][44] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][46] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[3][48] = new Note(40, DEFAULT_VELOCITY, 8); 

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
            leadPatternArray[5][2]  = new Note(45, DEFAULT_VELOCITY, 2);
            leadPatternArray[5][6]  = new Note(47, DEFAULT_VELOCITY, 2);
            leadPatternArray[5][10] = new Note(48, DEFAULT_VELOCITY, 2);
            leadPatternArray[5][14] = new Note(50, DEFAULT_VELOCITY, 8);

            //leadPatternArray[5][18] = new Note(45, DEFAULT_VELOCITY, 2);
            //leadPatternArray[5][22] = new Note(47, DEFAULT_VELOCITY, 2);
            //leadPatternArray[5][26] = new Note(48, DEFAULT_VELOCITY, 2);
            //leadPatternArray[5][30] = new Note(50, DEFAULT_VELOCITY, 2);

            leadPatternArray[5][34] = new Note(45, DEFAULT_VELOCITY, 2);
            leadPatternArray[5][38] = new Note(48, DEFAULT_VELOCITY, 2);
            leadPatternArray[5][42] = new Note(50, DEFAULT_VELOCITY, 2);
            leadPatternArray[5][46] = new Note(52, DEFAULT_VELOCITY, 8);

            //leadPatternArray[5][50] = new Note(45, DEFAULT_VELOCITY, 2);
            //leadPatternArray[5][54] = new Note(47, DEFAULT_VELOCITY, 2);
            //leadPatternArray[5][58] = new Note(50, DEFAULT_VELOCITY, 2);
            //leadPatternArray[5][62] = new Note(48, DEFAULT_VELOCITY, 2);

            // Pattern 7
            leadPatternArray[6][2]  = new Note(51, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][3]  = new Note(50, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][4]  = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][6]  = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][8]  = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][18] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][20] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][22] = new Note(50, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][24] = new Note(47, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][26] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][28] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][30] = new Note(42, DEFAULT_VELOCITY, 2); 

            leadPatternArray[6][32] = new Note(40, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][34] = new Note(51, DEFAULT_VELOCITY, 1);
            leadPatternArray[6][35] = new Note(50, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][36] = new Note(48, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][38] = new Note(45, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][40] = new Note(43, DEFAULT_VELOCITY, 2); 
            leadPatternArray[6][49] = new Note(45, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][50] = new Note(48, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][51] = new Note(50, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][52] = new Note(48, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][53] = new Note(50, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][54] = new Note(53, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][55] = new Note(55, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][56] = new Note(52, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][57] = new Note(55, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][58] = new Note(57, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][59] = new Note(59, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][60] = new Note(55, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][61] = new Note(57, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][62] = new Note(59, DEFAULT_VELOCITY, 1); 
            leadPatternArray[6][63] = new Note(67, DEFAULT_VELOCITY, 1); 

            // Set up the volume
            leadPatternSequencer.volume = 0.8;

            // Set the voice
            leadPatternSequencer.voice = presetVoice["valsound.lead37"];


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
            if (newValue == prevTargetsRemaining) return;

            prevTargetsRemaining = newValue;

            var newMusicTensionLevel:int;

            switch (newValue)
            {
                case 12:
                    newMusicTensionLevel = 0;
                    break;
                case 11:
                case 10:
                    newMusicTensionLevel = 1;
                    break;
                case 9:
                case 8:
                case 7:
                    newMusicTensionLevel = 2;
                    break;
                case 6:
                case 5:
                case 4:
                    newMusicTensionLevel = 3;
                    break;
                case 3:
                case 2:
                    newMusicTensionLevel = 4;
                    break;
                case 1:
                    newMusicTensionLevel = 5;
                    break;
                case 0:
                    newMusicTensionLevel = 6;
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

        // Getter and setter for portamento property
        public static function get portamento (): Boolean {return _leadSequencerPortamento;}

        public static function set portamento (newValue:Boolean): void
        {
            if (_leadSequencerPortamento == newValue) return;

            _leadSequencerPortamento = newValue;


            // Set portamento
            leadPatternSequencer.portament = _leadSequencerPortamento ? 1 : 0;
        }

		
		// Getter and setters for mute and enabled properties

        public static function get enabled ():Boolean { return _enabled;}

        public static function set enabled (newValue:Boolean):void
        {
            if (_enabled == newValue) return;

            _enabled = newValue;

            if (!_enabled)
                stopDriver();

            else if (_enabled && !_mute)
                startDriver();

            trace(_enabled ? "Audio enabled!" : "Audio disabled!");
        }
		
		public static function get mute (): Boolean { return _mute; }
		
		public static function set mute (newValue:Boolean): void
		{
			if (_mute == newValue) return;
			
			_mute = newValue;

            if (_mute)
                stopDriver();

            else if (!_mute && _enabled)
                startDriver();
			
			menuItem.caption = _mute ? "Unmute" : "Mute";
			
			so.data.mute = _mute;
			so.flush();

            trace(_mute ? "Audio muted!" : "Audio unmuted!");
		}

        public static function get muteLead ():Boolean {return leadPatternSequencer.mute;}

        public static function set muteLead (newValue:Boolean):void
        {
            if (leadPatternSequencer.mute == newValue) return;

            if (newValue == false)
            {
                leadToUnmute = true;
            }
            else
            {
                leadPatternSequencer.mute = newValue;
            }

        }

        public static function resetMusic():void
        {
            prevTargetsRemaining = -1;
            musicTensionLevel = 0;
            patternChanged = true;
            startDriver();
            trace("music reset!");
        }
		
		// Implementation details
        private static function startDriver():void
        {
            // Before starting the driver, we first make sure it is stopped.
            if (driver.isPlaying)
                stopDriver();

            // Start the driver at the right tempo
            beatCounter = 0;
            driver.bpm = TEMPO;
			if(musicTensionLevel != 0)
				driver.play();
        }

        private static function stopDriver():void
        {
            //We make sure all the sequencers are off, then stop the driver.
            stopAllDriverSequences();
            rhythmIsPlaying = false;
            leadPatternSequencer.stop();
            driver.stop();
        }

        // That's right, gentlemen, onBeat is NOT timing-accurate.
        // Instead we use this, whatever this is.
        private static function onTimerInterruption():void
        {
            // This line gets us a 0 to 32 index of the current bar
            var beatIndex:int = beatCounter % 32;
            //trace(beatIndex);

            // When the pattern needs changing, we straightaway change the lead
            // line, for instant feedback, and we set a flag for the rhythm
            // to change next time the pattern loops.
			if (patternChanged)
			{
                patternChanged = false;
                rhythmToChange = true;

                leadPatternSequencer.sequencer.pattern = leadPatternArray[musicTensionLevel];
                trace("lead pattern changed!");
			}

            if (beatIndex % 8 == 0)
            {
                if (leadToUnmute)
                {
                    leadToUnmute = false;
                    leadPatternSequencer.mute = false;
                }
            }

            // Only do this stuff at the start of a pattern.
            if (beatIndex % PATTERN_LENGTH == 0)
            {
                if (rhythmToChange)
                {
                    rhythmToChange = false;

                    stopAllDriverSequences();
                    driver.sequenceOn(rhythmPatternArray[musicTensionLevel]);
                    rhythmIsPlaying = true;

                    trace("rhythm pattern changed!");
                }

                // Play if necessary and not muted
                if (!_mute && _enabled)
                {

                    if (!leadPatternSequencer.isPlaying)
                        leadPatternSequencer.play();

                    if (!rhythmIsPlaying)
                    {
                        stopAllDriverSequences();
                        driver.sequenceOn(rhythmPatternArray[musicTensionLevel]);
                        rhythmIsPlaying = true;
                        trace("rhythmIsPlaying =", rhythmIsPlaying);
                    }
                }
            }
            beatCounter++;
        }

        private static function stopAllDriverSequences():void
        {
            // Waaagh kill all the sequences
            // I can't find a good way to know what's going on,
            // so I'm hacking it and killing everything.
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

