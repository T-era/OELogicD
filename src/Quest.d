private import std.algorithm;
private import std.range;
private import std.conv;
private import std.string;
private import std.stdio;

private import parts.CompList;
private import common;

class Quest {
	pos[][] vHints;
	pos[][] hHints;
	pos width;
	pos height;
	Cell[][] cells;

	this(pos[][] vHints, pos[][] hHints) {
		pos height = hHints.length;
		pos width = vHints.length;
		Cell[][] cs = new Cell[][](height, width);

		if (sumOf(vHints) != sumOf(hHints)) {
			throw new Exception("??");
		}
		this(vHints, hHints, cs);
	}
	this(string[] vHints, string[] hHints, string separator=",") {
		this(
			map!(
				str => map!(to!pos)(str.split(separator)).array()
			)(vHints).array()
			, map!(
				str => map!(to!pos)(str.split(separator)).array()
			)(hHints).array());
	}
	private this(pos[][] vHints, pos[][] hHints, Cell[][] cells) {
		this.vHints = vHints;
		this.hHints = hHints;

		this.width = vHints.length;
		this.height = hHints.length;
		this.cells = cells;
	}

	private static pos sumOf(pos[][] args) {
		pos sum = 0;
		for (pos i = 0; i < args.length; i ++) {
			for (pos j = 0; j < args[i].length; j ++) {
				sum += args[i][j];
			}
		}
		return sum;
	}

	Cell opIndex(size_t y, size_t x) {
		return cells[y][x];
	}
	void opIndexAssign(Cell c, size_t y, size_t x) {
		if (cells[y][x] == c) {
			// do nothing.
		} else if (cells[y][x] == Cell.Unknown) {
			cells[y][x] = c;
		} else {
			throw new ExclusiveException(new Position(x, y),
				format("Another value assigned.%s -> %s", cells[y][x], c));
		}
	}

	Quest copy() {
		return new Quest(this.vHints
			, this.hHints
			, deepCopy!(Cell[])(this.cells));
	}

	T forEachCell(T)(T delegate(Cell) map, T delegate(T, T) reduce, T delegate(T, T) ln) {
		return fetchDoubleList!(Cell, string)(
			this.cells,
			map,
			reduce,
			ln);
	}

	override string toString() {
		return this.forEachCell!(string)(
			delegate(c) {
				final switch(c) {
					case Cell.Unknown:
						return ".";
					case Cell.Empty:
						return "X";
					case Cell.Fill:
						return " ";
				}
			}
			, (a, b) => b ~ a
			, (t1, t2) => t2 ~ "\n" ~ t1);
	}
}
