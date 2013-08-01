using Gee;

namespace langtable {
	private class StringRankMap : HashMap<string, uint64?> {
	}

	private class NamesMap : HashMap<string, string> {
	}

	private class KeyboardsDB : HashMap<string, KeyboardsDBitem> {
	}

	private class TerritoriesDB: HashMap<string, TerritoriesDBitem> {
	}

	private class LanguagesDB: HashMap<string, LanguagesDBitem> {
	}

	private struct RankedItem {
		public string value;
		public uint64? rank;

		public RankedItem (string value, uint64? rank) {
			this.value = value;
			this.rank = rank;
		}
	}

	private enum LocFields {
		lang,
		script,
		terr,
	}

	// cannot create instances here, just declare
	private KeyboardsDB keyboards_db;
	private TerritoriesDB territories_db;
	private LanguagesDB languages_db;

	private Regex locale_regex;

	private const uint64 extra_bonus = 1000000;

	/***************** languages.xml parsing *****************/
	private enum LanguageFields {
		// attributes of the LanguagesDBitem
		languageId,
		iso639_1,
		iso639_2_t,
		iso639_2_b,

		// fields for storing item IDs, ranks and translated names
		item_id,
		item_rank,
		item_name,

		// indicate we shouldn't store data anywhere
		NONE,
	}

	private class LanguagesDBitem : GLib.Object {
		public string languageId;
		public string iso639_1;
		public string iso639_2_t;
		public string iso639_2_b;

		public NamesMap names;
		public StringRankMap locales;
		public StringRankMap territories;
		public StringRankMap keyboards;
		public StringRankMap consolefonts;
		public StringRankMap timezones;

		public LanguagesDBitem () {
			languageId = "";
			iso639_1 = "";
			iso639_2_t = "";
			iso639_2_b = "";
			names = new NamesMap ();
			locales = new StringRankMap ();
			territories = new StringRankMap ();
			keyboards = new StringRankMap ();
			consolefonts = new StringRankMap ();
			timezones = new StringRankMap ();
		}
	}

	private class LanguageParsingDriver : GLib.Object {
		public LanguageFields store_to;
		public LanguagesDBitem curr_item;
		public string item_id;
		public string item_rank;
		public string item_name;
		public bool in_names;

		public LanguageParsingDriver () {
			store_to = LanguageFields.NONE;
			curr_item = null;
			item_id = "";
			item_rank = "";
			item_name = "";
			in_names = false;
		}
	}

	private void languageStartElement (void* data, string name, string[] attrs) {
		LanguageParsingDriver driver = data as LanguageParsingDriver;

		switch (name) {
		case "language":
			driver.curr_item = new LanguagesDBitem ();
			break;
		case "languageId":
			if (!driver.in_names)
				driver.store_to = LanguageFields.languageId;
			else
				driver.store_to = LanguageFields.item_id;
			break;
		case "iso639-1":
			driver.store_to = LanguageFields.iso639_1;
			break;
		case "iso639-2-t":
			driver.store_to = LanguageFields.iso639_2_t;
			break;
		case "iso639-2-b":
			driver.store_to = LanguageFields.iso639_2_b;
			break;
		case "names":
			driver.in_names = true;
			break;
		case "localeId":
		case "keyboardId":
		case "territoryId":
		case "consolefontId":
		case "timezoneId":
			driver.store_to = LanguageFields.item_id;
		    break;
		case "trName":
			driver.store_to = LanguageFields.item_name;
			break;
		case "rank":
			driver.store_to = LanguageFields.item_rank;
			break;
		}
	}

	private void languageEndElement (void* data, string name) {
		LanguageParsingDriver driver = data as LanguageParsingDriver;

		switch (name) {
		case "language":
			languages_db[driver.curr_item.languageId] = driver.curr_item;
			driver.curr_item = null;
			break;
		case "names":
			driver.in_names = false;
			break;
		case "name":
			driver.curr_item.names[driver.item_id] = driver.item_name;
			driver.item_id = "";
			driver.item_name = "";
			break;
		case "locale":
			driver.curr_item.locales[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		case "keyboard":
			driver.curr_item.keyboards[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		case "territory":
			driver.curr_item.territories[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		case "consolefont":
			driver.curr_item.consolefonts[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		case "timezone":
			driver.curr_item.timezones[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		}

		driver.store_to = LanguageFields.NONE;
	}

	private void languageCharacters (void* data, string char_buf, int len)	{
		LanguageParsingDriver driver = data as LanguageParsingDriver;
		string chars = char_buf[0:len].strip ();

		if (chars == "")
			// nothing to save
			return;

		if (driver.curr_item == null || driver.store_to == LanguageFields.NONE)
			// no idea where to save characters
			return;

		switch (driver.store_to) {
		case LanguageFields.languageId:
			driver.curr_item.languageId += chars;
			break;
		case LanguageFields.iso639_1:
			driver.curr_item.iso639_1 += chars;
			break;
		case LanguageFields.iso639_2_t:
			driver.curr_item.iso639_2_t += chars;
			break;
		case LanguageFields.iso639_2_b:
			driver.curr_item.iso639_2_b += chars;
			break;
		case LanguageFields.item_id:
			driver.item_id += chars;
			break;
		case LanguageFields.item_rank:
			driver.item_rank += chars;
			break;
		case LanguageFields.item_name:
			driver.item_name += chars;
			break;
		}
	}

	/***************** keyboards.xml parsing *****************/
	private enum KeyboardFields {
		// attributes of the KeyboardsDBitem
		keyboardId,
		description,
		comment,

		// a helper field for storing temp values (e.g. bool/int strings)
		tmp_field,

		// fields for storing item IDs and ranks
		item_id,
		item_rank,
		NONE,
	}

	private class KeyboardsDBitem : GLib.Object {
		public string keyboardId;
		public string description;
		public string comment;
		public bool ascii;
		public StringRankMap languages;
		public StringRankMap territories;

		public KeyboardsDBitem () {
			keyboardId = "";
			description = "";
			comment = "";
			languages = new StringRankMap ();
			territories = new StringRankMap ();
		}
	}

	private class KeyboardParsingDriver : GLib.Object {
		public KeyboardFields store_to;
		public KeyboardsDBitem curr_item;
		public string item_id;
		public string item_rank;
		public string tmp_field;

		public KeyboardParsingDriver () {
			store_to = KeyboardFields.NONE;
			curr_item = null;
			item_id = "";
			item_rank = "";
			tmp_field = "";
		}
	}

	private void keyboardStartElement (void* data, string name, string[] attrs) {
		KeyboardParsingDriver driver = data as KeyboardParsingDriver;

		switch (name) {
		case "keyboard":
			driver.curr_item = new KeyboardsDBitem ();
			break;
		case "keyboardId":
			driver.store_to = KeyboardFields.keyboardId;
			break;
		case "description":
			driver.store_to = KeyboardFields.description;
			break;
		case "ascii":
			driver.store_to = KeyboardFields.tmp_field;
			break;
		case "comment":
			driver.store_to = KeyboardFields.comment;
			break;
		case "languageId":
		case "territoryId":
			driver.store_to = KeyboardFields.item_id;
		    break;
		case "rank":
			driver.store_to = KeyboardFields.item_rank;
			break;
		}
	}

	private void keyboardEndElement (void* data, string name) {
		KeyboardParsingDriver driver = data as KeyboardParsingDriver;

		switch (name) {
		case "ascii":
			driver.curr_item.ascii = driver.tmp_field == "True";
			driver.tmp_field = "";
			break;
		case "keyboard":
			keyboards_db[driver.curr_item.keyboardId] = driver.curr_item;
			driver.curr_item = null;
			break;
		case "language":
			driver.curr_item.languages[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			break;
		case "territory":
			driver.curr_item.territories[driver.item_id] = int.parse(driver.item_rank);
			driver.item_rank = "";
			break;
		}

		driver.store_to = KeyboardFields.NONE;
	}

	private void keyboardCharacters (void* data, string char_buf, int len)	{
		KeyboardParsingDriver driver = data as KeyboardParsingDriver;
		string chars = char_buf[0:len].strip ();

		if (chars == "")
			// nothing to save
			return;

		if (driver.curr_item == null || driver.store_to == KeyboardFields.NONE)
			// no idea where to save characters
			return;

		switch (driver.store_to) {
		case KeyboardFields.keyboardId:
			driver.curr_item.keyboardId += chars;
			break;
		case KeyboardFields.description:
			driver.curr_item.description += chars;
			break;
		case KeyboardFields.comment:
			driver.curr_item.comment += chars;
			break;
		case KeyboardFields.tmp_field:
			driver.tmp_field += chars;
			break;
		case KeyboardFields.item_id:
			driver.item_id += chars;
			break;
		case KeyboardFields.item_rank:
			driver.item_rank += chars;
			break;
		}
	}

	/***************** territories.xml parsing *****************/
	private enum TerritoryFields {
		// attributes of the TerritoriesDBitem
		territoryId,

		// fields for storing item IDs, ranks and translated names
		item_id,
		item_rank,
		item_name,
		NONE,
	}

	private class TerritoriesDBitem : GLib.Object {
		public string territoryId;

		public NamesMap names;
		public StringRankMap languages;
		public StringRankMap locales;
		public StringRankMap keyboards;
		public StringRankMap consolefonts;
		public StringRankMap timezones;

		public TerritoriesDBitem () {
			territoryId = "";
			names = new NamesMap ();
			languages = new StringRankMap ();
			locales = new StringRankMap ();
			keyboards = new StringRankMap ();
			consolefonts = new StringRankMap ();
			timezones = new StringRankMap ();
		}
	}

	private class TerritoryParsingDriver : GLib.Object {
		public TerritoryFields store_to;
		public TerritoriesDBitem curr_item;
		public string item_id;
		public string item_rank;
		public string item_name;

		public TerritoryParsingDriver () {
			store_to = TerritoryFields.NONE;
			curr_item = null;
			item_id = "";
			item_rank = "";
			item_name = "";
		}
	}

	private void territoryStartElement (void* data, string name, string[] attrs) {
		TerritoryParsingDriver driver = data as TerritoryParsingDriver;

		switch (name) {
		case "territory":
			driver.curr_item = new TerritoriesDBitem ();
			break;
		case "territoryId":
			driver.store_to = TerritoryFields.territoryId;
			break;
		case "languageId":
		case "localeId":
		case "keyboardId":
		case "consolefontId":
		case "timezoneId":
			driver.store_to = TerritoryFields.item_id;
		    break;
		case "trName":
			driver.store_to = TerritoryFields.item_name;
			break;
		case "rank":
			driver.store_to = TerritoryFields.item_rank;
			break;
		}
	}

	private void territoryEndElement (void* data, string name) {
		TerritoryParsingDriver driver = data as TerritoryParsingDriver;

		switch (name) {
		case "territory":
			territories_db[driver.curr_item.territoryId] = driver.curr_item;
			driver.curr_item = null;
			break;
		case "name":
			driver.curr_item.names[driver.item_id] = driver.item_name;
			driver.item_id = "";
			driver.item_name = "";
			break;
		case "language":
			driver.curr_item.languages[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		case "locale":
			driver.curr_item.locales[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		case "keyboard":
			driver.curr_item.keyboards[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		case "consolefont":
			driver.curr_item.consolefonts[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		case "timezone":
			driver.curr_item.timezones[driver.item_id] = int.parse(driver.item_rank);
			driver.item_id = "";
			driver.item_rank = "";
			break;
		}

		driver.store_to = TerritoryFields.NONE;
	}

	private void territoryCharacters (void* data, string char_buf, int len)	{
		TerritoryParsingDriver driver = data as TerritoryParsingDriver;
		string chars = char_buf[0:len].strip ();

		if (chars == "")
			// nothing to save
			return;

		if (driver.curr_item == null || driver.store_to == TerritoryFields.NONE)
			// no idea where to save characters
			return;

		switch (driver.store_to) {
		case TerritoryFields.territoryId:
			driver.curr_item.territoryId += chars;
			break;
		case TerritoryFields.item_id:
			driver.item_id += chars;
			break;
		case TerritoryFields.item_rank:
			driver.item_rank += chars;
			break;
		case TerritoryFields.item_name:
			driver.item_name += chars;
			break;
		}
	}

	private class FileParser : GLib.Object {
		private Xml.SAXHandler handler;
		private string real_path;
		private void* driver;

		public FileParser (Xml.startElementSAXFunc start,
						   Xml.endElementSAXFunc end,
						   Xml.charactersSAXFunc chars,
						   void* driver,
						   string fpath) {

			handler = Xml.SAXHandler ();
			handler.startElement = start;
			handler.endElement = end;
			handler.characters = chars;

			this.driver = driver;

			real_path = fpath;

			if (!FileUtils.test (real_path, FileTest.EXISTS)) {
				if (FileUtils.test (real_path + ".gz", FileTest.EXISTS))
					real_path += ".gz";
				else
					real_path = "";
			}
		}

		public bool parse () {
			if (real_path == "")
				return false;
			else
				handler.user_parse_file (driver, real_path);

			// successfully parsed
			return true;
		}
	}

	/**
	   Parses languageId and if it contains a valid ICU locale id,
	   returns the values for language, script, and territory found
	   in languageId instead of the original values given.

	   Before parsing, it replaces glibc names for scripts like “latin”
	   with the iso-15924 script names like “Latn”, both in the
	   languageId and the scriptId parameter. I.e.  language id like
	   “sr_latin_RS” is accepted as well and treated the same as
	   “sr_Latn_RS”.
	*/
	private string[] parse_and_split_languageId (string languageId,
												 string scriptId,
												 string territoryId) {
		string ICUscriptId = scriptId;
		string ICUlanguageId = languageId;
		string ICUterritoryId = territoryId;
		string[,] scripts = {{"latin", "Latn"},
							 {"iqtelif", "Latn"}, // Tatar, tt_RU.UTF-8@iqtelif,
							 // http://en.wikipedia.org/wiki/User:Ultranet/%C4%B0QTElif
							 {"cyrillic", "Cyrl"},
							 {"devanagari", "Deva"}};

		for (uint8 i=0; i < 4; i++ ) {
			if (ICUscriptId != null)
                ICUscriptId = ICUscriptId.replace(scripts[i,0], scripts[i,1]);
			if (ICUlanguageId != null)
			    ICUlanguageId = ICUlanguageId.replace(scripts[i,0], scripts[i,1]);
		}

	    MatchInfo info;
		var matched = locale_regex.match (ICUlanguageId, 0, out info);

		if (!matched) {
			debug ("languageId contains invalid locale id=%s", languageId);
			return {ICUlanguageId, ICUscriptId, ICUterritoryId};
		}

		string? lang = info.fetch_named ("language");
		string? script = info.fetch_named ("script");
		string? territory = info.fetch_named ("territory");

		if (lang != null)
		    ICUlanguageId = lang;
		if (script != null)
			ICUscriptId = script;
		if (territory != null)
     		ICUterritoryId = territory;

		return {ICUlanguageId, ICUscriptId, ICUterritoryId};
	}

	private RankedItem[] ranked_map_to_ranked_list (StringRankMap map, bool reverse) {
		RankedItem[] ret = {};
		var entry_set = map.entries;
		var ranked_list = new ArrayList<Map.Entry<string, uint64?>> ();
		int8 reverse_factor = reverse ? -1 : 1;

		ranked_list.add_all(entry_set);
		ranked_list.sort((a, b) => {
				if (a.value < b.value)
					return -1 * reverse_factor;
				if (a.value == b.value)
					return 0;
				else
					return 1 * reverse_factor;
			});

		foreach (var entry in ranked_list)
			ret += RankedItem (entry.key, entry.value);

		return ret;
	}

	private string[] ranked_list_to_list (RankedItem[] list) {
		string[] ret = {};

		foreach (var item in list)
			ret += item.value;

		return ret;
	}

	private RankedItem[] make_ranked_list_concise (RankedItem[] list, uint64? cut_off_factor) {
		RankedItem[] ret = list[0:list.length];

		if (list.length <= 1)
			return ret;

		for (int i=0; i < (list.length - 1); i++) {
			if ((list[i].rank / list[i+1].rank) > cut_off_factor) {
				ret = list[0:(i+1)];
				break;
			}
		}

		return ret;
	}

	/**
	   Returns True if the keyboard layout with that id can be used to
	   type ASCII, returns false if the keyboard layout can not be used
	   to type ASCII or if typing ASCII with that keyboard layout is
	   difficult.
	*/
	public bool supports_ascii (string? keyboardId) {
		if (keyboardId in keyboards_db)
			return keyboards_db[keyboardId].ascii;

		return false;
	}

	public string territory_name (string? territoryId, string? languageIdQuery,
								  string? scriptIdQuery, string? territoryIdQuery) {

		string? langIdQ;
		string? scriptIdQ;
		string? terrIdQ;

		string[] loc_fields = parse_and_split_languageId (languageIdQuery,
														  scriptIdQuery,
														  territoryIdQuery);
		langIdQ = loc_fields[LocFields.lang];
		scriptIdQ = loc_fields[LocFields.script];
		terrIdQ = loc_fields[LocFields.terr];

		if (!(territoryId in territories_db))
			return "";

		string ICUlocaleId;
		if (langIdQ != "" && scriptIdQ != "" && terrIdQ != "") {
			ICUlocaleId = langIdQ + "_" + scriptIdQ + "_" + terrIdQ;
			if (ICUlocaleId in territories_db[territoryId].names)
				return territories_db[territoryId].names[ICUlocaleId];
		}

		if (langIdQ != "" && scriptIdQ != "") {
			ICUlocaleId = langIdQ + "_" + scriptIdQ;
			if (ICUlocaleId in territories_db[territoryId].names)
				return territories_db[territoryId].names[ICUlocaleId];
		}

		if (langIdQ != "" && terrIdQ != "") {
			ICUlocaleId = langIdQ + "_" + terrIdQ;
			if (ICUlocaleId in territories_db[territoryId].names)
				return territories_db[territoryId].names[ICUlocaleId];
		}

		if (langIdQ != "") {
			ICUlocaleId = langIdQ;
			if (ICUlocaleId in territories_db[territoryId].names)
				return territories_db[territoryId].names[ICUlocaleId];
		}

		return "";
	}

	public string language_name (string? languageId, string? scriptId,
								 string? territoryId, string? languageIdQuery,
								 string? scriptIdQuery, string? territoryIdQuery) {
		string? langId;
		string? scrId;
		string? terrId;
		string? langIdQ;
		string? scrIdQ;
		string? terrIdQ;

		string[] loc_fields = parse_and_split_languageId (languageId,
														  scriptId,
														  territoryId);
		langId = loc_fields[LocFields.lang];
		scrId = loc_fields[LocFields.script];
		terrId = loc_fields[LocFields.terr];

		loc_fields = parse_and_split_languageId (languageIdQuery,
												 scriptIdQuery,
												 territoryIdQuery);
		langIdQ = loc_fields[LocFields.lang];
		scrIdQ = loc_fields[LocFields.script];
		terrIdQ = loc_fields[LocFields.terr];

		if (langIdQ == "") {
			// get the endonym
			langIdQ = langId;
			scrIdQ = scrId;
			terrIdQ = terrId;
		}

		string ICUlocaleId;
		string ICUlocaleIdQ;
		if (langId != "" && scrId != "" && terrId != "") {
			ICUlocaleId = langId + "_" + scrId + "_" + terrId;
			if (ICUlocaleId in languages_db) {
				if (langIdQ != "" && scrIdQ != "" && terrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + scrIdQ + "_" + terrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "" && scrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + scrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "" && terrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + terrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "") {
					ICUlocaleIdQ = langIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
			}
		}
		if (langId != "" && scrId != "") {
			ICUlocaleId = langId + "_" + scrId;
			if (ICUlocaleId in languages_db) {
				if (langIdQ != "" && scrIdQ != "" && terrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + scrIdQ + "_" + terrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "" && scrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + scrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "" && terrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + terrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "") {
					ICUlocaleIdQ = langIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
			}
		}
		if (langId != "" && terrId != "") {
			ICUlocaleId = langId + "_" + terrId;
			if (ICUlocaleId in languages_db) {
				if (langIdQ != "" && scrIdQ != "" && terrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + scrIdQ + "_" + terrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "" && scrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + scrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "" && terrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + terrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "") {
					ICUlocaleIdQ = langIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
			}
			string lname = language_name (langId, "", "", langIdQ, scrIdQ, terrIdQ);
			string tname = territory_name (terrId, langIdQ, scrIdQ, terrIdQ);

			if (lname != "" && tname != "")
				return lname + " (" + tname + ")";
		}
		if (langId != "") {
			ICUlocaleId = langId;
			if (ICUlocaleId in languages_db) {
				if (langIdQ != "" && scrIdQ != "" && terrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + scrIdQ + "_" + terrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "" && scrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + scrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "" && terrIdQ != "") {
					ICUlocaleIdQ = langIdQ + "_" + terrIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
				if (langIdQ != "") {
					ICUlocaleIdQ = langIdQ;
					if (ICUlocaleIdQ in languages_db[ICUlocaleId].names)
						return languages_db[ICUlocaleId].names[ICUlocaleIdQ];
				}
			}
		}

		return "";
	}

	private bool has_terr_name (TerritoriesDBitem item, string name) {
		foreach (var entry in item.names.entries)
			if (name == entry.value)
				return true;

		return false;
	}

	public string territoryId (string territoryName) {
		if (territoryName == "")
			return "";

		foreach (var terr_entry in territories_db.entries)
			if (has_terr_name (terr_entry.value, territoryName))
				return terr_entry.key;

		return "";
	}

	private bool has_lang_name (LanguagesDBitem item, string name) {
		foreach (var entry in item.names.entries)
			if (name == entry.value)
				return true;

		return false;
	}

	public string languageId (string languageName) {
		if (languageName == "")
			return "";

		foreach (var lang_entry in languages_db.entries)
			if (has_lang_name (lang_entry.value, languageName))
				return lang_entry.key;

		return "";
	}

	public string[] list_locales (bool concise, string languageId,
								  string scriptId, string territoryId) {

		var ranked_locales = new StringRankMap ();
		string[] loc_fields = parse_and_split_languageId (languageId, scriptId,
														  territoryId);

		var langId = loc_fields[LocFields.lang];
		var scrId = loc_fields[LocFields.script];
		var terrId = loc_fields[LocFields.terr];

		var skip_territory = false;

		if (langId != "" && scrId != "" && terrId != "" &&
			(langId + "_" + scrId + "_" + terrId) in languages_db) {
			langId = langId + "_" + scrId + "_" + terrId;
			skip_territory = true;
		}
		else if (langId != "" && scrId != "" &&
				 (langId + "_" + scrId) in languages_db) {
			langId = langId + "_" + scrId;
		}
		else if (langId != "" && terrId != "" &&
				 (langId + "_" + terrId) in languages_db) {
			langId = langId + "_" + terrId;
			skip_territory = false;
		}

		uint64 language_bonus = 100;
		ForallFunc<Map.Entry<string, uint64?>> foreach_lang = (item) => {
				if (item.value != 0) {
					if (!(item.key in ranked_locales))
						ranked_locales[item.key] = item.value;
					else {
						ranked_locales[item.key] = ranked_locales[item.key] * item.value;
						ranked_locales[item.key] = ranked_locales[item.key] * extra_bonus;
					}
					ranked_locales[item.key] = ranked_locales[item.key] * language_bonus;
				}
				return true;
		};

		if (langId in languages_db)
			languages_db[langId].locales.foreach(foreach_lang);

		uint64 territory_bonus = 1;
		ForallFunc<Map.Entry<string, uint64?>> foreach_terr = (item) => {
				if (item.value != 0) {
					if (!(item.key in ranked_locales))
						ranked_locales[item.key] = item.value;
					else {
						ranked_locales[item.key] = ranked_locales[item.key] * item.value;
						ranked_locales[item.key] = ranked_locales[item.key] * extra_bonus;
					}
					ranked_locales[item.key] = ranked_locales[item.key] * territory_bonus;
				}
				return true;
		};

		if (terrId in territories_db && !skip_territory)
			territories_db[terrId].locales.foreach (foreach_terr);

		var ranked_list = ranked_map_to_ranked_list (ranked_locales, true);
		if (concise)
			ranked_list = make_ranked_list_concise (ranked_list, 1000);

		var ret_list = ranked_list_to_list (ranked_list);
		return ret_list;
	}

	public string[] list_keyboards (bool concise, string languageId,
								  string scriptId, string territoryId) {

		var ranked_keyboards = new StringRankMap ();
		string[] loc_fields = parse_and_split_languageId (languageId, scriptId,
														  territoryId);

		var langId = loc_fields[LocFields.lang];
		var scrId = loc_fields[LocFields.script];
		var terrId = loc_fields[LocFields.terr];

		var skip_territory = false;

		if (langId != "" && scrId != "" && terrId != "" &&
			(langId + "_" + scrId + "_" + terrId) in languages_db) {
			langId = langId + "_" + scrId + "_" + terrId;
			skip_territory = true;
		}
		else if (langId != "" && scrId != "" &&
				 (langId + "_" + scrId) in languages_db) {
			langId = langId + "_" + scrId;
		}
		else if (langId != "" && terrId != "" &&
				 (langId + "_" + terrId) in languages_db) {
			langId = langId + "_" + terrId;
			skip_territory = false;
		}

		uint64 language_bonus = 1;
		ForallFunc<Map.Entry<string, uint64?>> foreach_lang = (item) => {
				if (item.value != 0) {
					if (!(item.key in ranked_keyboards))
						ranked_keyboards[item.key] = item.value;
					else {
						ranked_keyboards[item.key] = ranked_keyboards[item.key] * item.value;
						ranked_keyboards[item.key] = ranked_keyboards[item.key] * extra_bonus;
					}
					ranked_keyboards[item.key] = ranked_keyboards[item.key] * language_bonus;
				}
				return true;
		};

		if (langId in languages_db)
			languages_db[langId].keyboards.foreach(foreach_lang);

		uint64 territory_bonus = 1;
		ForallFunc<Map.Entry<string, uint64?>> foreach_terr = (item) => {
				if (item.value != 0) {
					if (!(item.key in ranked_keyboards))
						ranked_keyboards[item.key] = item.value;
					else {
						ranked_keyboards[item.key] = ranked_keyboards[item.key] * item.value;
						ranked_keyboards[item.key] = ranked_keyboards[item.key] * extra_bonus;
					}
					ranked_keyboards[item.key] = ranked_keyboards[item.key] * territory_bonus;
				}
				return true;
		};

		if (terrId in territories_db && !skip_territory)
			territories_db[terrId].keyboards.foreach (foreach_terr);

		var ranked_list = ranked_map_to_ranked_list (ranked_keyboards, true);
		if (concise)
			ranked_list = make_ranked_list_concise (ranked_list, 1000);

		var ret_list = ranked_list_to_list (ranked_list);
		return ret_list;
	}

	public string[] list_consolefonts (bool concise, string languageId,
									   string scriptId, string territoryId) {

		var ranked_consolefonts = new StringRankMap ();
		string[] loc_fields = parse_and_split_languageId (languageId, scriptId,
														  territoryId);

		var langId = loc_fields[LocFields.lang];
		var scrId = loc_fields[LocFields.script];
		var terrId = loc_fields[LocFields.terr];

		var skip_territory = false;

		if (langId != "" && scrId != "" && terrId != "" &&
			(langId + "_" + scrId + "_" + terrId) in languages_db) {
			langId = langId + "_" + scrId + "_" + terrId;
			skip_territory = true;
		}
		else if (langId != "" && scrId != "" &&
				 (langId + "_" + scrId) in languages_db) {
			langId = langId + "_" + scrId;
		}
		else if (langId != "" && terrId != "" &&
				 (langId + "_" + terrId) in languages_db) {
			langId = langId + "_" + terrId;
			skip_territory = false;
		}

		uint64 language_bonus = 100;
		ForallFunc<Map.Entry<string, uint64?>> foreach_lang = (item) => {
				if (item.value != 0) {
					if (!(item.key in ranked_consolefonts))
						ranked_consolefonts[item.key] = item.value;
					else {
						ranked_consolefonts[item.key] = ranked_consolefonts[item.key] * item.value;
						ranked_consolefonts[item.key] = ranked_consolefonts[item.key] * extra_bonus;
					}
					ranked_consolefonts[item.key] = ranked_consolefonts[item.key] * language_bonus;
				}
				return true;
		};

		if (langId in languages_db)
			languages_db[langId].consolefonts.foreach(foreach_lang);

		uint64 territory_bonus = 1;
		ForallFunc<Map.Entry<string, uint64?>> foreach_terr = (item) => {
				if (item.value != 0) {
					if (!(item.key in ranked_consolefonts))
						ranked_consolefonts[item.key] = item.value;
					else {
						ranked_consolefonts[item.key] = ranked_consolefonts[item.key] * item.value;
						ranked_consolefonts[item.key] = ranked_consolefonts[item.key] * extra_bonus;
					}
					ranked_consolefonts[item.key] = ranked_consolefonts[item.key] * territory_bonus;
				}
				return true;
		};

		if (terrId in territories_db && !skip_territory)
			territories_db[terrId].consolefonts.foreach (foreach_terr);

		var ranked_list = ranked_map_to_ranked_list (ranked_consolefonts, true);
		if (concise)
			ranked_list = make_ranked_list_concise (ranked_list, 1000);

		var ret_list = ranked_list_to_list (ranked_list);
		return ret_list;
	}

	public string[] list_timezones (bool concise, string languageId,
									   string scriptId, string territoryId) {

		var ranked_timezones = new StringRankMap ();
		string[] loc_fields = parse_and_split_languageId (languageId, scriptId,
														  territoryId);

		var langId = loc_fields[LocFields.lang];
		var scrId = loc_fields[LocFields.script];
		var terrId = loc_fields[LocFields.terr];

		var skip_territory = false;

		if (langId != "" && scrId != "" && terrId != "" &&
			(langId + "_" + scrId + "_" + terrId) in languages_db) {
			langId = langId + "_" + scrId + "_" + terrId;
			skip_territory = true;
		}
		else if (langId != "" && scrId != "" &&
				 (langId + "_" + scrId) in languages_db) {
			langId = langId + "_" + scrId;
		}
		else if (langId != "" && terrId != "" &&
				 (langId + "_" + terrId) in languages_db) {
			langId = langId + "_" + terrId;
			skip_territory = false;
		}

		uint64 language_bonus = 1;
		ForallFunc<Map.Entry<string, uint64?>> foreach_lang = (item) => {
				if (item.value != 0) {
					if (!(item.key in ranked_timezones))
						ranked_timezones[item.key] = item.value;
					else {
						ranked_timezones[item.key] = ranked_timezones[item.key] * item.value;
						ranked_timezones[item.key] = ranked_timezones[item.key] * extra_bonus;
					}
					ranked_timezones[item.key] = ranked_timezones[item.key] * language_bonus;
				}
				return true;
		};

		if (langId in languages_db)
			languages_db[langId].timezones.foreach(foreach_lang);

		uint64 territory_bonus = 100;
		ForallFunc<Map.Entry<string, uint64?>> foreach_terr = (item) => {
				if (item.value != 0) {
					if (!(item.key in ranked_timezones))
						ranked_timezones[item.key] = item.value;
					else {
						ranked_timezones[item.key] = ranked_timezones[item.key] * item.value;
						ranked_timezones[item.key] = ranked_timezones[item.key] * extra_bonus;
					}
					ranked_timezones[item.key] = ranked_timezones[item.key] * territory_bonus;
				}
				return true;
		};

		if (terrId in territories_db && !skip_territory)
			territories_db[terrId].timezones.foreach (foreach_terr);

		var ranked_list = ranked_map_to_ranked_list (ranked_timezones, true);
		if (concise)
			ranked_list = make_ranked_list_concise (ranked_list, 1000);

		var ret_list = ranked_list_to_list (ranked_list);
		return ret_list;
	}

	public void init () {
		keyboards_db = new KeyboardsDB ();
		territories_db = new TerritoriesDB ();
		languages_db = new LanguagesDB ();

		var kb_driver = new KeyboardParsingDriver ();
		var ter_driver = new TerritoryParsingDriver ();
		var lang_driver = new LanguageParsingDriver ();

		var keyb_parser = new FileParser (keyboardStartElement, keyboardEndElement,
										  keyboardCharacters, kb_driver,
										  "/usr/share/langtable/keyboards.xml");
		var ter_parser = new FileParser (territoryStartElement, territoryEndElement,
										 territoryCharacters, ter_driver,
										 "/usr/share/langtable/territories.xml");
		var lang_parser = new FileParser (languageStartElement, languageEndElement,
										  languageCharacters, lang_driver,
										  "/usr/share/langtable/languages.xml");

		Thread<bool> keyb_thread = new Thread<bool> ("KeybThread", keyb_parser.parse);
		Thread<bool> terr_thread = new Thread<bool> ("TerThread", ter_parser.parse);
		Thread<bool> lang_thread = new Thread<bool> ("LangThread", lang_parser.parse);

		locale_regex = new Regex (
			// language must be 2 or 3 lower case letters:
			"^(?P<language>[a-z]{2,3}" +
			// language is only valid if
			"(?=$|@" + // locale string ends here or only options follow
			"|_[A-Z][a-z]{3}(?=$|@|_[A-Z]{2}(?=$|@))" + // valid script follows
			"|_[A-Z]{2}(?=$|@)" + // valid territory follows
			"))" +
			// script must be 1 upper case letter followed by
			// 3 lower case letters:
			"(?:_(?P<script>[A-Z][a-z]{3})" +
			// script is only valid if
			"(?=$|@" + // locale string ends here or only options follow
			"|_[A-Z]{2}(?=$|@)" + // valid territory follows
			")){0,1}" +
			// territory must be 2 upper case letters:
			"(?:_(?P<territory>[A-Z]{2})" +
			// territory is only valid if
			"(?=$|@" + // locale string ends here or only options follow
			")){0,1}");

		if (!keyb_thread.join ())
			warning ("Failed to load keyboard data!");
		if (!terr_thread.join ())
			warning ("Failed to load territory data!");
		if (!lang_thread.join ())
			warning ("Failed to load language data!");
	}
}
