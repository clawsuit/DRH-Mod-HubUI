package mods.mod_hub_ui;

import brain.uI.UIButton;
import dBGlobals.DBGlobal;
import facade.DBFacade;
import mods.mod_hub_api.Hub;
import mods.mod_hub_api.HubEntry;
import mods.mod_hub_api.HubSetting;
import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;

/**
 * The hub window, built from the game's own town popup and prompt buttons.
 * The list, the settings form and the language button keep working the same.
 */
class Panel {
	static inline final W = 560.0;

	static inline final H = 380.0;

	/** The popup symbol keeps its frame centred here. */
	static inline final CX = 380.0;

	static inline final CY = 253.0;

	static inline final MARGIN = 40.0;

	static inline final LIST_ROWS = 6;

	static inline final SETTINGS_ROWS = 5;

	static inline final ROW = 46.0;

	static inline final ACTION_W = 120.0;

	static inline final ACTION_H = 24.0;

	static inline final HEADER_W = 100.0;

	static inline final HEADER_H = 20.0;

	static inline final SWITCH_W = 50.0;

	static inline final SWITCH_H = 22.0;

	static inline final GOLD = 0xFFCC00;

	static inline final WHITE = 0xFFFFFF;

	static inline final DIM = 0xB8A48C;

	var scale:Float = 1;

	var facade:DBFacade;

	var art:HubArt;

	var settings:Settings;

	var onClose:Void->Void;

	var viewWidth:Float;

	var viewHeight:Float;

	var overlayRef:Sprite;

	var holder:Sprite;

	var frame:MovieClip;

	var title:TextField;

	var subtitle:TextField;

	var pageLabel:TextField;

	var footer:TextField;

	var headerLabels:Sprite;

	var rowLabels:Sprite;

	var closeButton:UIButton;

	var langButton:UIButton;

	var prevButton:UIButton;

	var nextButton:UIButton;

	var backButton:UIButton;

	var rowButtons:Array<UIButton> = [];

	var switches:Array<Switch> = [];

	var shown:Bool = true;

	/** 0 the list, 1 the settings of one entry. */
	var mode:Int = 0;

	var page:Int = 0;

	var settingsPage:Int = 0;

	var settingsEntry:HubEntry;

	var activeEntry:HubEntry;

	var lastMessage:String = "";

	var lastColor:Int = DIM;

	var capturing:HubSetting;

	public function new(overlay:Sprite, width:Float, height:Float, facade:DBFacade, art:HubArt, settings:Settings,
			onClose:Void->Void) {
		this.facade = facade;
		this.art = art;
		this.settings = settings;
		this.onClose = onClose;
		viewWidth = width;
		viewHeight = height;
		overlayRef = overlay;
		scale = 1.8;
		var fitX = width * 0.92 / W;
		var fitY = height * 0.92 / H;
		if (fitX < scale)
			scale = fitX;
		if (fitY < scale)
			scale = fitY;
		if (scale < 0.8)
			scale = 0.8;
		build(overlay);
	}

	function build(overlay:Sprite):Void {
		frame = art.popup();
		layoutFrame();
		holder = new Sprite();
		var blocker = new Sprite();
		blocker.graphics.beginFill(0x000000, 0.01);
		blocker.graphics.drawRect(0, 0, viewWidth, viewHeight);
		blocker.graphics.endFill();
		holder.addChild(blocker);
		blocker.addEventListener(MouseEvent.MOUSE_DOWN, swallow);
		blocker.addEventListener(MouseEvent.CLICK, swallow);
		holder.addChild(frame);
		frame.scaleX = frame.scaleY = scale;
		frame.x = viewWidth / 2 - CX * scale;
		frame.y = viewHeight / 2 - CY * scale;
		overlay.addChild(holder);

		headerLabels = HubArt.outlined();
		frame.addChild(headerLabels);
		rowLabels = HubArt.outlined();
		frame.addChild(rowLabels);

		var top = CY - H / 2;
		var left = CX - W / 2 + MARGIN;
		var right = CX + W / 2 - MARGIN;

		subtitle = art.text(false, 11, DIM, W - 2 * MARGIN - 140, TextFormatAlign.LEFT);
		subtitle.x = left;
		subtitle.y = top + 30;
		headerLabels.addChild(subtitle);

		pageLabel = art.text(false, 11, DIM, 100, TextFormatAlign.RIGHT);
		pageLabel.y = top + 52;
		headerLabels.addChild(pageLabel);

		footer = art.text(false, 9, DIM, W - 2 * MARGIN, TextFormatAlign.LEFT);
		footer.x = left;
		footer.y = top + H - 22;
		headerLabels.addChild(footer);

		var headerY = top + 62;
		langButton = makeButton(Strings.lang == "es" ? "ES" : "EN", HEADER_W, HEADER_H, function():Void {
			toggleLanguage();
		});
		alignLeft(langButton, left, headerY);

		nextButton = makeButton(">", HEADER_W, HEADER_H, function():Void movePage(1));
		alignRight(nextButton, right, headerY);
		prevButton = makeButton("<", HEADER_W, HEADER_H, function():Void movePage(-1));
		alignRight(prevButton, nextButton.root.getBounds(frame).x - 8, headerY);
		pageLabel.x = prevButton.root.getBounds(frame).x - 106;

		backButton = makeButton(Strings.t("back"), ACTION_W, ACTION_H, function():Void {
			back();
		});
		backButton.root.visible = false;
		alignCenter(backButton, CX, top + H - 48);

		var cross = frame.getChildByName("close");
		if (Std.isOfType(cross, MovieClip)) {
			var clip:MovieClip = cast cross;
			clip.x = CX + W / 2 - 6;
			clip.y = top + 8;
			closeButton = new UIButton(facade, clip);
			closeButton.rolloverFilter = DBGlobal.UI_ROLLOVER_FILTER;
			closeButton.releaseCallback = function():Void {
				close();
			};
		}

		lastMessage = Strings.f("footer", settings.key);
		refresh();
	}

	/** The town popup, stretched to the hub. */
	function layoutFrame():Void {
		for (name in ["message_label", "left_button", "center_button", "right_button", "content"]) {
			var child = frame.getChildByName(name);
			if (child != null)
				child.visible = false;
		}
		var top = CY - H / 2;
		var base = frame.getChildByName("popup_base");
		if (base != null) {
			fit(base, W, H);
			base.x = CX;
			base.y = CY;
		}

		var banner = frame.getChildByName("banner_title_label");
		if (banner != null) {
			fit(banner, W * 0.7, banner.height * 1.3);
			banner.x = CX;
			banner.y = top - 4;
		}

		var titleField:TextField = cast frame.getChildByName("title_label");
		if (titleField != null) {
			var format = titleField.defaultTextFormat;
			format.size = 24;
			format.align = TextFormatAlign.CENTER;
			titleField.defaultTextFormat = format;
			titleField.width = W * 0.7;
			titleField.height = 40;
			titleField.x = CX - titleField.width / 2;
			titleField.y = (banner == null ? top : banner.y) - 16;
			title = titleField;
		}
	}

	static function fit(target:DisplayObject, width:Float, height:Float):Void {
		target.scaleX = target.scaleY = 1;
		target.scaleX = width / target.width;
		target.scaleY = height / target.height;
	}

	static function swallow(event:MouseEvent):Void {
		event.stopImmediatePropagation();
	}

	public function isShown():Bool {
		return shown;
	}

	public function isSettings():Bool {
		return mode == 1;
	}

	public function close():Void {
		if (!shown)
			return;
		closeActive();
		destroyVisual();
		shown = false;
		if (onClose != null)
			onClose();
	}

	public function back():Void {
		if (mode == 1) {
			mode = 0;
			settingsEntry = null;
			refresh();
			return;
		}
		close();
	}

	/** Rebuilds the frame after a language change; the open page is kept. */
	public function rebuild():Void {
		if (settingsEntry != null)
			settingsEntry = Hub.get(settingsEntry.id);
		if (activeEntry != null)
			activeEntry = Hub.get(activeEntry.id);
		destroyVisual();
		shown = true;
		build(overlayRef);
	}

	/** The hub key changed: the footer follows it. */
	public function updateKey(name:String):Void {
		lastMessage = Strings.f("footer", name);
		lastColor = DIM;
		refresh();
	}

	/** Rebuilds the visible page; the shell calls it when the registry changes. */
	public function refresh():Void {
		if (!shown)
			return;
		if (mode == 1 && settingsEntry != null) {
			Ui.set(title, safeName(settingsEntry));
			Ui.set(subtitle, safeDescription(settingsEntry));
			backButton.root.visible = true;
			renderSettings();
		} else {
			mode = 0;
			settingsEntry = null;
			Ui.set(title, Strings.t("title"));
			Ui.set(subtitle, Strings.t("subtitle"));
			backButton.root.visible = false;
			renderList();
		}
		Ui.set(footer, lastMessage);
		footer.textColor = lastColor;
	}

	function renderList():Void {
		clearRows();
		var list = Hub.all();
		var pages:Int = Std.int(Math.max(1, Math.ceil(list.length / LIST_ROWS)));
		if (page >= pages)
			page = pages - 1;
		if (page < 0)
			page = 0;
		Ui.set(pageLabel, Strings.f("page", Std.string(page + 1), Std.string(pages)));
		prevButton.enabled = page > 0;
		nextButton.enabled = page < pages - 1;

		var top = CY - H / 2;
		var left = CX - W / 2 + MARGIN;
		var right = CX + W / 2 - MARGIN;
		var rowTop = top + 78;

		if (list.length == 0) {
			var empty = art.text(false, 12, DIM, W - 2 * MARGIN, TextFormatAlign.CENTER);
			empty.text = Strings.t("empty");
			empty.y = rowTop + 80;
			rowLabels.addChild(empty);
			return;
		}

		var start = page * LIST_ROWS;
		var count = list.length - start;
		if (count > LIST_ROWS)
			count = LIST_ROWS;
		var i = 0;
		while (i < count) {
			addListRow(list[start + i], rowTop + i * ROW);
			i++;
		}
	}

	function addListRow(entry:HubEntry, y:Float):Void {
		var left = CX - W / 2 + MARGIN;
		var right = CX + W / 2 - MARGIN;
		var name = art.text(true, 14, GOLD, 220, TextFormatAlign.LEFT);
		name.text = safeName(entry);
		name.x = left;
		name.y = y + 3;
		rowLabels.addChild(name);

		var description = art.text(false, 9, WHITE, 220, TextFormatAlign.LEFT);
		description.text = safeDescription(entry);
		description.x = left;
		description.y = y + 19;
		rowLabels.addChild(description);

		var status = safeStatus(entry);
		if (status != null && status != "") {
			var statusField = art.text(false, 8, DIM, 220, TextFormatAlign.LEFT);
			statusField.text = status;
			statusField.x = left;
			statusField.y = y + 31;
			rowLabels.addChild(statusField);
		}

		var centerY = y + 23;
		var cursor = right;
		if (entry.settings != null && entry.settings.length > 0) {
			var options = makeButton(Strings.t("options"), ACTION_W, ACTION_H, function():Void openSettings(entry));
			alignRight(options, cursor, centerY);
			rowButtons.push(options);
			cursor = options.root.getBounds(frame).x - 8;
		}
		if (entry.open != null) {
			var open = makeButton(Strings.t("open"), ACTION_W, ACTION_H, function():Void openEntry(entry));
			alignRight(open, cursor, centerY);
			rowButtons.push(open);
		}
	}

	function renderSettings():Void {
		clearRows();
		if (settingsEntry == null || settingsEntry.settings == null || settingsEntry.settings.length == 0) {
			mode = 0;
			settingsEntry = null;
			refresh();
			return;
		}
		var list = settingsEntry.settings;
		var pages:Int = Std.int(Math.max(1, Math.ceil(list.length / SETTINGS_ROWS)));
		if (settingsPage >= pages)
			settingsPage = pages - 1;
		if (settingsPage < 0)
			settingsPage = 0;
		Ui.set(pageLabel, Strings.f("settings_page", Std.string(settingsPage + 1), Std.string(pages)));
		prevButton.enabled = settingsPage > 0;
		nextButton.enabled = settingsPage < pages - 1;

		var top = CY - H / 2;
		var left = CX - W / 2 + MARGIN;
		var right = CX + W / 2 - MARGIN;
		var rowTop = top + 78;
		var start = settingsPage * SETTINGS_ROWS;
		var count = list.length - start;
		if (count > SETTINGS_ROWS)
			count = SETTINGS_ROWS;
		var i = 0;
		while (i < count) {
			addSettingRow(list[start + i], rowTop + i * ROW);
			i++;
		}
	}

	function addSettingRow(setting:HubSetting, y:Float):Void {
		var left = CX - W / 2 + MARGIN;
		var right = CX + W / 2 - MARGIN;
		var label = art.text(true, 12, WHITE, 340, TextFormatAlign.LEFT);
		label.text = setting.label == null ? setting.id : setting.label;
		label.x = left;
		label.y = y + 3;
		rowLabels.addChild(label);

		if (setting.description != null && setting.description != "") {
			var description = art.text(false, 8, DIM, 340, TextFormatAlign.LEFT);
			description.text = setting.description;
			description.x = left;
			description.y = y + 19;
			rowLabels.addChild(description);
		}

		var centerY = y + 23;
		if (setting.type == "bool") {
			var value = safeGet(setting) == true;
			var toggle = new Switch(value, function(next:Bool):Void setBoolValue(setting, next), SWITCH_W, SWITCH_H);
			toggle.root.x = right - SWITCH_W;
			toggle.root.y = centerY - SWITCH_H / 2;
			frame.addChild(toggle.root);
			switches.push(toggle);
		} else if (setting.type == "key") {
			var current = Std.string(safeGet(setting));
			var keyButton = makeButton(current, ACTION_W, ACTION_H, function():Void beginKeyCapture(setting));
			alignRight(keyButton, right, centerY);
			rowButtons.push(keyButton);
		} else if (setting.type == "choice") {
			var current = Std.string(safeGet(setting));
			var choice = makeButton(choiceLabel(setting, current), ACTION_W, ACTION_H, function():Void cycleChoice(setting));
			alignRight(choice, right, centerY);
			rowButtons.push(choice);
		} else if (setting.type == "int") {
			var number = makeButton(Std.string(numeric(setting)), ACTION_W, ACTION_H, function():Void increment(setting));
			alignRight(number, right, centerY);
			rowButtons.push(number);
		}
	}

	function makeButton(text:String, targetWidth:Float, targetHeight:Float, callback:Void->Void):UIButton {
		var clip = art.button();
		clip.scaleX = clip.scaleY = 1;
		var ratio = Math.min(targetWidth / clip.width, targetHeight / clip.height);
		clip.scaleX = clip.scaleY = ratio;
		clip.x = 0;
		clip.y = 0;
		frame.addChild(clip);
		var button = new UIButton(facade, clip);
		button.label.text = text;
		button.rolloverFilter = DBGlobal.UI_ROLLOVER_FILTER;
		button.selectedFilter = DBGlobal.UI_SELECTED_FILTER;
		button.releaseCallback = callback;
		return button;
	}

	function alignRight(button:UIButton, right:Float, centerY:Float):Void {
		var rect = button.root.getBounds(frame);
		button.root.x += right - (rect.x + rect.width);
		button.root.y += centerY - (rect.y + rect.height / 2);
	}

	function alignLeft(button:UIButton, left:Float, centerY:Float):Void {
		var rect = button.root.getBounds(frame);
		button.root.x += left - rect.x;
		button.root.y += centerY - (rect.y + rect.height / 2);
	}

	function alignCenter(button:UIButton, centerX:Float, centerY:Float):Void {
		var rect = button.root.getBounds(frame);
		button.root.x += centerX - (rect.x + rect.width / 2);
		button.root.y += centerY - (rect.y + rect.height / 2);
	}

	function movePage(delta:Int):Void {
		if (mode == 1)
			settingsPage += delta;
		else
			page += delta;
		refresh();
	}

	function openSettings(entry:HubEntry):Void {
		if (entry == null || entry.settings == null || entry.settings.length == 0)
			return;
		Log.write("settings " + entry.id);
		settingsEntry = entry;
		settingsPage = 0;
		mode = 1;
		refresh();
	}

	function openEntry(entry:HubEntry):Void {
		if (entry == null || entry.open == null)
			return;
		Log.write("open " + entry.id);
		activeEntry = entry;
		holder.visible = false;
		var backToHub = function():Void {
			if (activeEntry == entry) {
				activeEntry = null;
				holder.visible = true;
				refresh();
			}
		};
		try {
			entry.open(backToHub);
		} catch (error:Dynamic) {
			activeEntry = null;
			holder.visible = true;
			setMessage(Strings.f("open_error", safeName(entry), Std.string(error)), 0xE8704A);
			refresh();
		}
	}

	function closeActive():Void {
		if (activeEntry == null)
			return;
		var entry = activeEntry;
		activeEntry = null;
		if (entry.close != null) {
			try {
				entry.close();
			} catch (error:Dynamic) {}
		}
	}

	function beginKeyCapture(setting:HubSetting):Void {
		capturing = setting;
		setMessage(Strings.t("press_key") + "  " + Strings.t("key_hint"), GOLD);
		Log.write("waiting for key setting " + setting.id);
	}

	public function isCapturingKey():Bool {
		return capturing != null;
	}

	public function cancelKeyCapture():Void {
		capturing = null;
		lastMessage = Strings.f("footer", settings.key);
		lastColor = DIM;
		refresh();
	}

	public function captureKey(key:UInt):Void {
		if (capturing == null)
			return;
		var name = HubKeys.name(key);
		if (name == null) {
			setMessage(Strings.t("key_invalid") + "  " + Strings.t("key_hint"), 0xE8704A);
			return;
		}
		var setting = capturing;
		capturing = null;
		var failed = false;
		try {
			setting.set(name);
		} catch (error:Dynamic) {
			failed = true;
			setMessage(Strings.f("change_error", setting.label, Std.string(error)), 0xE8704A);
		}
		if (!failed) {
			lastMessage = Strings.f("footer", settings.key);
			lastColor = DIM;
		}
		refresh();
	}

	function setBoolValue(setting:HubSetting, value:Bool):Void {
		try {
			setting.set(value);
		} catch (error:Dynamic) {
			setMessage(Strings.f("change_error", setting.label, Std.string(error)), 0xE8704A);
		}
		refresh();
	}

	function cycleChoice(setting:HubSetting):Void {
		var choices = setting.choices;
		if (choices == null || choices.length == 0)
			return;
		var current = Std.string(safeGet(setting));
		var index = 0;
		var i = 0;
		while (i < choices.length) {
			if (choices[i].id == current) {
				index = i;
				break;
			}
			i++;
		}
		var next = (index + 1) % choices.length;
		try {
			setting.set(choices[next].id);
		} catch (error:Dynamic) {
			setMessage(Strings.f("change_error", setting.label, Std.string(error)), 0xE8704A);
		}
		refresh();
	}

	function increment(setting:HubSetting):Void {
		var value = numeric(setting) + 1;
		var min = setting.min == null ? 0 : setting.min;
		var max = setting.max == null ? 99 : setting.max;
		if (value > max)
			value = min;
		try {
			setting.set(value);
		} catch (error:Dynamic) {
			setMessage(Strings.f("change_error", setting.label, Std.string(error)), 0xE8704A);
		}
		refresh();
	}

	function choiceLabel(setting:HubSetting, id:String):String {
		var choices = setting.choices;
		if (choices != null) {
			for (choice in choices)
				if (choice.id == id)
					return choice.label;
		}
		return id;
	}

	function toggleLanguage():Void {
		Strings.lang = Strings.lang == "es" ? "en" : "es";
		if (settings != null) {
			settings.language = Strings.lang;
			settings.save();
		}
		Hub.setLanguage(Strings.lang);
		if (settingsEntry != null)
			settingsEntry = Hub.get(settingsEntry.id);
		if (activeEntry != null)
			activeEntry = Hub.get(activeEntry.id);
		lastMessage = Strings.f("footer", settings.key);
		lastColor = DIM;
		rebuild();
	}

	function clearRows():Void {
		while (rowLabels.numChildren > 0)
			rowLabels.removeChildAt(0);
		for (button in rowButtons)
			button.destroy();
		rowButtons = [];
		for (toggle in switches) {
			if (toggle.root.parent != null)
				toggle.root.parent.removeChild(toggle.root);
			toggle.destroy();
		}
		switches = [];
	}

	function destroyVisual():Void {
		clearRows();
		if (closeButton != null) {
			closeButton.destroy();
			closeButton = null;
		}
		if (langButton != null) {
			langButton.destroy();
			langButton = null;
		}
		if (prevButton != null) {
			prevButton.destroy();
			prevButton = null;
		}
		if (nextButton != null) {
			nextButton.destroy();
			nextButton = null;
		}
		if (backButton != null) {
			backButton.destroy();
			backButton = null;
		}
		if (holder != null && holder.parent != null)
			holder.parent.removeChild(holder);
		holder = null;
		frame = null;
	}

	function safeGet(setting:HubSetting):Dynamic {
		try {
			return setting.get();
		} catch (error:Dynamic) {
			return null;
		}
	}

	function numeric(setting:HubSetting):Int {
		var value:Dynamic = safeGet(setting);
		if (value == null)
			return 0;
		return Std.int(value);
	}

	function safeName(entry:HubEntry):String {
		return entry == null || entry.name == null ? "" : entry.name;
	}

	function safeDescription(entry:HubEntry):String {
		return entry == null || entry.description == null ? "" : entry.description;
	}

	function safeStatus(entry:HubEntry):String {
		if (entry == null || entry.status == null)
			return "";
		try {
			var value = entry.status();
			return value == null ? "" : value;
		} catch (error:Dynamic) {
			return "";
		}
	}

	function setMessage(text:String, color:Int):Void {
		lastMessage = text;
		lastColor = color;
		Ui.set(footer, text);
		footer.textColor = color;
		Log.write(text);
	}
}
