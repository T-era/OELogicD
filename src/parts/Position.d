module parts.Position;

import std.typecons;
import std.traits;
import std.stdio;
import std.string;

class Position {
	immutable int x;
	immutable int y;
	this(int x, int y) {
		this.x = x;
		this.y = y;
	}

	public override string toString() {
		return format("(%d, %d)", x, y);
	}
}
