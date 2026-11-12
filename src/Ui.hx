package mods.mod_hub_ui;

import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/** The colours and the labels the panel is drawn with. */
class Ui {
	public static inline final GOLD = 0xF2C14E;

	public static inline final GOLD_DARK = 0x8C6A2A;

	public static inline final PARCHMENT = 0x3A2412;

	public static inline final PANEL = 0x241408;

	public static inline final INK = 0x120A04;

	public static inline final TEXT = 0xFFF1D0;

	public static inline final DIM = 0xC4A87C;

	public static inline final GREEN = 0x8CE05E;

	public static inline final RED = 0xE8704A;

	public static inline final BLUE = 0x8CC8FF;

	public static function text(size:Int, color:Int, width:Float, align:TextFormatAlign, wrap:Bool = false):TextField {
		var field = new TextField();
		field.width = width;
		field.height = size * (wrap ? 2.8 : 2.0);
		field.selectable = false;
		field.mouseEnabled = false;
		field.multiline = wrap;
		field.wordWrap = wrap;
		field.defaultTextFormat = new TextFormat("_sans", size, color, true, null, null, null, null, align);
		field.filters = [new GlowFilter(INK, 1, 4, 4, 4)];
		return field;
	}

	public static function set(field:TextField, value:String):Void {
		if (field != null && field.text != value)
			field.text = value;
	}
}
