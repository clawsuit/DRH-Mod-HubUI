package mods.mod_hub_ui;

/** The hub's own words in English and Spanish; `lang` is "en" or "es". */
class Strings {
	public static var lang:String = "en";

	static var en:Map<String, String> = [
		"title" => "MOD HUB",
		"subtitle" => "Panels and options from your mods",
		"empty" => "No mods registered.\nMods with hub support appear here when they load.",
		"open" => "OPEN",
		"options" => "OPTIONS",
		"back" => "BACK",
		"page" => "#1 / #2",
		"settings_page" => "SETTINGS #1 / #2",
		"footer" => "#1 or ESC closes.",
		"hub_name" => "Mod Hub",
		"hub_description" => "Change the key that opens this hub.",
		"hub_key" => "Hub key",
		"hub_key_description" => "Click it and press any letter, number or F1-F12. Letters may be used by chat.",
		"hub_status" => "Key: #1",
		"press_key" => "PRESS A KEY",
		"key_hint" => "Letter, number or F1-F12; ESC cancels.",
		"key_invalid" => "Use a letter, a number or F1-F12.",
		"unknown" => "unsupported type",
		"open_error" => "Could not open #1: #2",
		"change_error" => "Could not change #1: #2"
	];

	static var es:Map<String, String> = [
		"title" => "CENTRO DE MODS",
		"subtitle" => "Paneles y opciones de tus mods",
		"empty" => "No hay mods registrados.\nLos mods con soporte para el hub aparecen aquí al cargar.",
		"open" => "ABRIR",
		"options" => "OPCIONES",
		"back" => "VOLVER",
		"page" => "#1 / #2",
		"settings_page" => "AJUSTES #1 / #2",
		"footer" => "#1 o ESC cierran.",
		"hub_name" => "Centro de Mods",
		"hub_description" => "Cambia la tecla que abre este hub.",
		"hub_key" => "Tecla del hub",
		"hub_key_description" => "Haz clic y pulsa una letra, un número o F1-F12. El chat puede usar las letras.",
		"hub_status" => "Tecla: #1",
		"press_key" => "PULSA UNA TECLA",
		"key_hint" => "Letra, número o F1-F12; ESC cancela.",
		"key_invalid" => "Usa una letra, un número o F1-F12.",
		"unknown" => "tipo no soportado",
		"open_error" => "No pude abrir #1: #2",
		"change_error" => "No pude cambiar #1: #2"
	];

	public static function t(key:String):String {
		var table = lang == "es" ? es : en;
		var value = table.get(key);
		if (value == null)
			value = en.get(key);
		return value == null ? key : value;
	}

	public static function f(key:String, a:String, b:String = null):String {
		var text = t(key);
		text = StringTools.replace(text, "#1", a == null ? "" : a);
		if (b != null)
			text = StringTools.replace(text, "#2", b);
		return text;
	}
}
