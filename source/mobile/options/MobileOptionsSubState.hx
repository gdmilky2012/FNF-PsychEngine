package mobile.options;

import mobile.backend.MobileScaleMode;
import options.BaseOptionsMenu;
import options.Option;

class MobileOptionsSubState extends BaseOptionsMenu
{
	#if android
	var storageTypes:Array<String> = ["EXTERNAL","EXTERNAL_DATA", "EXTERNAL_OBB", "EXTERNAL_MEDIA"];
	var externalPaths:Array<String> = SUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.data.storageType;
	#end

	public function new()
	{
		#if android if (!externalPaths.contains('\n')) storageTypes = storageTypes.concat(externalPaths); #end
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu'; // for Discord Rich Presence, fuck it

		var option:Option = new Option('Controls alpha',
		    'How visible you want the virtual pad to be',
		    'controlsAlpha',
		    'float');
        option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			_virtualpad.alpha = curOption.getValue();
		};
		addOption(option);

		#if mobile
		var option:Option = new Option('Allow Phone Screensaver',
		    'If checked, the phone will sleep after going inactive for few seconds.',
		    'screensaver', 
		    'bool');
		option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue(); 
		addOption(option);

		var option:Option = new Option('Wide Screen Mode',
		    'If checked, The game will stetch to fill your whole screen. (WARNING: Can result in bad visuals & break some mods that resizes the game/cameras)',
		    'wideScreen',
			'bool');
		option.onChange = () -> FlxG.scaleMode = new MobileScaleMode();
		addOption(option);
		#end

		var option:Option = new Option('Hide Hitbox Hints',
		    'If checked, makes the hitbox invisible.',
		    'hideHitboxHints',
		    'bool');
		addOption(option);

		var option:Option = new Option('Arrow-Only Hitbox',
		    'If checked, touch zones are only as big as the arrows (no press effect). Unchecked = normal full-column hitbox.',
		    'arrowOnlyHitbox',
		    'bool');
		addOption(option);

		var option:Option = new Option('Dynamic Color',
		    'If checked, the hitbox will use the color of the notes, else it will use the default color in extrakeys.json',
		    'dynamicColors',
		    'bool');
		addOption(option);

		#if android
		var option:Option = new Option('Storage Type',
		    'Which folder Psych Engine should use?\n(CHANGING THIS MAKES DELETE YOUR OLD FOLDER!!)',
		    'storageType',
		    'string',
		    storageTypes);
		addOption(option);
		#end

		super();
	}
	#if android
	function onStorageChange():Void
	{
		File.saveContent(lime.system.System.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.data.storageType);

		var lastStoragePath:String = StorageType.fromStrForce(lastStorageType) + '/';

		try
		{
			Sys.command('rm', ['-rf', lastStoragePath]);
		}
		catch (e:haxe.Exception)
			trace('Failed to remove last directory. (${e.message})');
	}
	#end
	override public function destroy()
	{
		super.destroy();
		#if android
		if (ClientPrefs.data.storageType != lastStorageType)
		{
			onStorageChange();
			SUtil.showPopUp('Storage Type has been changed and you needed restart the game!!\nPress OK to close the game.', 'Notice!');
			lime.system.System.exit(0);
		}
		#end
	}
}
