package mods.mod_hub_ui;

import brain.uI.UIButton;
import facade.DBFacade;
import haxe.Timer;
import mods.api.Context;
import mods.api.Mod;
import mods.mod_hub_api.Hub;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.events.Event;
import openfl.geom.Point;
import stateMachine.mainStateMachine.TownState;
import town.HomeState;
import town.TownStateMachine;

/** The hub shell: one key, one list of the panels and options other mods registered. */
@:privateAccess
class Main extends Mod {
	static inline final ESC:UInt = 27;

	var ctx:Context;

	var facade:DBFacade;

	var art:HubArt;

	var panel:Panel;

	var settings:Settings;

	var hubIcon:BitmapData;

	var townButton:TownHubButton;

	var townOptions:DisplayObject;

	var lastTownCheck:Float = 0;

	var frameLogged:Bool = false;

	var inTown:Bool = false;

	var diag:String = "";

	override public function init(context:Context):Void {
		ctx = context;
		try {
			Log.start(ctx.data);
		} catch (error:Dynamic) {}
		settings = new Settings(ctx.data, ctx.log);
		settings.key = HubKeys.normalize(settings.key);
		Strings.lang = settings.language;
		Hub.setLanguage(settings.language);
		Hub.onChanged(changed);
		Hub.onLanguageChanged(languageChanged);
		registerSelf();
		ctx.onKeyDown(onKey);
		Log.write("init language=" + Strings.lang + " key=" + settings.key);
	}

	override public function ready(context:Context):Void {
		facade = context.core.facade;
		art = new HubArt(facade);
		try {
			hubIcon = BitmapData.fromFile(ctx.resources + "/icono.png");
			Log.write("town icon loaded " + hubIcon.width + "x" + hubIcon.height);
		} catch (error:Dynamic) {
			Log.write("town icon failed: " + Std.string(error));
		}
		ctx.overlay.addEventListener(Event.ENTER_FRAME, onFrame);
		ctx.onTownEnter(function():Void {
			inTown = true;
			diag = "";
			note("town enter event");
			lastTownCheck = 0;
			checkTown();
		});
		ctx.onTownExit(function():Void {
			inTown = false;
			diag = "";
			destroyTownButton();
		});
		checkTown();
		Log.write("ready view=" + ctx.viewWidth + "x" + ctx.viewHeight + " entries=" + Hub.all().length + " language=" + Strings.lang);
	}

	override public function dispose():Void {
		Hub.offChanged(changed);
		Hub.offLanguageChanged(languageChanged);
		Hub.unregister("mod_hub_ui");
		if (ctx != null && ctx.overlay != null)
			ctx.overlay.removeEventListener(Event.ENTER_FRAME, onFrame);
		destroyTownButton();
		if (panel != null) {
			panel.close();
			panel = null;
		}
		if (art != null) {
			art.destroy();
			art = null;
		}
		if (hubIcon != null) {
			hubIcon.dispose();
			hubIcon = null;
		}
	}

	function onFrame(event:Event):Void {
		if (!frameLogged) {
			frameLogged = true;
			Log.write("town frame listener is polling");
		}
		var now = Timer.stamp();
		if (now - lastTownCheck < 0.5)
			return;
		lastTownCheck = now;
		checkTown();
	}

	/** Never lets a layout error kill the polling; on failure, the fixed fallback still appears. */
	function checkTown():Void {
		try {
			checkTownInner();
		} catch (error:Dynamic) {
			Log.write("town check failed: " + Std.string(error));
			if (inTown)
				ensureFallback();
		}
	}

	/** Finds the town options gear and puts the hub plaque just above it. */
	function checkTownInner():Void {
		if (facade == null) {
			destroyTownButton();
			return;
		}
		if (!isHomeState()) {
			destroyTownButton();
			return;
		}

		var options:Dynamic = findByName(facade.stageRef, "options_button");
		if (options == null)
			options = findInHome();
		if (options == null) {
			note("town options_button not found");
			if (inTown)
				ensureFallback();
			else
				destroyTownButton();
			return;
		}
		if (!Std.isOfType(options, MovieClip)) {
			note("town options_button is not a MovieClip");
			if (inTown)
				ensureFallback();
			else
				destroyTownButton();
			return;
		}
		var clip:MovieClip = cast options;
		var fallbackX = ctx.viewWidth - 190;
		var fallbackY = ctx.viewHeight * 0.09;
		if (fallbackY < 4)
			fallbackY = 4;
		var x = fallbackX;
		var y = fallbackY;
		try {
			var global = clip.getBounds(facade.stageRef);
			var topLeft = ctx.overlay.globalToLocal(new Point(global.x, global.y));
			var size = 62;
			if (global.width > 0 && !Math.isNaN(global.width)) {
				x = topLeft.x + (global.width - size) / 2;
				y = topLeft.y - size - 8;
			}
			if (y < 4)
				y = 4;
		} catch (error:Dynamic) {
			Log.write("town bounds failed: " + Std.string(error));
		}

		placeTownButton(clip, x, y, "above gear");
	}

	function ensureFallback():Void {
		if (!inTown || ctx.viewWidth <= 0 || ctx.viewHeight <= 0)
			return;
		var x = ctx.viewWidth - 190;
		var y = ctx.viewHeight * 0.09;
		if (y < 4)
			y = 4;
		placeTownButton(null, x, y, "fallback");
	}

	function placeTownButton(clip:MovieClip, x:Float, y:Float, label:String):Void {
		if (townButton != null && townButton.root.parent == ctx.overlay && townOptions == clip) {
			townButton.root.x = x;
			townButton.root.y = y;
			return;
		}
		destroyTownButton();

		var button:TownHubButton;
		try {
			button = new TownHubButton(openHub, hubIcon);
		} catch (error:Dynamic) {
			Log.write("town button failed with icon: " + Std.string(error));
			try {
				button = new TownHubButton(openHub, null);
			} catch (second:Dynamic) {
				Log.write("town button failed: " + Std.string(second));
				return;
			}
		}
		button.root.x = x;
		button.root.y = y;
		try {
			ctx.overlay.addChild(button.root);
		} catch (error:Dynamic) {
			Log.write("town overlay add failed: " + Std.string(error));
			button.destroy();
			return;
		}
		townButton = button;
		townOptions = clip;
		Log.write("town hub button " + label + " at " + Std.int(x) + "," + Std.int(y));
	}

	/** Only the town's home screen owns this button, not the map/dungeon screens. */
	function isHomeState():Bool {
		if (facade == null || facade.mainStateMachine == null)
			return false;
		var mainState = facade.mainStateMachine;
		if (mainState.currentStateName != "TownState")
			return false;
		var town:TownState = Std.isOfType(mainState.currentState, TownState) ? cast mainState.currentState : null;
		if (town == null || town.townStateMachine == null)
			return false;
		return town.townStateMachine.currentStateName == "HomeState";
	}

	function findInHome():Dynamic {
		var mainState = facade.mainStateMachine;
		if (mainState == null) {
			note("town: no main state");
			return null;
		}
		if (mainState.currentStateName != "TownState") {
			note("town: main state " + mainState.currentStateName);
			return null;
		}
		var town:TownState = Std.isOfType(mainState.currentState, TownState) ? cast mainState.currentState : null;
		if (town == null) {
			note("town: current state is not TownState");
			return null;
		}
		if (town.townStateMachine == null) {
			note("town: no town state machine");
			return null;
		}
		var machine:TownStateMachine = town.townStateMachine;
		var home:HomeState = machine.mHomeState;
		if (home == null) {
			note("town: no HomeState");
			return null;
		}
		var root:MovieClip = home.mRootMovieClip;
		if (root == null) {
			note("town: HomeState has no root movie");
			return null;
		}

		// The real, displayed button is the child. `mOptionsButton.root` can be a detached wrapper.
		var options:Dynamic = root.getChildByName("options_button");
		if (options == null)
			options = untyped root.options_button;
		if (options == null)
			options = Reflect.field(root, "options_button");
		if (options != null) {
			note("town: using HomeState child options_button");
			return options;
		}

		var button:UIButton = home.mOptionsButton;
		if (button != null && button.root != null && button.root.parent != null && Std.isOfType(button.root, MovieClip)) {
			note("town: using HomeState options button");
			return button.root;
		}
		note("town: HomeState root has no options_button (" + root.numChildren + " children)");
		return null;
	}

	function findByName(container:DisplayObjectContainer, name:String):DisplayObject {
		if (container == null)
			return null;
		var direct = container.getChildByName(name);
		if (direct != null)
			return direct;
		var i = 0;
		while (i < container.numChildren) {
			var child = container.getChildAt(i);
			if (Std.isOfType(child, DisplayObjectContainer)) {
				var found = findByName(cast child, name);
				if (found != null)
					return found;
			}
			i++;
		}
		return null;
	}

	function note(text:String):Void {
		if (diag == text)
			return;
		diag = text;
		if (text != null && text != "")
			Log.write(text);
	}

	function destroyTownButton():Void {
		if (townButton == null)
			return;
		if (townButton.root.parent != null)
			townButton.root.parent.removeChild(townButton.root);
		townButton.destroy();
		townButton = null;
		townOptions = null;
	}

	function changed():Void {
		Log.write("changed entries=" + Hub.all().length);
		if (panel != null)
			panel.refresh();
	}

	function languageChanged():Void {
		var changed = Strings.lang != Hub.language;
		Strings.lang = Hub.language;
		if (changed) {
			settings.language = Hub.language;
			settings.save();
		}
		registerSelf();
		if (panel != null)
			panel.rebuild();
	}

	/** The hub lists itself so its key can be changed from OPTIONS like any other mod. */
	function registerSelf():Void {
		Hub.register({
			id: "mod_hub_ui",
			name: Strings.t("hub_name"),
			description: Strings.t("hub_description"),
			category: "Tools",
			order: 0,
			status: function():String {
				return Strings.f("hub_status", settings.key);
			},
			settings: [
				{
					id: "key",
					label: Strings.t("hub_key"),
					description: Strings.t("hub_key_description"),
					type: "key",
					get: function():Dynamic {
						return settings.key;
					},
					set: function(value:Dynamic):Void {
						var next = HubKeys.normalize(Std.string(value));
						if (next == settings.key)
							return;
						settings.key = next;
						settings.save();
						if (panel != null)
							panel.updateKey(next);
						Hub.notifyChanged();
					}
				}
			]
		});
	}

	function hubKeyCode():UInt {
		return HubKeys.code(settings.key);
	}

	function openHub():Void {
		if (panel != null)
			return;
		if (ctx.viewWidth <= 0 || ctx.viewHeight <= 0)
			return;
		if (facade == null || art == null || !art.ready) {
			Log.write("hub art is not ready yet");
			return;
		}
		panel = new Panel(ctx.overlay, ctx.viewWidth, ctx.viewHeight, facade, art, settings, function():Void {
			panel = null;
		});
	}

	function onKey(key:UInt):Bool {
		if (panel != null && panel.isCapturingKey()) {
			if (key == ESC)
				panel.cancelKeyCapture();
			else
				panel.captureKey(key);
			return true;
		}
		if (key == hubKeyCode()) {
			if (panel != null) {
				panel.close();
				panel = null;
				return true;
			}
			openHub();
			return true;
		}
		if (panel != null) {
			if (key == ESC) {
				if (panel.isSettings())
					panel.back();
				else
					panel.close();
			}
			return true;
		}
		return false;
	}
}
