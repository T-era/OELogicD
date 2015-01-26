module extent_resolver.Extent;

private import std.string;
private import std.stdio;
private import Quest;
private import extent_resolver.LinePossibility;
private import parts.ExclusiveException;

class Extent {
	private Cell delegate(int) getCell;
	private Extent prev;
	private Extent next;

	public int length;
	public int min;
	public int max;

	this(Cell delegate(int) getCell, int length, Extent prev) {
		this.getCell = getCell;
		this.length = length;
		this.prev = prev;
		if (prev) {
			prev.setNext(this);
		}
	}
	private void setNext(Extent next) {
		this.next = next;
	}

	public void shortenMin(int pos) {
		if (pos > min) {
			int len = getShorten(pos, +1);
			min = pos + len;
			checkLength();
			if (next !is null)
				next.shortenMin(min + length + 1);
		}
	}
	public void shortenMax(int pos) {
		if (pos < max) {
			int len = getShorten(pos, -1);
			max = pos + len;
			checkLength();
			if (prev !is null)
				prev.shortenMax(max - length - 1);
		}
	}
	private int getShorten(int pos, int direction) {
		int temp = 0;
		bool more;
		do {
			more = false;
			int edge = pos + temp;
			int edge2 = edge + (direction * length) - direction;
			if (getCell(edge - direction) == Cell.Fill
				|| getCell(edge2 + direction) == Cell.Fill) {
				temp += direction;
				more = true;
			} else {
				for (int i = length - 1; i >= 0; i --) {
					if (getCell(edge + (direction * i)) == Cell.Empty) {
						temp += direction * (i + 1);
						more = true;
						break;
					}
				}
			}
		} while (more);
		return temp;
	}
	private void checkLength() {
		if (max - min + 1 < length)
			throw new ExclusiveException(format(
				"Length %d(%d)", max - min + 1, length));
	}
	public bool contains(int arg) {
		return min <= arg
			&& arg <= max;
	}
	public bool isFixed() {
		checkLength();
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

	/* for force resolve */
	Extent deepCopy(Extent cpPrev) {
		Extent cp = new Extent(this.getCell, this.length, cpPrev);
		cp.min = this.min;
		cp.max = this.max;
		return cp;
	}
	int getScore() {
		// 0-...
		return max - min + 1 - length;
	}


	public override string toString() {
		return format("%d-%d@%d", min, max, length);
	}
}
