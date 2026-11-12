package mods.mod_hub_ui;

import brain.assetRepository.AssetLoadingComponent;
import brain.assetRepository.SwfAsset;
import facade.DBFacade;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
 * The hub's furniture, taken from the game itself: the town popup frame and its prompt buttons, and
 * the fonts the game's popups and nametags use.
 */
class HubArt {
	static inline final TOWN_SWF = "Resources/Art2D/UI/db_UI_town.swf";

	static inline final NAMETAG_SWF = "Resources/Art2D/UI/db_UI_nametag.swf";

	/** The game's text outline, as on its nametags. */
	static inline final GLOW = 0x330000;

	var loader:AssetLoadingComponent;

	var town:Null<SwfAsset>;

	var bodyFont:String = "_sans";

	var titleFont:Null<String>;

	var titleEmbedded:Bool = false;

	/** True once the town art is in: the popup and its buttons can be built. */
	public var ready(get, never):Bool;

	public function new(facade:DBFacade) {
		loader = new AssetLoadingComponent(facade);
		loader.getSwfAsset(DBFacade.buildFullDownloadPath(NAMETAG_SWF), function(asset:SwfAsset) {
			var type:Dynamic = asset.getClass("UI_widget");
			var sample:MovieClip = type == null ? null : cast ASCompat.createInstance(type, []);
			var alert = sample == null ? null : sample.getChildByName("AlertText");
			if (Std.isOfType(alert, TextField)) {
				var field:TextField = cast alert;
				titleFont = field.defaultTextFormat.font;
				titleEmbedded = field.embedFonts;
			}
		});
		loader.getSwfAsset(DBFacade.buildFullDownloadPath(TOWN_SWF), function(asset:SwfAsset) {
			var popupType:Dynamic = asset.getClass("popup");
			var sample:MovieClip = popupType == null ? null : cast ASCompat.createInstance(popupType, []);
			var body = sample == null ? null : sample.getChildByName("message_label");
			if (Std.isOfType(body, TextField))
				bodyFont = (cast body : TextField).defaultTextFormat.font;
			town = asset;
		});
	}

	function get_ready():Bool {
		return town != null;
	}

	/** The game's town popup: a frame (`popup_base`), a banner and its title, a close button. */
	public function popup():MovieClip {
		return townSymbol("popup");
	}

	/** The game's prompt button: `up`, `over` and `disabled` states, and a `label`. */
	public function button():MovieClip {
		return townSymbol("UI_prompt_button_extended");
	}

	function townSymbol(name:String):MovieClip {
		var type:Dynamic = town == null ? null : town.getClass(name);
		return type == null ? null : cast ASCompat.createInstance(type, []);
	}

	/** A label in the game's comic font, or else its bold one, to go in `outlined()`. */
	public function text(title:Bool, size:Int, color:Int, width:Float, align:TextFormatAlign):TextField {
		var field = label(width, size * 1.7);
		field.embedFonts = titleEmbedded;
		var format = new TextFormat(title && titleFont != null ? titleFont : bodyFont, size, color);
		format.align = align;
		field.defaultTextFormat = format;
		return field;
	}

	/** A layer for labels, outlined as the game's popups are: one outline for them all. */
	public static function outlined():Sprite {
		var layer = new Sprite();
		layer.mouseEnabled = false;
		layer.mouseChildren = false;
		layer.filters = [new GlowFilter(GLOW, 1, 4, 4, 4)];
		return layer;
	}

	static function label(width:Float, height:Float):TextField {
		var field = new TextField();
		field.selectable = false;
		field.mouseEnabled = false;
		field.width = width;
		field.height = height;
		return field;
	}

	public function destroy():Void {
		loader.destroy();
		town = null;
	}
}
