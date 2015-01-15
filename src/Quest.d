import std.algorithm;
private import std.range;
import std.conv;
import std.string;
import std.stdio;

class Quest {
	int[][] vHints;
	int[][] hHints;

	this(int[][] vHints, int[][] hHints) {
		this.vHints = vHints;
		this.hHints = hHints;
	}
	this(string[] vHints, string[] hHints, string separator=",") {
		this.vHints = map!(
				str => map!(to!int)(str.split(separator)).array()
			)(vHints).array();
		this.hHints = map!(
				str => map!(to!int)(str.split(separator)).array()
			)(hHints).array();
	}
}

enum Cell {
	Unknown,
	Fill,
	Empty
}
