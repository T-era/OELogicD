import std.string;

alias pos = sizediff_t;
alias Cell delegate(pos) GetCell;

enum Cell {
	Unknown, // Must be initial value.
	Fill,
	Empty
}

class Position {
	immutable pos  x;
	immutable pos  y;
	this(pos  x, pos  y) {
		this.x = x;
		this.y = y;
	}

	public override string toString() {
		return format("(%d, %d)", x, y);
	}
}

class ExclusiveException : Exception {
	private pos x;
	private pos y;

	this(string message) {
		super(message);
	}
	this(pos x, pos y, string message = "") {
		super(format("%s@(%d, %d)", message, x, y));
		this.x = x;
		this.y = y;
	}
	this(Position at, string message="") {
		this(at.x, at.y, message);
	}
}
