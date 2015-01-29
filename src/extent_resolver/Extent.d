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
	unittest {
		Cell[] cells = [Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Empty
			, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown
			, Cell.Empty, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Fill];
		Cell getCell(int pos) {
			if (pos < 0 || pos >= cells.length)
				return Cell.Empty;
			return cells[pos];
		}
		void testGetShorten() {
			Extent ext = new Extent(&getCell, 3, null);
			ext.max = cells.length;
			ext.min = 0;
			assert(0 == ext.getShorten(0, 1)); // where len3 block can be in [X???_???????_???X] ?
			assert(4 == ext.getShorten(1, 1)); // where len3 block can be in [X???_???????_???X] ?(but more than @1)
			assert(0 == ext.getShorten(16, -1)); // where len3 block can be in [X???_???????_???X] ?
			assert(-4 == ext.getShorten(15, -1)); // where len3 block can be in [X???_???????_???X] ?(but less than @7)
		}
		void testShortenChain() {
			Extent ext1 = new Extent(&getCell, 3, null);
			Extent ext2 = new Extent(&getCell, 3, ext1);
			Extent ext3 = new Extent(&getCell, 3, ext2);
			ext1.max = cells.length - 1;
			ext1.min = 0;
			ext2.max = cells.length - 1;
			ext2.min = 0;
			ext3.max = cells.length - 1;
			ext3.min = 0;
			ext1.shortenMin(1);
			assert(5 == ext1.min); // smoke
			assert(9 == ext2.min); // chain to next
			assert(14 == ext3.min); // chain to next after next
			ext1.max = cells.length - 1;
			ext1.min = 0;
			ext2.max = cells.length - 1;
			ext2.min = 0;
			ext3.max = cells.length - 1;
			ext3.min = 0;
			ext3.shortenMax(cells.length - 2);
			assert(11 == ext3.max); // smoke
			assert(7 == ext2.max); // chain to prev
			assert(2 == ext1.max); // chain to prev before prev
		}
		testGetShorten();
		testShortenChain();
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
	unittest {
		Extent ext = new Extent(null, 5, null);
		ext.min = 1;
		ext.max = 7;
		void callback(int arg) {
			assert(arg == 3 || arg == 4 || arg == 5);
		}
		ext.fillCenter(&callback);
	}

	/* for force resolve */
	Extent deepCopy(Cell delegate(int) getCell, Extent cpPrev) {
		Extent cp = new Extent(getCell, this.length, cpPrev);
		cp.min = this.min;
		cp.max = this.max;
		return cp;
	}
	unittest {
		Cell getCell1(int pos) { return Cell.Unknown; }
		Cell getCell2(int pos) { return Cell.Unknown; }
		Extent exOriginParent = new Extent(null, 1, null);
		Extent exCopyParent = new Extent(null, 1, null);
		Extent exOrigin = new Extent(&getCell1, 1, exOriginParent);
		Extent exCopy = exOrigin.deepCopy(&getCell2, exCopyParent); // TODO getCell
		assert(exOrigin.min == exCopy.min);
		assert(exOrigin.max == exCopy.max);
		assert(exOrigin.length == exCopy.length);
		assert(exOrigin.getCell != exCopy.getCell);
	}

	int getScore() {
		// 0-...
		return max - min + 1 - length;
	}


	public override string toString() {
		return format("%d-%d@%d", min, max, length);
	}
}
