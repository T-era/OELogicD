module parts.ExclusiveException;

private import std.typecons;
private import std.traits;
private import std.stdio;
private import std.string;
private import parts.Position;

class ExclusiveException : Exception {
	private int x;
	private int y;

	this(int x, int y, string message = "") {
		super(format("%s@(%d, %d)", message, x, y));
		this.x = x;
		this.y = y;
	}
	this(Position at, string message="") {
		this(at[0], at[1], message);
	}
}
