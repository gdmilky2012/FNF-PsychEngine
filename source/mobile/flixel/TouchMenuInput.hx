package mobile.flixel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/**
 * Kontrol menu lewat layar sentuh sebagai pengganti vpad.
 *  - Geser atas/bawah/kiri/kanan = tombol arah
 *  - Ketuk (tap)                 = A (pilih)
 *  - Ketuk dua jari              = B (kembali)
 *  - Tahan jari ~0,6 detik       = tampilkan palet tombol aksi tambahan (X, Y, C, Z, ...)
 *                                  yang dipakai layar itu; ketuk salah satunya untuk memakainya.
 *
 * Vpad asli tetap dibuat (tersembunyi) agar semua menu yang memeriksa
 * _virtualpad.buttonX.justPressed tetap berfungsi tanpa diubah satu per satu.
 */
class TouchMenuInput extends FlxSpriteGroup
{
	static inline var START_DIST:Float = 60; // jarak geser pertama (piksel game)
	static inline var STEP_DIST:Float = 85; // jarak tiap langkah berikutnya saat jari terus digeser
	static inline var TAP_SLOP:Float = 30; // toleransi gerak untuk dianggap ketukan / tahan
	static inline var TAP_TIME:Float = 0.35; // batas lama ketukan (detik)
	static inline var LONG_PRESS:Float = 0.6; // lama tahan untuk membuka palet (detik)
	static inline var PALETTE_TIME:Float = 4; // palet menutup sendiri setelah (detik)
	static inline var CHIP_SIZE:Int = 96;
	static inline var CHIP_GAP:Int = 16;

	var pad:FlxVirtualPad;
	var pending:Array<FlxButton> = [];
	var extras:Array<FlxButton> = [];
	var chips:Array<FlxSprite> = [];

	var paletteOpen:Bool = false;
	var paletteTimer:Float = 0;

	var tracking:Bool = false;
	var swiped:Bool = false;
	var multi:Bool = false;
	var ignoreTouch:Bool = false;
	var startX:Float = 0;
	var startY:Float = 0;
	var anchorX:Float = 0;
	var anchorY:Float = 0;
	var threshold:Float = START_DIST;
	var held:Float = 0;

	public function new(pad:FlxVirtualPad)
	{
		super();
		this.pad = pad;
		scrollFactor.set();

		// Tombol aksi selain A/B/arah yang memang ada di vpad layar ini
		var candidates:Array<Array<Dynamic>> = [
			['X', pad.buttonX], ['Y', pad.buttonY], ['Z', pad.buttonZ], ['C', pad.buttonC], ['V', pad.buttonV],
			['D', pad.buttonD], ['E', pad.buttonE], ['F', pad.buttonF], ['G', pad.buttonG], ['S', pad.buttonS]
		];
		var labels:Array<String> = [];
		for (c in candidates)
		{
			var btn:FlxButton = c[1];
			if (btn != null && pad.members.indexOf(btn) != -1)
			{
				extras.push(btn);
				labels.push(c[0]);
			}
		}

		var total:Int = extras.length * CHIP_SIZE + (extras.length > 0 ? (extras.length - 1) * CHIP_GAP : 0);
		var startPosX:Float = (FlxG.width - total) / 2;
		var posY:Float = FlxG.height - CHIP_SIZE - 40;
		for (i in 0...extras.length)
		{
			var cx:Float = startPosX + i * (CHIP_SIZE + CHIP_GAP);

			var chip:FlxSprite = new FlxSprite(cx, posY);
			chip.makeGraphic(CHIP_SIZE, CHIP_SIZE, 0xE6101018);
			chip.scrollFactor.set();
			add(chip);
			chips.push(chip);

			var txt:FlxText = new FlxText(cx, posY + 22, CHIP_SIZE, labels[i], 44);
			txt.alignment = CENTER;
			txt.color = FlxColor.WHITE;
			txt.scrollFactor.set();
			add(txt);
		}

		visible = false; // palet tersembunyi sampai ditahan lama
	}

	/** Editor tetap memakai vpad biasa karena butuh banyak tombol. */
	public static function enabledFor(state:Dynamic):Bool
	{
		var name:String = Type.getClassName(Type.getClass(state));
		return name.indexOf('.editors.') == -1;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Lepas tombol yang ditekan pada frame sebelumnya (satu frame = satu "justPressed")
		for (b in pending)
			@:privateAccess b.input.release();
		pending = [];

		if (paletteOpen)
		{
			paletteTimer -= elapsed;
			if (paletteTimer <= 0)
				hidePalette();
		}

		var list:Array<FlxTouch> = FlxG.touches.list;
		var down:Int = 0;
		for (t in list)
			if (t.pressed)
				down++;

		if (down == 0)
		{
			multi = false;
			ignoreTouch = false;
		}

		// Dua jari = kembali (B), sekali per sentuhan
		if (down >= 2)
		{
			if (!multi)
			{
				multi = true;
				hidePalette();
				press(pad.buttonB);
			}
			tracking = false;
			return;
		}
		if (multi || ignoreTouch)
			return;

		var touch:FlxTouch = null;
		for (t in list)
			if (t.pressed || t.justReleased)
			{
				touch = t;
				break;
			}

		if (touch == null)
		{
			tracking = false;
			return;
		}

		// Palet terbuka: ketuk chip = tekan tombolnya, ketuk di luar = tutup palet
		if (paletteOpen && touch.justPressed)
		{
			var hit:Int = chipAt(touch.screenX, touch.screenY);
			if (hit >= 0)
				press(extras[hit]);
			hidePalette();
			tracking = false;
			ignoreTouch = true;
			return;
		}

		if (touch.justPressed)
		{
			tracking = true;
			swiped = false;
			held = 0;
			threshold = START_DIST;
			startX = anchorX = touch.screenX;
			startY = anchorY = touch.screenY;
		}
		else if (tracking && touch.pressed)
		{
			held += elapsed;

			var moved:Float = Math.abs(touch.screenX - startX) + Math.abs(touch.screenY - startY);
			if (!swiped && extras.length > 0 && held >= LONG_PRESS && moved < TAP_SLOP)
			{
				showPalette();
				swiped = true;
				ignoreTouch = true;
				tracking = false;
				return;
			}

			var dx:Float = touch.screenX - anchorX;
			var dy:Float = touch.screenY - anchorY;

			if (Math.abs(dy) >= threshold && Math.abs(dy) >= Math.abs(dx))
			{
				// jari ke atas = turun ke item berikutnya
				press(dy < 0 ? pad.buttonDown : pad.buttonUp);
				step(touch);
			}
			else if (Math.abs(dx) >= threshold && Math.abs(dx) > Math.abs(dy))
			{
				press(dx < 0 ? pad.buttonRight : pad.buttonLeft);
				step(touch);
			}
		}
		else if (tracking && touch.justReleased)
		{
			tracking = false;
			var moved:Float = Math.abs(touch.screenX - startX) + Math.abs(touch.screenY - startY);
			if (!swiped && held < TAP_TIME && moved < TAP_SLOP)
				press(pad.buttonA);
		}
	}

	function showPalette():Void
	{
		paletteOpen = true;
		paletteTimer = PALETTE_TIME;
		visible = true;
	}

	function hidePalette():Void
	{
		paletteOpen = false;
		visible = false;
	}

	function chipAt(px:Float, py:Float):Int
	{
		for (i in 0...chips.length)
		{
			var c:FlxSprite = chips[i];
			if (px >= c.x && px <= c.x + c.width && py >= c.y && py <= c.y + c.height)
				return i;
		}
		return -1;
	}

	function step(touch:FlxTouch):Void
	{
		swiped = true;
		threshold = STEP_DIST;
		anchorX = touch.screenX;
		anchorY = touch.screenY;
	}

	function press(btn:FlxButton):Void
	{
		// Hanya tombol yang memang ada di vpad menu itu (sama seperti vpad asli)
		if (btn == null || pad.members.indexOf(btn) == -1)
			return;

		@:privateAccess btn.input.press();
		pending.push(btn);
	}
}
