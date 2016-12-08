module extent.LinePossibility0;

private import std.algorithm;
private import std.range;
private import std.stdio;
private import std.string;

private import extent.Extent0;
private import parts.CompList;
private import common;

class LinePossibility {
	private immutable(pos[]) hints;
	private bool[pos] eventDone;
	private Extent extents;
	private pos size;
	private Cell[] cells;
	private Cell getCell(pos p) {
		if (0 <= p && p < size) {
			return cells[p];
		} else {
			return Cell.Empty;
		}
	}

	this(pos size, immutable(pos[]) hints, string dbg="") {
		pos temp = 0;
		Extent extPrev;
		Extent head;
		Extent ext;
		for (int i = 0; i < hints.length; i ++) {
			ext = new Extent(hints[i], extPrev, format("%s::%s %d", dbg, hints, size));
			if (i == 0) {
				head = ext;
			}
			ext.min = temp;
			extPrev = ext;
			temp += hints[i] + 1;
		}
		temp = size - 1;
		for (pos i = hints.length - 1; i >= 0; i --) {
			ext.max = temp;
			temp -= hints[i] + 1;
			ext = ext.prev;
		}
		bool[pos] ed;
		cells.length = size;
		for (int i = 0; i < size; i ++) {
			cells[i] = Cell.Unknown;
		}
		this(size, hints, head, ed, cells);
	}

	/*
	 Constructor for copy.
	 */
	private this(pos size, immutable(pos[]) hints, Extent extents, bool[pos] eventDone, Cell[] cells) {
		this.size = size;
		this.hints = hints;
		this.cells = cells;

		this.extents = extents;
		this.eventDone = eventDone;
	}

	public bool isChecked(pos pos) {
		if (pos in eventDone) {
			return true;
		} else {
			return false;
		}
	}
	public void checkUp(SetCell callback) {
		if (this.extents is null) {
			// Extent がなければ全部Empty
			for (int i = 0; i < this.size; i ++) {
				if (i !in this.eventDone) {
					callback(Cell.Empty, i);
				}
			}
		} else {
			pos prevMax = -1;
			for (Extent ex = this.extents; ex !is null; ex = ex.next) {
				ex.cleanUp(callback);
				// Extentが定まっていれば両端はEmptyに
				if (ex.isFixed()) {
					if (ex.min-1 >= 0)
						callback(Cell.Empty, ex.min-1);
					if (ex.max+1 < size)
						callback(Cell.Empty, ex.max+1);
				}
				// Extent に隙間があればEmptyに
				for (pos i = prevMax + 1; i < ex.min; i ++) {
					callback(Cell.Empty, i);
				}
				prevMax = ex.max;
			}
			for (pos i = prevMax + 1; i < size; i ++) {
				callback(Cell.Empty, i);
			}

			eachFillCell(0, size - 1, (i) {
				Extent[] containsList = [];
				for (Extent ext = extents; ext !is null; ext = ext.next) {
					if (ext.contains(i)) {
						containsList ~= ext;
					}
				}
				emptyIfAllExtentLength_lessThanNow(containsList, i, callback);
				return true;
			});
		}
	}
	unittest {
		Extent testExtentList(pos[][] fromToList) {
			Extent prev = null;
			Extent list = null;
			foreach (pos[] fromTo; fromToList) {
				Extent obj = new Extent(fromTo[0], prev);
				if (list is null) {
					list = obj;
				}
				obj.min = fromTo[1];
				obj.max = fromTo[2];
				prev = obj;
			}
			return list;
		}
		auto callbackForTest(ref Cell[pos] stock) {
			return (Cell c, pos pos) {
				stock[pos] = c;
			};
		}
		{
			Cell[pos] stock;
			bool[pos] done;
			auto lp1 = new LinePossibility(4, [1], testExtentList([[1,0,3]]), done, [Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown]);
			lp1.checkUp(callbackForTest(stock));
			assert(stock.length == 0);
			auto lp2 = new LinePossibility(4, [1], testExtentList([[1,1,2]]), done, [Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown]);
			lp2.checkUp(callbackForTest(stock));
			assert(stock == [cast(pos)(0):Cell.Empty, cast(pos)(3):Cell.Empty]);
		}
		{
			Cell[pos] stock;
			bool[pos] done;
			auto lp = new LinePossibility(5, [2], testExtentList([[2,1,3]]), done, [Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown]);
			lp.checkUp(callbackForTest(stock));
			assert(stock == [cast(pos)(2):Cell.Fill, cast(pos)(0):Cell.Empty, cast(pos)(4):Cell.Empty]);
		}
		{
			Cell[pos] stock;
			bool[pos] done;
			auto lp = new LinePossibility(9, [2, 2], testExtentList([[2,1,3], [2,5,8]]), done, [Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown,Cell.Unknown]);
			lp.checkUp(callbackForTest(stock));
			assert(stock == [cast(pos)(2):Cell.Fill, cast(pos)(0):Cell.Empty, cast(pos)(4):Cell.Empty]);
		}
	}

	/**
	 セルを設定します。その結果として、各Extentは縮小する可能性があります。
	 各Extentが縮小した場合、checkUpをおこないます。
	 設定のキャンセルはできません。(Unknown指定はエラー仕様外)
	 Questに対して矛盾が検知されると、ExclusiveException例外が送出します。
	**/
	public bool set(Cell cell, pos pos) {
		assert(cell != Cell.Unknown);
		if (pos in eventDone) {
			return false;
		} else {
			eventDone[pos] = true;
		}
		cells[pos] = cell;
		bool ret;
		if (cell == Cell.Empty) {
			ret = setEmpty(pos);
		} else if (cell == Cell.Fill) {
			ret = setFill(pos);
		} else {
			assert(false, "Invalid cell setting.");
			return false;
		}
		ret |= eachFillCell(0, this.size - 1, (pos) {
			return checkContainsFilled(pos);
		});
		return ret;
	}
	private bool setEmpty(pos pos) {
		bool ret = false;
		Extent[] containsList = [];
		for (Extent ex = extents; ex !is null; ex = ex.next) {
			if (ex.contains(pos)) {
				containsList ~= ex;
			}
		}
		foreach(Extent ex; containsList) {
			if (ex.contains(pos)) {
				ex.setCell(pos, Cell.Empty);
				ret = true;
			}
		}
		return ret;
	}
	private bool setFill(pos pos) {
		bool ret = false;

		for (Extent ex = extents; ex !is null; ex = ex.next) {
			if (ex.min - 1 == pos) {
				ex.min(ex.min + 1);
				ret = true;
			}
		}
		for (Extent ex = extents; ex !is null; ex = ex.next) {
			if (ex.max + 1 == pos) {
				ex.max(ex.max - 1);
				ret = true;
			}
		}
		return ret;
	}
	unittest {
		/*
		 テスト用の状況設定は以下。
		 ??????_???X???
		 ----2----
		        ---4---
		*/
		Cell[] init = [Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Empty, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown];
		LinePossibility initTest(Cell[] cells, Extent extents) {
			bool[pos] eventDone;
			return new LinePossibility(
				cells.length,
				[2,4],
				extents,
				eventDone,
				cells);
		}
		Extent testExtentList(GetCell getCell, pos[][] fromToList) {
			Extent prev = null;
			Extent head = null;
			foreach (pos[] fromTo; fromToList) {
				Extent obj = new Extent(fromTo[0], prev);
				obj.min = fromTo[1];
				obj.max = fromTo[2];
				prev = obj;
				if (head is null) {
					head = obj;
				}
			}
			return head;
		}
		Cell[] cells;
		Cell getCell(pos pos) {
			if (0 <= pos && pos < cells.length) {
				return cells[pos];
			} else {
				return Cell.Empty;
			}
		}
		Cell[pos] called = null;
		void setCell(Cell c, pos pos) {
			called[pos] = c;
		}
		testSetFill: {
			cells = .deepCopy!(Cell)(init);
			called = null;

			Extent extents = testExtentList(&getCell, [[2,0,8],[4,7,13]]);
			auto lp = initTest(cells, extents);
			cells[6] = Cell.Empty;lp.set(Cell.Empty, 6);
			cells[9] = Cell.Fill;lp.set(Cell.Fill, 9);
			lp.checkUp(&setCell);
			assert(called == [cast(pos)(9): Cell.Fill, cast(pos)(13): Cell.Empty]
				|| called == [cast(pos)(9): Cell.Fill, cast(pos)(10): Cell.Fill, cast(pos)(13): Cell.Empty] // Fill@10 はコールバックされてもされなくてもOK(決定済み)
				|| called == [cast(pos)(6): Cell.Empty, cast(pos)(9): Cell.Fill, cast(pos)(13): Cell.Empty] // Empty@6 はコールバックされてもされなくてもOK(決定済み)
				|| called == [cast(pos)(6): Cell.Empty, cast(pos)(9): Cell.Fill, cast(pos)(10): Cell.Fill, cast(pos)(13): Cell.Empty]);
			assert(extents.min == 0);
			assert(extents.max == 5, format("%d (want; 5)", extents.max));
			assert(extents.next.min == 7);
			assert(extents.next.max == 12);
		}
		testSetEmpty: {
			cells = .deepCopy!(Cell)(init);
			called = null;

			Extent extents = testExtentList(&getCell, [[2,0,8],[4,7,13]]);
			auto lp = initTest(cells, extents);
			cells[6] = Cell.Empty;lp.set(Cell.Empty, 6);
			cells[8] = Cell.Empty;lp.set(Cell.Empty, 8);
			lp.checkUp(&setCell);
			assert(called == [cast(pos)(7): Cell.Empty, cast(pos)(8): Cell.Empty, cast(pos)(11): Cell.Fill, cast(pos)(12): Cell.Fill]
				|| called == [cast(pos)(6): Cell.Empty, cast(pos)(7): Cell.Empty, cast(pos)(8): Cell.Empty, cast(pos)(11): Cell.Fill, cast(pos)(12): Cell.Fill] // Empty@6 はコールバックされてもされなくてもOK(決定済み)
				|| called == [cast(pos)(7): Cell.Empty, cast(pos)(8): Cell.Empty, cast(pos)(10): Cell.Fill, cast(pos)(11): Cell.Fill, cast(pos)(12): Cell.Fill] // Fill@10 はコールバックされてもされなくてもOK(決定済み)
				|| called == [cast(pos)(6): Cell.Empty, cast(pos)(7): Cell.Empty, cast(pos)(8): Cell.Empty, cast(pos)(10): Cell.Fill, cast(pos)(11): Cell.Fill, cast(pos)(12): Cell.Fill]);
			assert(extents.min == 0);
			assert(extents.max == 5);
			assert(extents.next.min == 9);
			assert(extents.next.max == 13);
		}
		testSet3: {
			/*
			 テスト用の状況設定は以下。
			     X
			 ??X????X???
			 -1-
			   --1---
			       -2---
			*/
			cells = [Cell.Unknown, Cell.Unknown, Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown];
			void _myCallBack1(Cell c, pos pos) {
				cells[pos] = c;
			}

			Extent extents = testExtentList(&getCell, [[1,0,2],[1,2,7],[2,6,10]]);
			auto lp = initTest(cells, extents);
			cells[2] = Cell.Fill; lp.set(Cell.Fill, 2);
			cells[7] = Cell.Fill; lp.set(Cell.Fill, 7);

			cells[4] = Cell.Fill; lp.set(Cell.Fill, 4);
			lp.checkUp(&_myCallBack1);
			assert(cells == [Cell.Empty, Cell.Empty, Cell.Fill, Cell.Empty, Cell.Fill, Cell.Empty, Cell.Unknown, Cell.Fill, Cell.Unknown, Cell.Empty, Cell.Empty]);
		}
		testSet4: {
			/*
			 テスト用の状況設定は以下。
			  _
			 ??X_???
			 -1-
			  ---2--
			*/
			cells = [Cell.Unknown, Cell.Empty, Cell.Fill, Cell.Empty, Cell.Unknown, Cell.Unknown, Cell.Unknown];
			void _myCallBack2(Cell c, pos pos) {
				cells[pos] = c;
			}

			Extent extents = testExtentList(&getCell, [[1,0,2],[2,1,6]]);
			auto lp = initTest(cells, extents);
			lp.set(Cell.Fill, 2);
			lp.set(Cell.Empty, 3);

			lp.set(Cell.Empty, 1);
			lp.checkUp(&_myCallBack2);
			assert(cells == [Cell.Empty, Cell.Empty, Cell.Fill, Cell.Empty, Cell.Unknown, Cell.Fill, Cell.Unknown]);
		}
	}

	private bool checkContainsFilled(pos pos) {
		bool ret = false;
		Extent[] containsList = [];
		for (Extent ex = extents; ex !is null; ex = ex.next) {
			if (ex.contains(pos)) {
				containsList ~= ex;
			}
		}
		if (containsList.length != 0) {
			// first and last one shorten.
			auto cFirst = containsList[0];
			auto cLast = containsList[$-1];

			auto newMax = pos + cFirst.length - 1;
		 	auto newMin = pos - cLast.length + 1;
			for (auto i = pos+1; i <= newMax; i ++) {
				if (getCell(i) == Cell.Empty) {
					newMax = i - 1;
					break;
				}
			}
			for (auto i = pos-1; i >= newMin; i --) {
				if (getCell(i) == Cell.Empty) {
					newMin = i + 1;
					break;
				}
			}
			if (cFirst.max > newMax) {
				auto oldValue = cFirst.max;
				cFirst.max = newMax;
				eachFillCell(newMax + 1, oldValue, &checkContainsFilled);
				ret = true;
			}
			if (cLast.min < newMin) {
				auto oldValue = cLast.min;
				cLast.min = newMin;
				eachFillCell(oldValue, newMin - 1, &checkContainsFilled);
				ret = true;
			}

			//emptyIfAllExtentLength_lessThanNow(containsList, pos);
		} else {
			throw new ExclusiveException("No Extent at");
		}
		return ret;
	}
	private void emptyIfAllExtentLength_lessThanNow(Extent[] containsList, pos pos, SetCell callback) {
		auto min = pos;
		auto max = pos;
		while (getCell(min-1) ==  Cell.Fill)
			min --;
		while (getCell(max+1) ==  Cell.Fill)
			max ++;
		auto length = max - min + 1;
		if (filter!(ex => ex.length > length)(containsList).array().length == 0) {
			callback(Cell.Empty, min - 1);
			callback(Cell.Empty, max + 1);
		}
	}
	private bool eachFillCell(pos min, pos max, bool delegate(pos) action) {
		bool hasChange = false;
		for (pos i = min; i <= max; i ++) {
			if (getCell(i) == Cell.Fill) {
				hasChange |= action(i);
			}
		}
		return hasChange;
	}
	public bool done() {
		for (Extent ex = extents; ex !is null; ex = ex.next) {
			if (! ex.isFixed()) {
				return false;
			}
		}
		return true;
	}

	/* for force resolve */
	LinePossibility deepCopy(GetCell getCell) {
		Extent cp = new Extent(extents);
		bool[pos] ed;
		foreach (key, val; this.eventDone) {
			ed[key] = val;
		}
		return new LinePossibility(size, hints, cp, ed, cells.dup());
	}

	public override string toString() {
		string str = "";
		for (Extent ex = extents; ex !is null; ex = ex.next) {
			str ~= ex.toString();
			str ~= " ";
		}
		return format("%s[%d]", str, size);
	}
}
unittest {
	auto E = Cell.Empty;
	auto U = Cell.Unknown;
	auto F = Cell.Fill;
	auto INIT = [U,U,U,U,U,U,U,U,U,U
				,U,U,U,U,U,U,U,U,U,U
				,U,U,U,U,U,U,U,U,U,U];
	auto cells = INIT;
	Cell getCell(pos pos) {
		if (0 <= pos && pos < cells.length) { return cells[pos]; }
		return E;
	}
	void setCell(Cell c, pos pos) {
		if (0 <= pos && pos < cells.length)
			cells[pos] = c;
	}
	void test(pos[] order) {
		cells = INIT;
		auto lp = new LinePossibility(30, [7,5]);
		foreach (pos p; order) {
			lp.set(Cell.Fill, p);
			lp.checkUp(&setCell);
		}
		assert([E,U,U,U,U,U,U,F,U,U,U,U,U,U,E,E,E,E,E,E,E,E,E,E,E,F,F,F,F,F] == cells);
	}
	test([7, 29]);
	test([29, 7]);
}
unittest {
	auto E = Cell.Empty;
	auto U = Cell.Unknown;
	auto F = Cell.Fill;
	auto INIT = [F,U];
	auto cells = INIT;
	Cell getCell(pos pos) {
		if (0 <= pos && pos < cells.length) { return cells[pos]; }
		return E;
	}
	void setCell(Cell c, pos pos) {
		if (0 <= pos && pos < cells.length)
			cells[pos] = c;
	}
	void test() {
		cells = INIT;
		auto lp = new LinePossibility(2, [1]);
		lp.set(F, 0);
		lp.checkUp(&setCell);
		assert([F,E] == cells, "Why must set explicit ??");
	}
	test();
}
unittest {
	auto F = Cell.Fill;
	auto E = Cell.Empty;
	auto U = Cell.Unknown;
	auto cells = [E,F,F,E,F,F,E,U,E,U,U,U,F,U,U,U,F,U,U,U,U,U,U,U,U,U,U,U,U,U];
	void setCell(Cell c, pos pos) {
		if (0 <= pos && pos < cells.length)
			cells[pos] = c;
	}
	auto lp = new LinePossibility(30,[2,2,3,9,5]);
	foreach (i, c; cells) {
		if (c != U) {
			lp.set(c, i);
		}
	}
	lp.checkUp(&setCell);
	assert(cells == [E,F,F,E,F,F,E,E,E,E,U,F,F,U,U,F,F,F,F,F,F,F,F,U,U,F,F,F,F,U]);
}
unittest {
	auto F = Cell.Fill;
	auto E = Cell.Empty;
	auto U = Cell.Unknown;
	auto cells = [U,F,U,F,U,U,U,U,U,U,F,U,F,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U];
	void setCell(Cell c, pos pos) {
		if (0 <= pos && pos < cells.length)
			cells[pos] = c;
	}
	auto lp = new LinePossibility(30,[2,1,1,1,2,2,1,2,4]);
	foreach (i, c; cells) {
		if (c != U) {
			lp.set(c, i);
		}
	}
	lp.checkUp(&setCell);

	lp.set(E, 5);
	lp.checkUp(&setCell);
	assert(cells == [F,F,E,F,E,E,U,U,U,E,F,E,F,U,U,U,U,U,U,U,U,U,U,U,U,U,F,U,U,U]);
}
