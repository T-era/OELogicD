module parts.Resolver;

private import std.stdio;
private import std.string;
private import main;
private import Quest;
private import parts.LinePossibility;


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
			vPossibility[x] = new LinePossibility(this, width, quest.vHints[x], &this.getHp);
		}
		for (int y = 0; y < height; y ++) {
			hPossibility[y] = new LinePossibility(this, height, quest.hHints[y], &this.getHp);
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
	public LinePossibility getHp(int y) {
		return hPossibility[y];
	}
	public LinePossibility getVp(int x) {
		return vPossibility[x];
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
