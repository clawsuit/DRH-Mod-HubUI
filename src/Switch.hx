package mods.mod_hub_ui;

import openfl.display.Sprite;
import openfl.events.MouseEvent;

/**
 * A small toggle switch in the game's palette: dark brown track, gold rim, green knob.
 * The hub draws it itself, so the settings API stays the same.
 */
class Switch {
	public var root(default, null):Sprite;

	var width:Float;

	var height:Float;

	var knob:Float;

	var on:Bool;

	var action:Bool->Void;

	var over:Bool = false;

	public function new(value:Bool, action:Bool->Void, width:Float = 64, height:Float = 30) {
		on = value;
		this.action = action;
		this.width = width;
		this.height = height;
		knob = height - 6;
		root = new Sprite();
		root.buttonMode = true;
		root.addEventListener(MouseEvent.MOUSE_DOWN, swallow);
		root.addEventListener(MouseEvent.CLICK, click);
		root.addEventListener(MouseEvent.ROLL_OVER, enter);
		root.addEventListener(MouseEvent.ROLL_OUT, leave);
		paint();
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
		on = !on;
		paint();
		if (action != null)
			action(on);
	}

	public function setValue(value:Bool):Void {
		if (on == value)
			return;
		on = value;
		paint();
	}

	function paint():Void {
		var g = root.graphics;
		g.clear();

		g.beginFill(0x000000, 0.28);
		g.drawRoundRect(0, 2, width, height, height / 2, height / 2);
		g.endFill();

		var border = over ? 0xFFD45A : (on ? 0xC08A3E : 0x6B4A22);
		var fill = on ? (over ? 0x3A1E0A : 0x2A1608) : (over ? 0x241408 : 0x1A1008);
		var rim = 1.5;

		// Two nested pills: the outer one is the thinner brown/gold rim, the inner one the track.
		g.beginFill(border, 1);
		g.drawRoundRect(0, 0, width, height, height / 2, height / 2);
		g.endFill();
		g.beginFill(fill, 1);
		g.drawRoundRect(rim, rim, width - rim * 2, height - rim * 2, (height - rim * 2) / 2, (height - rim * 2) / 2);
		g.endFill();

		var radius = knob / 2;
		var centerX = on ? width - 3 - radius : 3 + radius;
		var centerY = height / 2;
		g.lineStyle(2, on ? 0x0B5E0B : 0x0A3A0A, 1);
		g.beginFill(on ? (over ? 0x4DF04D : 0x2ECC40) : 0x1B5E20, 1);
		g.drawCircle(centerX, centerY, radius);
		g.endFill();
	}

	public function destroy():Void {
		root.removeEventListener(MouseEvent.MOUSE_DOWN, swallow);
		root.removeEventListener(MouseEvent.CLICK, click);
		root.removeEventListener(MouseEvent.ROLL_OVER, enter);
		root.removeEventListener(MouseEvent.ROLL_OUT, leave);
	}
}
