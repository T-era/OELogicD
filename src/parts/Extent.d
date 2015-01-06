module parts.Extent;

private import parts.LinePossibility;

class Extent {
	private LinePossibility parent;
	private int length;
	public int min;
	public int max;

	this(LinePossibility parent, int length) {
		this.length = length;
	}

	public bool contains(int arg) {
		return min <= arg
			&& arg <= max;
	}
	public bool fixed() {
		return max - min + 1 == length;
	}
	public void fillCenter(void delegate(int) fillCallback) {
		int d = length * 2 - (max - min + 1);
		if (d <= 0) {
			return;
		} else {
			int fillMin = max - length + 1;
			int fillMax = min + length - 1;
			for (int i = min + fillMin; i <= fillMin; i ++) {
				fillCallback(i);
			}
		}
	}
}
