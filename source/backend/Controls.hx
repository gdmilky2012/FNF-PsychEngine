package backend;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;

class Controls
{
	//Keeping same use cases on stuff for it to be easier to understand/use
	//I'd have removed it but this makes it a lot less annoying to use in my opinion

	//You do NOT have to create these variables/getters for adding new keys,
	//but you will instead have to use:
	//   controls.justPressed("ui_up")   instead of   controls.UI_UP

	//Dumb but easily usable code, or Smart but complicated? Your choice.
	//Also idk how to use macros they're weird as fuck lol

	// Pressed buttons (directions)
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_NOTE_UP_P() return justPressed('note_up');
	private function get_NOTE_DOWN_P() return justPressed('note_down');
	private function get_NOTE_LEFT_P() return justPressed('note_left');
	private function get_NOTE_RIGHT_P() return justPressed('note_right');

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_NOTE_UP() return pressed('note_up');
	private function get_NOTE_DOWN() return pressed('note_down');
	private function get_NOTE_LEFT() return pressed('note_left');
	private function get_NOTE_RIGHT() return pressed('note_right');

	// Released buttons (directions)
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_NOTE_UP_R() return justReleased('note_up');
	private function get_NOTE_DOWN_R() return justReleased('note_down');
	private function get_NOTE_LEFT_R() return justReleased('note_left');
	private function get_NOTE_RIGHT_R() return justReleased('note_right');


	// Pressed buttons (others)
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	private function get_ACCEPT() return justPressed('accept');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');
	private function get_RESET() return justPressed('reset');

	//Gamepad & Keyboard stuff
	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public function justPressed(key:String)
	{
		var result:Bool = (FlxG.keys.anyJustPressed(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result || _myGamepadJustPressed(gamepadBinds[key]) == true;
	}

	public function pressed(key:String)
	{
		var result:Bool = (FlxG.keys.anyPressed(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result || _myGamepadPressed(gamepadBinds[key]) == true;
	}

	public function justReleased(key:String)
	{
		var result:Bool = (FlxG.keys.anyJustReleased(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result || _myGamepadJustReleased(gamepadBinds[key]) == true;
	}

	public var controllerMode:Bool = false;
	private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for (key in keys)
			{
				if (gpJustPressed(key))
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}
	private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for (key in keys)
			{
				if (gpPressed(key))
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}
	private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for (key in keys)
			{
				if (gpJustReleased(key))
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	// ===== L2 / R2 =====
	// Trigger dibaca lewat nilai analog (> 0.5) atau tombol digital L2/R2, dihitung SEKALI per frame.
	// Ini menghindari trigger yang "menempel" ketika nilai diamnya -1 di sebagian gamepad Android,
	// dan membuat L2/R2 bisa dipakai untuk note, menu, maupun mapping.
	static var trigNow:Array<Bool> = [false, false];
	static var trigPrev:Array<Bool> = [false, false];
	static var trigHooked:Bool = false;

	public static function triggerPressed(i:Int):Bool return trigNow[i];
	public static function triggerJustPressed(i:Int):Bool return trigNow[i] && !trigPrev[i];
	public static function triggerJustReleased(i:Int):Bool return !trigNow[i] && trigPrev[i];

	static function updateTriggers():Void
	{
		trigPrev[0] = trigNow[0];
		trigPrev[1] = trigNow[1];
		var l:Bool = false;
		var r:Bool = false;
		for (i in 0...FlxG.gamepads.numActiveGamepads)
		{
			var pad = FlxG.gamepads.getByID(i);
			if (pad == null) continue;
			if (pad.getAxis(LEFT_TRIGGER) > 0.5 || pad.checkStatus(LEFT_TRIGGER_BUTTON, PRESSED)) l = true;
			if (pad.getAxis(RIGHT_TRIGGER) > 0.5 || pad.checkStatus(RIGHT_TRIGGER_BUTTON, PRESSED)) r = true;
		}
		trigNow[0] = l;
		trigNow[1] = r;
	}

	static function triggerIndex(key:FlxGamepadInputID):Int
	{
		return switch (key)
		{
			case LEFT_TRIGGER, LEFT_TRIGGER_BUTTON: 0;
			case RIGHT_TRIGGER, RIGHT_TRIGGER_BUTTON: 1;
			default: -1;
		}
	}

	static function gpJustPressed(key:FlxGamepadInputID):Bool
	{
		var t:Int = triggerIndex(key);
		return t >= 0 ? triggerJustPressed(t) : (FlxG.gamepads.anyJustPressed(key) == true);
	}

	static function gpPressed(key:FlxGamepadInputID):Bool
	{
		var t:Int = triggerIndex(key);
		return t >= 0 ? triggerPressed(t) : (FlxG.gamepads.anyPressed(key) == true);
	}

	static function gpJustReleased(key:FlxGamepadInputID):Bool
	{
		var t:Int = triggerIndex(key);
		return t >= 0 ? triggerJustReleased(t) : (FlxG.gamepads.anyJustReleased(key) == true);
	}

	// IGNORE THESE
	public static var instance:Controls;
	public function new()
	{
		keyboardBinds = ClientPrefs.keyBinds;
		gamepadBinds = ClientPrefs.gamepadBinds;

		if (!trigHooked)
		{
			trigHooked = true;
			FlxG.signals.preUpdate.add(updateTriggers);
		}
	}
}
