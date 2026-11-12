package mods.mod_hub_ui;

/** Key names for the hub: F1-F12, letters, digits and numpad digits. */
class HubKeys {
	public static function name(key:UInt):Null<String> {
		if (key >= 112 && key <= 123)
			return "F" + (key - 111);
		if (key >= 65 && key <= 90)
			return String.fromCharCode(key);
		if (key >= 48 && key <= 57)
			return String.fromCharCode(key);
		if (key >= 96 && key <= 105)
			return "NUM" + (key - 96);
		return null;
	}

	public static function normalize(value:String):String {
		if (value == null)
			return "F1";
		var name = value.toUpperCase();
		if (name.length >= 2 && name.charAt(0) == "F") {
			var number = Std.parseInt(name.substr(1));
			if (number != null && number >= 1 && number <= 12)
				return "F" + number;
		}
		if (name.length >= 4 && name.substr(0, 3) == "NUM") {
			var number = Std.parseInt(name.substr(3));
			if (number != null && number >= 0 && number <= 9)
				return "NUM" + number;
		}
		if (name.length == 1) {
			var code = name.charCodeAt(0);
			if ((code >= 65 && code <= 90) || (code >= 48 && code <= 57))
				return name;
		}
		return "F1";
	}

	public static function code(value:String):UInt {
		var name = normalize(value);
		if (name.charAt(0) == "F")
			return 111 + Std.parseInt(name.substr(1));
		if (name.substr(0, 3) == "NUM")
			return 96 + Std.parseInt(name.substr(3));
		return name.charCodeAt(0);
	}
}
