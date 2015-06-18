module CommandLineParser;

import std.string;
import std.stdio;
import std.traits;
import std.range;
import std.conv;

import core.stdc.stdlib; // To exit(0)

abstract class CmdOption {
	public bool isRequired;
	private string shortSwitch;
	private string longSwitch;
	private string helpMessage;
	private bool isPointed;

	this(string shortSwitch, string longSwitch, string helpMessage, bool isRequired) {
		this.shortSwitch = shortSwitch.toLower();
		this.longSwitch = longSwitch;
		this.helpMessage = helpMessage;
		this.isRequired = isRequired;

		isPointed = false;
	}
	this(string longSwitch, string helpMessage, bool isRequired) {
		this(
			longSwitch.startsWith("--") ? format("-%c", longSwitch[2]) : null
			, longSwitch
			, helpMessage
			, isRequired);
	}
	override string toString() {
		return format("\t%s %s:\n\t\t%s"
			, shortSwitch
			, longSwitch
			, helpMessage);
	}

	abstract bool requireValue();
	abstract bool isMatch(string str);
	abstract int assignValue(string[] args, int index);
}
class CmdOptionWithValue(ValueType) : CmdOption {
	private ValueType value;
	private ValueType delegate (string) convert;

	this(string shortSwitch, string longSwitch, string helpMessage, ValueType delegate(string) convert, bool isRequired = false) {
		super(shortSwitch, longSwitch, helpMessage, isRequired);
		this.convert = convert;
	}
	this(string longSwitch, string helpMessage, ValueType delegate(string) convert, bool isRequired = false) {
		super(longSwitch, helpMessage, isRequired);
		this.convert = convert;
	}
	override bool requireValue() { return true; }

	override bool isMatch(string str) {
		string low = str.toLower();
		return low == shortSwitch || low.startsWith(shortSwitch ~ "=")
			|| str == longSwitch || str.startsWith(longSwitch ~ "=");
	}
	override int assignValue(string[] args, int index) {
		if (this.isPointed) {
			throw new UsageException("Option duplicated ", this);
		}
		string key = args[index];
		string low = key.toLower();
		this.isPointed = true;
		if (low.startsWith(shortSwitch ~ "=")) {
			try {
				string valueStr = key[shortSwitch.length + 1..$];
				value = convert(valueStr);
			} catch (Exception ex) {
				throw new UsageException(format("Value is invalid %s", key), this);
			}
			return 1;
		} else if (key.startsWith(longSwitch ~ "=")) {
			try {
				string valueStr = key[longSwitch.length + 1..$];
				value = convert(valueStr);
			} catch (Exception ex) {
				throw new UsageException(format("Value is invalid %s", key), this);
			}
			return 1;
		} else if (args.length > index + 1) {
			try {
				value = convert(args[index + 1]);
				return 2;
			} catch (Exception ex) {
				throw new UsageException(format("Value is invalid %s", key), this);
			}
		} else {
			throw new UsageException("Value is requierd", this);
		}
	}
	public ValueType getValue() {
		return value;
	}
}

class CmdOptionNoValue : CmdOption {
	this(string shortSwitch, string longSwitch, string helpMessage) {
		super(shortSwitch, longSwitch, helpMessage, false);
	}
	this(string longSwitch, string helpMessage) {
		super(longSwitch, helpMessage, false);
	}
	override bool requireValue() { return false; }

	override bool isMatch(string str) {
		string low = str.toLower();
		return low == shortSwitch
			|| str == longSwitch;
	}
	override int assignValue(string[] args, int index) {
		this.isPointed = true;
		return 1;
	}
	public bool getValue() {
		return isPointed;
	}
}
class UsageException : Exception {
	CmdOption error;
	bool mashTrace;
	this(string message, CmdOption opt, bool mashTrace = false) {
		super(message);
		this.error = opt;
		this.mashTrace = mashTrace;
	}
}
alias Parser = string[] delegate(string[]);
class CommandLineParser {
	private bool[string] keys;
	private CmdOption[] options;

	template addValiableOption(T) {
		CmdOptionWithValue!(T) addValiableOption(string shortSwitch, string longSwitch, string helpMessage, T delegate(string) conv, bool isRequired=false) {
			CmdOptionWithValue!(T) opt = new CmdOptionWithValue!(T)(shortSwitch, longSwitch, helpMessage, conv, isRequired);
			addOption(opt);
			return opt;
		}
		CmdOptionWithValue!(T) addValiableOption(string longSwitch, string helpMessage, T delegate(string) conv, bool isRequired=false) {
			CmdOptionWithValue!(T) opt = new CmdOptionWithValue!(T)(longSwitch, helpMessage, conv, isRequired);
			addOption(opt);
			return opt;
		}
	}
	CmdOptionNoValue addStaticOption(string shortSwitch, string longSwitch, string helpMessage) {
		CmdOptionNoValue opt = new CmdOptionNoValue(shortSwitch, longSwitch, helpMessage);
		addOption(opt);
		return opt;
	}
	CmdOptionNoValue addStaticOption(string longSwitch, string helpMessage) {
		CmdOptionNoValue opt = new CmdOptionNoValue(longSwitch, helpMessage);
		addOption(opt);
		return opt;
	}
	private void addOption(CmdOption opt) {
		duplicateKey(opt.shortSwitch);
		duplicateKey(opt.longSwitch);
		options ~= opt;
	}
	private void duplicateKey(string key) {
		if (key != null
			&& key in keys) {
			throw new Exception(format("Codeing error: Option key duplicated %s", key));
		}
	}

	string[] parseOptions(string[] args) {
		try {
			string[] remain = [];
			int index = 1; // @0 is name of exe-file.
			while (index < args.length) {
				string arg = args[index];
				auto matches = filter!(o => o.isMatch(arg))(options).array();
				if (matches.length == 1) {
					CmdOption opt = matches[0];
					index += opt.assignValue(args, index);
				} else if (matches.length > 1) {
					throw new Exception(format("Coding error: Command switch duplicated %s" , matches));
				} else if (arg == "-h"
					|| arg == "--help") {
					throw new UsageException("", null, true);
				} else {
					remain ~= arg;
					index ++;
				}
			}
			foreach (CmdOption opt; options) {
				if (opt.isRequired
					&& ! opt.isPointed) {
					throw new UsageException("Required but not.", opt);
				}
			}
			return remain;
		} catch (UsageException ex) {
			showUsage(ex.error);
			if (ex.mashTrace) {
				exit(0);
				assert(0);
			} else {
				throw ex;
			}
		}
	}

	void showUsage(CmdOption error = null) {
		foreach (CmdOption opt; options) {
			if (opt == error) {
				writeln(format("*%s", error));
			} else {
				writeln(opt);
			}
		}
	}
}
