module extent.Extent;

import std.exception;
private import std.string;
private import std.algorithm;
private import std.stdio;
private import common;
private import extent.ShortenListener;

/// ヒントで示された[長さ]が取りうる位置範囲。
///
/// min, max がそれぞれ左右を指すのか、それとも上下を指すのかは、このオブジェクトを保持するコンテキストに依存します。
/// 両隣の位置範囲情報への参照を持ったリンクリスト実装です。
///
/// shorten**メソッドによって、このオブジェクトは自律的に短縮をします。この際、コンストラクタで指定されたgetCellによって各座標のCell内容を得ます。
/// また、shorten**メソッドによって範囲の見直しが発生すると、両隣のExtentに対してもshorten** の連鎖を起こします。
class Extent : ShortenOwner!(Extent) {
private const string dbg;
	private GetCell getCell;
	private ShortenListener!(Extent) listener;
	private Extent _prev;
	private Extent _next;
	private pos _length;
	private pos _min;
	private pos _max;

	Extent prev() { return _prev; }
	Extent next() { return _next; }
	pos min() { return _min; }
	pos max() { return _max; }
	pos length() { return _length; }
	package void min(pos arg) { _min = arg; }
	package void max(pos arg) { _max = arg; }

	this(GetCell getCell, pos length, Extent prev, string dbg="") {
this.dbg = dbg;
		this.getCell = getCell;
		this._length = length;
		this._prev = prev;
		if (prev) {
			prev.setNext(this);
		}
		this.listener = new ShortenListener!(Extent)(this);
	}
	private void setNext(Extent next) {
		this._next = next;
	}

	public void shortenMin(pos p) {
		if (p > min) {
			pos minDef = min;
			pos len = getShorten(p, +1);
			writefln("s:%d %s %d", p, this, len);
			min = p + len;
			checkLength();
			if (next !is null)
				next.shortenMin(min + length + 1);

			listener.minShorted(minDef, getCell);
		}
	}
	public void shortenMax(pos p) {
		if (p < max) {
			pos maxDef = max;
			pos len = getShorten(p, -1);
			max = p + len;
			checkLength();
			if (prev !is null)
				prev.shortenMax(max - length - 1);

			listener.maxShorted(maxDef, getCell);
		}
	}
	private pos getShorten(pos p, int direction) {
		pos temp = 0;
		bool more;
		do {
			more = false;
			pos edge = p + temp;
			pos edge2 = edge + (direction * length) - direction;
			if (getCell(edge - direction) == Cell.Fill
				|| getCell(edge2 + direction) == Cell.Fill) {
				temp += direction;
				more = true;
			} else {
				for (pos i = length - 1; i >= 0; i --) {
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
		// X??? ??????? ???X
		Cell[] cells = [ Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Empty
			, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown
			, Cell.Empty, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Fill];
		Cell getCell(pos p) {
			if (p < 0 || p >= cells.length)
				return Cell.Empty;
			return cells[p];
		}
		void testGetShorten() {
			Extent ext = new Extent(&getCell, 3, null);
			ext.max = cells.length;
			ext.min = 0;
			assert(0 == ext.getShorten(0, 1)); // where len3 block can be in [X???_???????_???X] ?
			assert(4 == ext.getShorten(1, 1)); // where len3 block can be in [X???_???????_???X] ?(but more than @1)
			assert(0 == ext.getShorten(9, 1)); // to be [---------???_???X]
			assert(4 == ext.getShorten(10, 1)); // to be [--------------??X]
			assert(0 == ext.getShorten(16, -1)); // where len3 block can be in [X???_???????_???X] ?
			assert(-4 == ext.getShorten(15, -1)); // where len3 block can be in [X???_???????_???X] ?(but less than @7)
		}
		void testShortenChain() {
			Extent ext1 = new Extent(&getCell, 3, null);
			Extent ext2 = new Extent(&getCell, 3, ext1);
			Extent ext3 = new Extent(&getCell, 3, ext2);
			void init() {
				ext1.max = cells.length - 2;
				ext1.min = 0;
				ext2.max = cells.length - 2;
				ext2.min = 1;
				ext3.max = cells.length - 1;
				ext3.min = 1;
			}
			init();
			ext1.shortenMin(1);
			// to be [X??? ??????? ???X]
			//  ext1:      ---...
			//  ext2:          ---...
			//  ext3:               ---
			assert(5 == ext1.min); // smoke
			assert(9 == ext2.min); // chain to next
			assert(14 == ext3.min); // chain to next after next

			init();
			ext3.shortenMax(cells.length - 2);
			assert(11 == ext3.max); // smoke
			assert(7 == ext2.max); // chain to prev
			assert(2 == ext1.max); // chain to prev before prev
		}
		testGetShorten();
		testShortenChain();
	}
	unittest {
		// ?X???X???
		Cell[] cells = [Cell.Unknown, Cell.Fill
				, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Fill
				, Cell.Unknown, Cell.Unknown, Cell.Unknown];
		Cell getCell(pos p) {
			if (p < 0 || p >= cells.length)
				return Cell.Empty;
			return cells[p];
		}
		void testShortenNOTchained() {
			Extent ext1 = new Extent(&getCell, 2, null);
			Extent ext2 = new Extent(&getCell, 2, ext1);
			Extent ext3 = new Extent(&getCell, 2, ext2);
			ext1.max = cells.length - 1;
			ext1.min = 0;
			ext2.max = cells.length - 1;
			ext2.min = 0;
			ext3.max = cells.length - 1;
			ext3.min = 0;
			ext1.shortenMax(2);
			assert(0 == ext1.min);
			assert(2 == ext1.max);
			assert(0 == ext2.min);
			assert(8 == ext2.max);
			assert(0 == ext3.min);
			assert(8 == ext3.max);
		}
		void testShortenChained() {
			Extent ext1 = new Extent(&getCell, 2, null);
			Extent ext2 = new Extent(&getCell, 2, ext1);
			ext1.max = cells.length - 1;
			ext1.min = 0;
			ext2.max = cells.length - 1;
			ext2.min = 0;
			ext1.shortenMax(2);
			assert(0 == ext1.min);
			assert(2 == ext1.max);
			assert(4 == ext2.min);
			assert(6 == ext2.max);
		}
		testShortenNOTchained();
		testShortenChained();
	}

	private void checkLength() {
		if (max - min + 1 < length)
			throw new ExclusiveException(format(
				"Length %d(%d)", max - min + 1, length));
	}
	public bool contains(pos arg) {
		return min <= arg
			&& arg <= max;
	}
	public bool isFixed() {
		checkLength();
		return max - min + 1 == length;
	}
	public void fillCenter(void delegate(pos ) fillCallback) {
		pos d = length * 2 - (max - min + 1);
		if (d <= 0) {
			return;
		} else {
			pos fillMin = max - length + 1;
			pos fillMax = min + length - 1;
			for (pos i = fillMin; i <= fillMax; i ++) {
				fillCallback(i);
			}
		}
	}
	unittest {
		Extent ext = new Extent(null, 5, null);
		ext.min = 1;
		ext.max = 7;
		pos[] called = [];
		void callback(pos arg) {
			called ~= arg;
		}
		ext.fillCenter(&callback);
		pos[] expected = [3,4,5];
		assert(sort!("a>b")(called) == sort!("a>b")(expected));
		writeln(called);
	}

	/* for force resolve */
	Extent deepCopy(GetCell getCell, Extent cpPrev) {
		Extent cp = new Extent(getCell, this.length, cpPrev);
		cp.min = this.min;
		cp.max = this.max;
		return cp;
	}
	unittest {
		Cell getCell1(pos p) { return Cell.Unknown; }
		Cell getCell2(pos p) { return Cell.Unknown; }
		Extent exOriginParent = new Extent(null, 1, null);
		Extent exCopyParent = new Extent(null, 1, null);
		Extent exOrigin = new Extent(&getCell1, 1, exOriginParent);
		Extent exCopy = exOrigin.deepCopy(&getCell2, exCopyParent); // TODO getCell
		assert(exOrigin.min == exCopy.min);
		assert(exOrigin.max == exCopy.max);
		assert(exOrigin.length == exCopy.length);
		assert(exOrigin.getCell != exCopy.getCell);
	}

	pos getScore() {
		// 0-...
		return max - min + 1 - length;
	}

	public override string toString() {
		return format("%s %d-%d@%d", dbg, min, max, length);
	}
}
