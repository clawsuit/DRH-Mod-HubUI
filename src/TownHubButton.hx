package mods.mod_hub_ui;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.MouseEvent;

/**
 * The little hub button in town, above the game's options gear. It uses the settings button's brown
 * and gold palette, and the uploaded icon when there is one.
 */
class TownHubButton {
	static inline final SIZE = 62.0;

	static inline final ICON = 48.0;

	public var root(default, null):Sprite;

	var onOpen:Void->Void;

	var icon:BitmapData;

	var over:Bool = false;

	public function new(onOpen:Void->Void, icon:BitmapData = null) {
		this.onOpen = onOpen;
		this.icon = icon;
		root = new Sprite();
		root.buttonMode = true;
		root.addEventListener(MouseEvent.MOUSE_DOWN, swallow);
		root.addEventListener(MouseEvent.CLICK, click);
		root.addEventListener(MouseEvent.ROLL_OVER, enter);
		root.addEventListener(MouseEvent.ROLL_OUT, leave);
		paint();
		addIcon();
	}

	static function swallow(event:MouseEvent):Void {
		event.stopImmediatePropagation();
	}

	function enter(event:MouseEvent):Void {
		over = true;
		paint();
	}

	function leave(event:MouseEvent):Void {
		over = false;
		paint();
	}

	function click(event:MouseEvent):Void {
		event.stopImmediatePropagation();
		if (onOpen != null)
			onOpen();
	}

	function paint():Void {
		var g = root.graphics;
		g.clear();

		g.beginFill(0x000000, 0.4);
		g.drawRoundRect(0, 3, SIZE, SIZE, 14, 14);
		g.endFill();

		// The settings gear's brown plaque and warm gold rim.
		var border = over ? 0xFFD06A : 0xEFAF4A;
		var fill = over ? 0x3A1E0A : 0x2A1608;
		g.lineStyle(3, border, 1);
		g.beginFill(fill, over ? 0.96 : 0.92);
		g.drawRoundRect(0, 0, SIZE, SIZE, 14, 14);
		g.endFill();

		if (icon == null) {
			var cell = 16.0;
			var gap = 4.0;
			var start = (SIZE - (cell * 2 + gap)) / 2;
			var row = 0;
			while (row < 2) {
				var col = 0;
				while (col < 2) {
					var x = start + col * (cell + gap);
					var y = start + row * (cell + gap);
					var green = row == 0 && col == 1;
					g.lineStyle(2, border, 1);
					g.beginFill(green ? (over ? 0x4DF04D : 0x2ECC40) : 0x1A1008, 1);
					g.drawRoundRect(x, y, cell, cell, 4, 4);
					g.endFill();
					col++;
				}
				row++;
			}
		}
	}

	function addIcon():Void {
		if (icon == null)
			return;
		var bitmap = new Bitmap(icon);
		bitmap.smoothing = true;
		var scale = ICON / Math.max(icon.width, icon.height);
		bitmap.scaleX = bitmap.scaleY = scale;
		bitmap.x = (SIZE - bitmap.width) / 2;
		bitmap.y = (SIZE - bitmap.height) / 2;
		root.addChild(bitmap);
	}

	public function destroy():Void {
		root.removeEventListener(MouseEvent.MOUSE_DOWN, swallow);
		root.removeEventListener(MouseEvent.CLICK, click);
		root.removeEventListener(MouseEvent.ROLL_OVER, enter);
		root.removeEventListener(MouseEvent.ROLL_OUT, leave);
	}
}
