module parts.Extent;

private import std.string;
private import std.stdio;
private import parts.LinePossibility;

class Extent {
	private LinePossibility parent;
	public int length;
	public int min;
	public int max;

	this(LinePossibility parent, int length) {
		this.length = length;
	}

	public bool contains(int arg) {
		return min <= arg
			&& arg <= max;
	}
	public bool isFixed() {
		return max - min + 1 == length;
	}
	public void fillCenter(void delegate(int) fillCallback) {
		int d = length * 2 - (max - min + 1);
		if (d <= 0) {
			return;
		} else {
			int fillMin = max - length + 1;
			int fillMax = min + length - 1;
			for (int i = fillMin; i <= fillMax; i ++) {
				fillCallback(i);
			}
		}
	}
	public override string toString() {
		return format("%d-%d@%d", min, max, length);
	}
}
