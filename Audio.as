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
    import org.si.sion.sequencer.*;
    import org.si.sion.utils.SiONPresetVoice;
    import org.si.sound.PatternSequencer;
    import org.si.sound.patterns.Note;

	public class Audio
	{
        //Set the tempo here
        private static const TEMPO:int = 100;
        // Sound driver
        private static var driver:SiONDriver = new SiONDriver();

        // Preset sound voices
        private static var presetVoice:SiONPresetVoice = new SiONPresetVoice();

        private static var beatCounter:int;

        private static var musicTensionLevel:int = -1;

        private static var patternChanged:Boolean = false;

        private static var drumPatternArray:Vector.<SiONData> = new Vector.<SiONData>();
        private static var drumPatternCurrent:SiONData;
        private static var drumsArePlaying:Boolean = false;

        private static var currentSequence:Vector.<SiMMLTrack> = new Vector.<SiMMLTrack>();

        private static var bassPatternSequencer:PatternSequencer = new PatternSequencer(32);
        //private static var bassPatternMaster:Vector.<Note> = new Vector.<Note>(32, true);
        private static var bassPatternArray:Vector.<Vector.<Note>> = new Vector.<Vector.<Note>>(12, true);
        private static var bassPatternCurrent:Vector.<Note> = new Vector.<Note>(32, true);

        private static var leadPatternSequencer:PatternSequencer = new PatternSequencer(32);
        //private static var leadPatternMaster:Vector.<Note> = new Vector.<Note>(32, true);
        private static var leadPatternArray:Vector.<Vector.<Note>> = new Vector.<Vector.<Note>>(12, true);
        private static var leadPatternCurrent:Vector.<Note> = new Vector.<Note>(32, true);

        private static var _leadSequencerPortamento:Boolean = false;

		private static var jump:SfxrSynth;
		private static var death:SfxrSynth;
		private static var target:SfxrSynth;
		private static var bounce:SfxrSynth;
		
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
            //         DRUM TRACK
            //---------------------------------
            // Loop one:
            var drums1:String;  
            //         Inst   |Vol|Oct|Sequence
            drums1 =  "%6@1    v4  o3  $c2 c2;";                  // Kick pattern (voice 1)
            //drums1 += "%6@5    v2  o4  $a4 a4 a4 a4;";                      //percussion (voice 5)

            // Loop two:
            var drums2:String;  
            drums2 =  "%6@1    v4  o3  $c4 c4 c4 c4;";            // Kick pattern (voice 1)

            // Loop three:
            var drums3:String;  
            drums3 =  "%6@1    v4  o3  $c4 c4 c4 c4;";            // Kick pattern (voice 1)
            drums3 += "%6@3    v1  p2  $c8 c8 c8 c8 c8 c8 c8 c8;";   // Closed Hat pattern (voice 3)

            // Loop four:
            var drums4:String;  
            drums4 =  "%6@1    v4  o3  $c4 c4 c4 r8 c8;";             // Kick pattern (voice 1)
            drums4 += "%6@3    v1  p2  $c8 c8 c8 c8 c8 c8 c8 c8;";    // Closed Hat pattern (voice 3)

            // Loop five:
            var drums5:String;  
            drums5 =  "%6@1    v4  o3  $c4 c4 c4 c8 c8;";             // Kick pattern (voice 1)
            drums5 += "%6@3    v1  p2  $c16 c16 c8 c8 c8 c16 c16 c8 c8 c8;";   // Closed Hat pattern (voice 3)

            // Loop six:
            var drums6:String;  
            drums6 =  "%6@1    v4  o3  $c4 c4 c4 c8 c8;";             // Kick pattern (voice 1)
            drums6 += "%6@3    v1  p2  $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)

            // Loop seven:
            var drums7:String;  
            drums7 =  "%6@1    v4  o3  $c8 c8 c4 c4 c8 c8;";          // Kick pattern (voice 1)
            drums7 += "%6@3    v1  p2  $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)

            // Loop eight:
            var drums8:String;  
            drums8 =  "%6@1    v4  o3  $c8 c8 c4 c4 c8 c8;";          // Kick pattern (voice 1)
            drums8 += "%6@3    v1  p2  $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            drums8 += "%6@4 p6 v2  o3  $r4 c8 r16 c16 r4 c8 c4;";   // Open Hat pattern (voice 4)

            // Loop nine:
            var drums9:String;  
            drums9 =  "%6@1    v4  o3  $c8 c8 c4 c4 c8 c8;";          // Kick pattern (voice 1)
            drums9 += "%6@3    v1  p2  $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            drums9 += "%6@4 p6 v2  o3  $r4 c8 r16 c16 r4 c16 c16 c4;";   // Open Hat pattern (voice 4)

            // Loop ten:
            var drums10:String;  
            drums10 =  "%6@1    v4  o3  $c8 c8 c4 c4 c8 c8;";          // Kick pattern (voice 1)
            drums10 += "%6@3    v1  p2  $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            drums10 += "%6@4 p6 v2  o3  $c4 c8 r16 c16 r4 c16 c16 c4;";   // Open Hat pattern (voice 4)

            // Loop eleven:
            var drums11:String;  
            drums11 =  "%6@1    v4  o3  $c8 c8 c4 c4 c8 c8;";          // Kick pattern (voice 1)
            drums11 += "%6@2    v4  o3  $r c r c;";                // Snare pattern (voice 2)
            drums11 += "%6@3    v1  p2  $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            drums11 += "%6@4 p6 v2  o3  $r4 c8 r16 c16 r4 c16 c16 c4;";   // Open Hat pattern (voice 4)

            // Loop twelve:
            var drums12:String;  
            drums12 =  "%6@1    v4  o3  $c16 c16 c16 c16 c4 c16 c16 c16 c16 c4;";          // Kick pattern (voice 1)
            drums12 += "%6@2    v4  o3  $r c r c;";                // Snare pattern (voice 2)
            drums12 += "%6@3    v1  p2  $c16 c16 c8 c8 c8 c16 c16 c8 c16 c16;";   // Closed Hat pattern (voice 3)
            drums12 += "%6@4 p6 v2  o3  $[r8 c8 r8 c8];";   // Open Hat pattern (voice 4)
            drums12 += "%6@5    v3  o4  $[a16 r16 r8 a16 r16 r8];";                      //percussion (voice 5)

            // Compile the MML:
            drumPatternArray[0] = driver.compile(drums1);
            drumPatternArray[1] = driver.compile(drums2);
            drumPatternArray[2] = driver.compile(drums3);
            drumPatternArray[3] = driver.compile(drums4);
            drumPatternArray[4] = driver.compile(drums5);
            drumPatternArray[5] = driver.compile(drums6);
            drumPatternArray[6] = driver.compile(drums7);
            drumPatternArray[7] = driver.compile(drums8);
            drumPatternArray[8] = driver.compile(drums9);
            drumPatternArray[9] = driver.compile(drums10);
            drumPatternArray[10] = driver.compile(drums11);
            drumPatternArray[11] = driver.compile(drums12);

            // Set the voices for each instrument
            var percusVoices:Array = presetVoice["valsound.percus"];
            for(var i:int = 0; i < drumPatternArray.length; i++)
            {
                drumPatternArray[i].setVoice(1, percusVoices[1]);  // kick
                drumPatternArray[i].setVoice(2, percusVoices[27]); // snare
                drumPatternArray[i].setVoice(3, percusVoices[16]); // closed hihat
                drumPatternArray[i].setVoice(4, percusVoices[21]); // open hihat
                drumPatternArray[i].setVoice(5, presetVoice["midi.percus4"]); // some kind of block?
            }

            //---------------------------------
            //         BASS TRACK
            //---------------------------------
            // The array of different patterns
            bassPatternArray[0] = new Vector.<Note>(32, true);
            bassPatternArray[1] = new Vector.<Note>(32, true);
            bassPatternArray[2] = new Vector.<Note>(32, true);
            bassPatternArray[3] = new Vector.<Note>(32, true);
            bassPatternArray[4] = new Vector.<Note>(32, true);
            bassPatternArray[5] = new Vector.<Note>(32, true);
            bassPatternArray[6] = new Vector.<Note>(32, true);
            bassPatternArray[7] = new Vector.<Note>(32, true);
            bassPatternArray[8] = new Vector.<Note>(32, true);
            bassPatternArray[9] = new Vector.<Note>(32, true);
            bassPatternArray[10] = new Vector.<Note>(32, true);
            bassPatternArray[11] = new Vector.<Note>(32, true);

            // Master Pattern, for reference:
            /*
            bassPatternMaster[0] = new Note(33, 64, 3); 
            bassPatternMaster[1] = null; 
            bassPatternMaster[2] = null; 
            bassPatternMaster[3] = new Note(28, 64, 1); 
            bassPatternMaster[4] = new Note(31, 64, 2); 
            bassPatternMaster[5] = null; 
            bassPatternMaster[6] = new Note(32, 64, 2); 
            bassPatternMaster[7] = null; 
            bassPatternMaster[8] = new Note(33, 64, 3); 
            bassPatternMaster[9] = null; 
            bassPatternMaster[10] = null; 
            bassPatternMaster[11] = null; 
            bassPatternMaster[12] = new Note(28, 64, 2); 
            bassPatternMaster[13] = null; 
            bassPatternMaster[14] = new Note(43, 64, 2); 
            bassPatternMaster[15] = null; 
            bassPatternMaster[16] = new Note(33, 64, 3); 
            bassPatternMaster[17] = null; 
            bassPatternMaster[18] = null; 
            bassPatternMaster[19] = new Note(35, 64, 1); 
            bassPatternMaster[20] = new Note(34, 64, 2); 
            bassPatternMaster[21] = null;              
            bassPatternMaster[22] = new Note(31, 64, 2); 
            bassPatternMaster[23] = null;              
            bassPatternMaster[24] = new Note(33, 64, 2); 
            bassPatternMaster[25] = null; 
            bassPatternMaster[26] = new Note(21, 64, 2); 
            bassPatternMaster[27] = null;             
            bassPatternMaster[28] = new Note(28, 64, 2); 
            bassPatternMaster[29] = null; 
            bassPatternMaster[30] = new Note(31, 64, 2);             
            bassPatternMaster[31] = null; 
            */

            // Pattern 1
            bassPatternArray[0][0] = new Note(33, 64, 3);
            bassPatternArray[0][16] = new Note(33, 64, 3); 
            
            // Pattern 2
            bassPatternArray[1] = bassPatternArray[0].concat();
            bassPatternArray[1][8] = new Note(33, 64, 3); 

            // Pattern 3
            bassPatternArray[2] = bassPatternArray[1].concat();
            bassPatternArray[2][30] = new Note(31, 64, 2);             

            // Pattern 4
            bassPatternArray[3] = bassPatternArray[2].concat();
            bassPatternArray[3][26] = new Note(21, 64, 2); 

            // Pattern 5
            bassPatternArray[4] = bassPatternArray[3].concat();
            bassPatternArray[4][12] = new Note(28, 64, 2); 

            // Pattern 6
            bassPatternArray[5] = bassPatternArray[4].concat();
            bassPatternArray[5][3] = new Note(28, 64, 1); 
            bassPatternArray[5][4] = new Note(31, 64, 2); 

            // Pattern 7
            bassPatternArray[6] = bassPatternArray[5].concat();
            bassPatternArray[6][8] = new Note(33, 64, 2); 

            // Pattern 8
            bassPatternArray[7] = bassPatternArray[6].concat();
            bassPatternArray[7][19] = new Note(35, 64, 1); 
            bassPatternArray[7][20] = new Note(34, 64, 2); 

            // Pattern 9
            bassPatternArray[8] = bassPatternArray[7].concat();
            bassPatternArray[8][6] = new Note(32, 64, 2); 

            // Pattern 10
            bassPatternArray[9] = bassPatternArray[8].concat();
            bassPatternArray[9][24] = new Note(33, 64, 2); 

            // Pattern 11 
            bassPatternArray[10] = bassPatternArray[9].concat();
            bassPatternArray[10][28] = new Note(28, 64, 2); 

            // Pattern 12
            bassPatternArray[11] = bassPatternArray[10].concat();
            bassPatternArray[11][14] = new Note(43, 64, 2); 

            // Set up the volume
            bassPatternSequencer.volume = 0.2;

            // Set the voice
            bassPatternSequencer.voice = presetVoice["valsound.bass1"];

            //---------------------------------
            //         LEAD TRACK
            //---------------------------------
            // Pattern Arrays
            leadPatternArray[0] = new Vector.<Note>(32, true);
            leadPatternArray[1] = new Vector.<Note>(32, true);
            leadPatternArray[2] = new Vector.<Note>(32, true);
            leadPatternArray[3] = new Vector.<Note>(32, true);
            leadPatternArray[4] = new Vector.<Note>(32, true);
            leadPatternArray[5] = new Vector.<Note>(32, true);
            leadPatternArray[6] = new Vector.<Note>(32, true);
            leadPatternArray[7] = new Vector.<Note>(32, true);
            leadPatternArray[8] = new Vector.<Note>(32, true);
            leadPatternArray[9] = new Vector.<Note>(32, true);
            leadPatternArray[10] = new Vector.<Note>(32, true);
            leadPatternArray[11] = new Vector.<Note>(32, true);

            // Master pattern, for reference:
            /*
            leadPatternMaster[0] = new Note(45, 64, 1); 
            leadPatternMaster[1] = new Note(40, 64, 1); 
            leadPatternMaster[2] = new Note(43, 64, 1); 
            leadPatternMaster[3] = new Note(40, 64, 1);
            leadPatternMaster[4] = new Note(48, 64, 1);
            leadPatternMaster[5] = new Note(40, 64, 1);
            leadPatternMaster[6] = new Note(43, 64, 1);
            leadPatternMaster[7] = new Note(44, 64, 1);
            leadPatternMaster[8] = new Note(45, 64, 1);
            leadPatternMaster[9] = new Note(43, 64, 1);
            leadPatternMaster[10] = new Note(41, 64, 1); 
            leadPatternMaster[11] = new Note(40, 64, 1); 
            leadPatternMaster[12] = new Note(39, 64, 1); 
            leadPatternMaster[13] = new Note(38, 64, 1); 
            leadPatternMaster[14] = new Note(36, 64, 1); 
            leadPatternMaster[15] = new Note(38, 64, 1); 
            leadPatternMaster[16] = new Note(39, 64, 1); 
            leadPatternMaster[17] = new Note(38, 64, 1); 
            leadPatternMaster[18] = new Note(36, 64, 1); 
            leadPatternMaster[19] = new Note(35, 64, 1); 
            leadPatternMaster[20] = new Note(33, 64, 1); 
            leadPatternMaster[21] = new Note(28, 64, 1); 
            leadPatternMaster[22] = new Note(31, 64, 1); 
            leadPatternMaster[23] = new Note(28, 64, 1); 
            leadPatternMaster[24] = new Note(28, 64, 1); 
            leadPatternMaster[25] = new Note(31, 64, 1); 
            leadPatternMaster[26] = new Note(32, 64, 1); 
            leadPatternMaster[27] = new Note(33, 64, 1);             
            leadPatternMaster[28] = new Note(45, 64, 1); 
            leadPatternMaster[29] = new Note(45, 64, 1); 
            leadPatternMaster[30] = new Note(45, 64, 1);             
            leadPatternMaster[31] = new Note(45, 64, 1); 
            */

            // Pattern 1
            leadPatternArray[0][0] = new Note(45, 64, 1); 
            leadPatternArray[0][1] = new Note(40, 64, 1); 

            // Pattern 2
            leadPatternArray[1] = leadPatternArray[0].concat();
            leadPatternArray[1][16] = new Note(39, 64, 1); 
            leadPatternArray[1][17] = new Note(38, 64, 1); 

            // Pattern 3
            leadPatternArray[2] = leadPatternArray[1].concat();
            leadPatternArray[2][25] = new Note(31, 64, 1); 
            leadPatternArray[2][26] = new Note(32, 64, 1); 
            leadPatternArray[2][27] = new Note(33, 64, 1);             

            // pattern 4
            leadPatternArray[3] = leadPatternArray[2].concat();
            leadPatternArray[3][8] = new Note(45, 64, 1);
            leadPatternArray[3][9] = new Note(43, 64, 1);
            leadPatternArray[3][10] = new Note(41, 64, 1); 
            leadPatternArray[3][11] = new Note(40, 64, 1); 

            // Pattern 5
            leadPatternArray[4] = leadPatternArray[3].concat();
            leadPatternArray[4][4] = new Note(48, 64, 1);
            leadPatternArray[4][5] = new Note(40, 64, 1);
            leadPatternArray[4][6] = new Note(43, 64, 1);

            // Pattern 6
            leadPatternArray[5] = leadPatternArray[4].concat();
            leadPatternArray[5][12] = new Note(39, 64, 1); 
            leadPatternArray[5][13] = new Note(38, 64, 1); 

            // Pattern 7
            leadPatternArray[6] = leadPatternArray[5].concat();
            leadPatternArray[6][29] = new Note(45, 64, 1); 
            leadPatternArray[6][31] = new Note(45, 64, 1); 

            // Pattern 8
            leadPatternArray[7] = leadPatternArray[6].concat();
            leadPatternArray[7][22] = new Note(31, 64, 1); 
            leadPatternArray[7][23] = new Note(28, 64, 1); 
            leadPatternArray[7][24] = new Note(28, 64, 1); 

            // Pattern 9
            leadPatternArray[8] = leadPatternArray[7].concat();
            leadPatternArray[8][18] = new Note(36, 64, 1); 
            leadPatternArray[8][19] = new Note(35, 64, 1); 
            leadPatternArray[8][20] = new Note(33, 64, 1); 

            // Pattern 10
            leadPatternArray[9] = leadPatternArray[8].concat();
            leadPatternArray[9][15] = new Note(38, 64, 1); 
            leadPatternArray[9][28] = new Note(45, 64, 1); 

            // Pattern 11 
            leadPatternArray[10] = leadPatternArray[9].concat();
            leadPatternArray[10][2] = new Note(43, 64, 1); 
            leadPatternArray[10][3] = new Note(40, 64, 1);
            leadPatternArray[10][30] = new Note(45, 64, 1);             

            // Pattern 12
            leadPatternArray[11] = leadPatternArray[10].concat();
            leadPatternArray[11][7] = new Note(44, 64, 1);
            leadPatternArray[11][14] = new Note(36, 64, 1); 
            leadPatternArray[11][21] = new Note(28, 64, 1); 

            // Set up the volume
            leadPatternSequencer.volume = 0.1;

            // Set the voice
            leadPatternSequencer.voice = presetVoice["valsound.lead31"];

            // Set up listeners for the beat
            driver.setBeatCallbackInterval(1);
            driver.addEventListener(SiONTrackEvent.BEAT, onBeat);
            driver.setTimerInterruption(1, onTimerInterruption);

            // Start the driver at the right tempo
            beatCounter = 0;
            driver.play("t" + TEMPO.toString() + ";");
		}
		
		public static function play (sound:String):void
		{
			if (! _mute) {
				Audio[sound].playCachedMutation();
			}
		}

        public static function setMusicTensionLevel(newValue:int):void
        {
            if (musicTensionLevel == newValue) return;
            
            musicTensionLevel = newValue;

            patternChanged = true;
            trace("music incrementing to ", musicTensionLevel);
        }

        // REMOVE:
        public static function incrementMusicTensionLevel():void
        {
            musicTensionLevel++;
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
            leadPatternSequencer.portament = _leadSequencerPortamento ? 1: 0;
        }

		
		// Getter and setter for mute property
		
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
            }
			
			menuItem.caption = _mute ? "Unmute" : "Mute";
			
			so.data.mute = _mute;
			so.flush();
		}
		
		// Implementation details

        private static function onBeat(e:SiONTrackEvent):void
        {
            //do nothing
        }

        // That's right, gentlemen, onBeat is NOT timing-accurate.
        // Instead we use this, whatever this is.
        private static function onTimerInterruption():void
        {
            // This line gets us a 0 to 15 index of the current bar
            var beatIndex:int = beatCounter & 15;

            // Only do this stuff at the start of a bar.
            if (beatIndex % 16 == 0)
            {
                if (patternChanged)
                {
                    patternChanged = false;

                    if (musicTensionLevel == -1) // no targets got yet
                    {
                        stopAllDriverSequences();
                        currentSequence = driver.sequenceOn(new SiONData());
                        drumsArePlaying = true;
                        bassPatternSequencer.sequencer.pattern = new Vector.<Note>(32, false);
                        leadPatternSequencer.sequencer.pattern = new Vector.<Note>(32, false);
                    }
                    else
                    {
                        stopAllDriverSequences();
                        currentSequence = driver.sequenceOn(drumPatternArray[musicTensionLevel]);
                        drumsArePlaying = true;
                        bassPatternSequencer.sequencer.pattern = bassPatternArray[musicTensionLevel];
                        leadPatternSequencer.sequencer.pattern = leadPatternArray[musicTensionLevel];
                    }
                    trace("pattern changed!");
                }

                // Play if necessary and not muted
                if (!_mute)
                {
                    if (!bassPatternSequencer.isPlaying)
                        bassPatternSequencer.play();

                    if (!leadPatternSequencer.isPlaying)
                        leadPatternSequencer.play();

                    if (!drumsArePlaying)
                    {
                        if (musicTensionLevel == -1) // no targets got yet
                            currentSequence = driver.sequenceOn(new SiONData());
                        else
                            driver.sequenceOn(drumPatternArray[musicTensionLevel]);
                        drumsArePlaying = true;
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

