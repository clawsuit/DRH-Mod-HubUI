package mods.mod_hub_ui;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

/** The hub's own settings: the language and the key that opens it. */
class Settings {
	static inline final FILE = "settings.json";

	public var language:String = "en";

	public var key:String = "F1";

	var path:String;

	var log:String->Void;

	public function new(folder:String, log:String->Void) {
		path = folder + "/" + FILE;
		this.log = log;
		load();
	}

	public function save():Void {
		var data = {language: language, key: key};
		try {
			File.saveContent(path, Json.stringify(data, null, "\t"));
		} catch (error:Dynamic) {
			log("could not save " + FILE + ": " + error);
		}
	}

	function load():Void {
		if (!FileSystem.exists(path))
			return;
		try {
			var content = File.getContent(path);
			if (content.charCodeAt(0) == 0xFEFF)
				content = content.substr(1);
			var data:Dynamic = Json.parse(content);
			if (data.language != null)
				language = Std.string(data.language) == "es" ? "es" : "en";
			if (data.key != null)
				key = Std.string(data.key);
		} catch (error:Dynamic) {
			log("could not read " + FILE + ", the defaults apply: " + error);
		}
	}
}
