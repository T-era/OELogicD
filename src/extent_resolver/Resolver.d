module extent_resolver.Resolver;

private import std.stdio;
private import std.string;
private import Quest;
private import extent_resolver.LinePossibility;
private import parts.ExclusiveException;
private import parts.Position;

class Resolver {
	private int[][] xHints;
	private int[][] yHints;
	private int width;
	private int height;
	private Cell[][] cells;
	private LinePossibility[] vPossibility;
	private LinePossibility[] hPossibility;

	this(Quest quest) {
		this.width = quest.vHints.length;
		this.height = quest.hHints.length;

		vPossibility.length = width;
		hPossibility.length = height;
		for (int x = 0; x < width; x ++) {
			vPossibility[x] = new LinePossibility(this, height, quest.vHints[x], this.verticalCallback(x), this.getCellAtX(x));
		}
		for (int y = 0; y < height; y ++) {
			hPossibility[y] = new LinePossibility(this, width, quest.hHints[y], this.horizontalCallback(y), this.getCellAtY(y));
		}

		int xSum = 0;
		int ySum = 0;
		cells.length = this.height;
		for (int y = 0; y < this.height; y ++) {
			cells[y].length = this.width;
			for (int x = 0; x < this.width; x ++) {
				cells[y][x] = Cell.Unknown;
			}
		}
		if (sumOf(xHints) != sumOf(yHints)) {
			throw new Exception("??");
		}
	}
	public void checkUp() {
		foreach(LinePossibility lp; vPossibility) {
			lp.checkUp();
		}
		foreach(LinePossibility lp; hPossibility) {
			lp.checkUp();
		}
	}

	public auto verticalCallback(int x) {
		void _inner(Cell c, int y) {
			if (0 <= x && x < width
				&& 0 <= y && y < height) {
				if (cells[y][x] != c) {
					if (cells[y][x] != Cell.Unknown) {
						throw new ExclusiveException(
							Position(x, y),
							format("Put on anothervalue on (%d, %d): %s-> %s", x, y, cells[y][x], c));
					}
					cells[y][x] = c;
					hPossibility[y].set(c, x);
					hPossibility[y].checkUp();
				}
			}
		}
		return &_inner;
	}
	public auto horizontalCallback(int y) {
		void _inner(Cell c, int x) {
			if (0 <= x && x < width
				&& 0 <= y && y < height) {
				if (cells[y][x] != c) {
					if (cells[y][x] != Cell.Unknown) {
						throw new ExclusiveException(
							Position(x, y),
							format("Put on anothervalue on (%d, %d): %s-> %s", x, y, cells[y][x], c));
					}
					cells[y][x] = c;
					vPossibility[x].set(c, y);
					vPossibility[x].checkUp();
				}
			}
		}
		return &_inner;
	}

	public auto getCellAtX(int x) {
		Cell _inner(int y) {
			if (0 <= y && y < height
				&& 0 <= x && x < width) {
				return cells[y][x];
			} else {
				return Cell.Unknown;
			}
		}
		return &_inner;
	}
	public auto getCellAtY(int y) {
		Cell _inner(int x) {
			if (0 <= y && y < height
				&& 0 <= x && x < width) {
				return cells[y][x];
			} else {
				return Cell.Unknown;
			}
		}
		return &_inner;
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
						str ~= " ";
						break;
					case Cell.Fill:
						str ~= "X";
						break;
					default:
						throw new Exception("??");
				}
			}
			str ~= "\n";
		}
		return str;
	}
	public void showDetail() {
		writeln("||");
		foreach (LinePossibility lb; vPossibility) {
			writeln(lb);
		}
		writeln("=");
		foreach (LinePossibility lb; hPossibility) {
			writeln(lb);
		}
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
}
