import std.algorithm;
private import std.range;
import std.conv;
import std.string;
import std.stdio;
private import parts.ExclusiveException;
private import parts.Position;

class Quest {
	int[][] vHints;
	int[][] hHints;
	int width;
	int height;
	private Cell[][] cells;

	this(int[][] vHints, int[][] hHints) {
		this.vHints = vHints;
		this.hHints = hHints;

		this.width = vHints.length;
		this.height = hHints.length;
		this.cells.length = this.height;
		for (int y = 0; y < this.height; y ++) {
			cells[y].length = this.width;
			for (int x = 0; x < this.width; x ++) {
				cells[y][x] = Cell.Unknown;
			}
		}
		if (sumOf(vHints) != sumOf(hHints)) {
			throw new Exception("??");
		}
	}
	this(string[] vHints, string[] hHints, string separator=",") {
		this(
			map!(
				str => map!(to!int)(str.split(separator)).array()
			)(vHints).array()
			, map!(
				str => map!(to!int)(str.split(separator)).array()
			)(hHints).array());
	}

	private static int sumOf(int[][] args) {
		int sum = 0;
		for (int i = 0; i < args.length; i ++) {
			for (int j = 0; j < args[i].length; j ++) {
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
			throw new ExclusiveException(Position(x, y),
				format("Another value assigned.%s -> %s", cells[y][x], c));
		}
	}

	override string toString() {
		string str = "";
		for (int y = 0; y < cells.length; y ++) {
			for (int x = 0; x < cells[y].length; x ++) {
				switch(cells[y][x]) {
					case Cell.Unknown:
						str ~= ".";
						break;
					case Cell.Empty:
						str ~= "X";
						break;
					case Cell.Fill:
						str ~= " ";
						break;
					default:
						throw new Exception("??");
				}
			}
			str ~= "\n";
		}
		return str;
	}
}

enum Cell {
	Unknown,
	Fill,
	Empty
}
