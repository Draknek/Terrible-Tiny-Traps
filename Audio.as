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
    import org.si.sion.utils.SiONPresetVoice;
    import org.si.sound.PatternSequencer;
    import org.si.sound.patterns.Note;

	public class Audio
	{
        // Sound driver
        private static var driver:SiONDriver = new SiONDriver();

        // Preset sound voices
        private static var presetVoice:SiONPresetVoice = new SiONPresetVoice();

        private static var patternSequencer:PatternSequencer = new PatternSequencer(32);
        private static var _sequencerPortamento:Boolean = false;

        private static var rhythmLoop:SiONData;
        private static var beatCounter:int;

        private static var patternIndex:int = -1;
        private static var patternArray:Array = new Array();
        private static var patternCurrent:Vector.<Note>;
        private static var patternChanged:Boolean = false;

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

            /// Set up MML data
            // Set up the rhythm loop
            var mml:String = "t100;";                           // Set the tempo.
            //      Inst   |Vol|Oct|Len|Sequence
            mml += "%6@1    v4  o3  l8  $c2 c c. c.;";             // Kick pattern (voice 1)
            mml += "%6@2    v4  o3      $r c r c;";                // Snare pattern (voice 2)
            mml += "%6@3    v2      l16 $[c r c c r r c c];";      // Closed Hat pattern (voice 3)
            mml += "%6@4    v2  o3      $r c8 r16 c16 r c8 r8;";   // Open Hat pattern (voice 4)
            mml += "%6@5    v1  o2  l2  $a. r4 a. r4;";              // Bass pattern (voice 5)

            rhythmLoop = driver.compile(mml);

            // Set the voices for each instrument
            var percusVoices:Array = presetVoice["valsound.percus"];
            rhythmLoop.setVoice(1, percusVoices[1]);  // kick
            rhythmLoop.setVoice(2, percusVoices[27]); // snare
            rhythmLoop.setVoice(3, percusVoices[16]); // closed hihat
            rhythmLoop.setVoice(4, percusVoices[21]); // open hihat

            rhythmLoop.setVoice(5, presetVoice["valsound.bass1"]);

            /// Set up the lead sequenced pattern
            // The array of different patterns
            patternArray[0] = new Vector.<Note>(32, true);
            patternArray[1] = new Vector.<Note>(32, true);
            patternArray[2] = new Vector.<Note>(32, true);
            patternArray[3] = new Vector.<Note>(32, true);
            patternArray[4] = new Vector.<Note>(32, true);
            patternArray[5] = new Vector.<Note>(32, true);
            patternArray[6] = new Vector.<Note>(32, true);
            patternArray[7] = new Vector.<Note>(32, true);
            patternArray[8] = new Vector.<Note>(32, true);
            patternArray[9] = new Vector.<Note>(32, true);
            patternArray[10] = new Vector.<Note>(32, true);
            patternArray[11] = new Vector.<Note>(32, true);


            // Master pattern, for reference:
            patternArray[0][0] = new Note(45, 64, 4); 
            patternArray[0][1] = null; 
            patternArray[0][2] = null; 
            patternArray[0][3] = null; 
            patternArray[0][4] = null; 
            patternArray[0][5] = null; 
            patternArray[0][6] = null; 
            patternArray[0][7] = null; 
            patternArray[0][8] = null; 
            patternArray[0][9] = null; 
            patternArray[0][10] = null; 
            patternArray[0][11] = null; 
            patternArray[0][12] = null; 
            patternArray[0][13] = null; 
            patternArray[0][14] = null; 
            patternArray[0][15] = null; 
            patternArray[0][16] = null; 
            patternArray[0][17] = null; 
            patternArray[0][18] = null; 
            patternArray[0][19] = null; 
            patternArray[0][20] = null; 
            patternArray[0][21] = null; 
            patternArray[0][22] = null; 
            patternArray[0][23] = null; 
            patternArray[0][24] = null; 
            patternArray[0][25] = null; 
            patternArray[0][26] = null; 
            patternArray[0][27] = null;             
            patternArray[0][28] = null; 
            patternArray[0][29] = null; 
            patternArray[0][30] = null;             
            patternArray[0][31] = null; 


            // Pattern one:
            //patternArray[0][0] = new Note(46, 64, 4);
            //patternArray[0][4] = new Note(45, 64, 4);
            //patternArray[0][8] = new Note(43, 64, 8);

            // Pattern two (I'm using concat to make a duplicate
            //              of the previous array as opposed to 
            //              making a reference to it):
            patternArray[1] = patternArray[0].concat();
            patternArray[1][12] = new Note(48, 64, 4);

            // Pattern three:
            patternArray[2] = patternArray[1].concat();
            patternArray[2][14] = new Note(49, 64, 2);

            // Pattern four:
            patternArray[3] = patternArray[2].concat();
            patternArray[3][2] = new Note(50, 64, 2);

            // Pattern five:
            patternArray[4] = patternArray[3].concat();
            patternArray[4][6] = new Note(41, 64, 2);

            // Pattern six:
            patternArray[5] = patternArray[4].concat();
            patternArray[5][7] = new Note(42, 64, 1);
            
            // Pattern seven:
            patternArray[6] = patternArray[5].concat();
            patternArray[6][10] = new Note(45, 64, 2);

            // TODO need twelve of these patterns

            // Set up the volume
            patternSequencer.volume = 0.1;

            // Set the voice
            patternSequencer.voice = presetVoice["valsound.lead32"];

            // Set up listeners for the beat
            driver.setBeatCallbackInterval(1);
            driver.addEventListener(SiONTrackEvent.BEAT, onBeat);
            driver.setTimerInterruption(1, onTimerInterruption);

            // Start the rhythm loop playing (necessary for BEAT track events)
            beatCounter = 0;
            driver.play(rhythmLoop);
		}
		
		public static function play (sound:String):void
		{
			if (! _mute) {
				Audio[sound].playCachedMutation();
			}
		}

        public static function incrementMusic():void
        {
            patternIndex++;
            if (patternIndex >= patternArray.length)
            {
                patternIndex = 0;
            }
            patternCurrent = patternArray[patternIndex];
            patternChanged = true;
            trace("music incrementing to");
            trace(patternIndex);
        }

        // Getter and setter for portamento property
        public static function get portamento (): Boolean {return _sequencerPortamento;}

        public static function set portamento (newValue:Boolean): void
        {
            if (_sequencerPortamento == newValue) return;

            _sequencerPortamento = newValue;

            // Set portamento
            patternSequencer.portament = _sequencerPortamento ? 2: 0;

            trace(_sequencerPortamento ? "Portamento on!" : "Portamento off!");
        }

		
		// Getter and setter for mute property
		
		public static function get mute (): Boolean { return _mute; }
		
		public static function set mute (newValue:Boolean): void
		{
			if (_mute == newValue) return;
			
			_mute = newValue;

            if (_mute)
            {
                patternSequencer.stop();
            }

            if (!_mute) patternChanged = true;
			
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
                    patternSequencer.sequencer.pattern = patternCurrent;
                    trace("pattern changed!");

                    // Play if necessary and not muted
                    if (!patternSequencer.isPlaying && !_mute)
                    {
                        patternSequencer.play();
                        trace("pattern now playing");
                    }
                }
            }
            beatCounter++;
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

