package backend;

import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	#if android
	var _hitbox:FlxHitbox;
	var _virtualpad:FlxVirtualPad;

	public function addHitbox(?keyCount:Int = 3) {
		_hitbox = new FlxHitbox(keyCount);

		var camMobile = new FlxCamera();
	    camMobile.bgColor.alpha = 0;
		FlxG.cameras.add(camMobile, false);

		_hitbox.cameras = [camMobile];
 		add(_hitbox);
	}

	var _touchMenu:mobile.flixel.TouchMenuInput;

	public function addVirtualPad(?dpad:FlxDPadMode, ?action:FlxActionMode) {
		_virtualpad = new FlxVirtualPad(dpad, action);

		if (mobile.flixel.TouchMenuInput.enabledFor(this)) {
			// Mode sentuh: vpad disembunyikan, gestur layar yang menggerakkan tombolnya
			_virtualpad.visible = false;
			add(_virtualpad);
			_touchMenu = new mobile.flixel.TouchMenuInput(_virtualpad);
			add(_touchMenu);
		} else {
			_virtualpad.alpha = ClientPrefs.data.controlsAlpha;
			add(_virtualpad);
		}
	}

	public function removeVirtualPad() {
		remove(_virtualpad);
		if (_touchMenu != null) {
			remove(_touchMenu);
			_touchMenu = null;
		}
	}

	public function addVPadCam() {
		var camMobile = new FlxCamera();
		camMobile.bgColor.alpha = 0;
		FlxG.cameras.add(camMobile, false);
		
		_virtualpad.cameras = [camMobile];
		if (_touchMenu != null) _touchMenu.cameras = [camMobile];
	}
    
	public function closeSs() {
		FlxTransitionableState.skipNextTransOut = true;
		FlxG.resetState();
	}
	#end

	inline function get_controls():Controls
		return Controls.instance;

	override function update(elapsed:Float)
	{
		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
	
	public function sectionHit():Void
	{
		//yep, you guessed it, nothing again, dumbass
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
