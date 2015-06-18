module extent.LinePossibility;

private import std.algorithm;
private import std.range;
private import std.stdio;
private import std.string;

private import extent.Extent;
private import parts.Resolver;
private import parts.CompList;
private import common;

alias void delegate(Cell, pos) SetCell;

class LinePossibility {
	private pos[] hints;
	private bool[pos] eventDone;
	private Extent[] extents;
	private pos size;
	private SetCell callback;
	private GetCell getCell;

	this(pos size, pos[] hints, SetCell f, GetCell getF, string dbg="") {
		void mixedF(Cell c, pos p) {
			set(c, p);
			f(c,p);
		}
		Extent[] exts;
		exts.length = hints.length;
		pos temp = 0;
		for (int i = 0; i < hints.length; i ++) {
			exts[i] = new Extent(getF, hints[i], i == 0 ? null : exts[i-1], dbg ~ format("::%s %d", hints, size));
			exts[i].min = temp;
			temp += hints[i] + 1;
		}
		temp = size - 1;
		for (pos i = hints.length - 1; i >= 0; i --) {
			exts[i].max = temp;
			temp -= hints[i] + 1;
		}
		bool[pos] ed;
		this(size, hints, exts, ed, &mixedF, getF);
	}

	/*
	 Constructor for copy.
	 */
	private this(pos size, pos[] hints, Extent[] extents, bool[pos] eventDone, SetCell callback, GetCell getCell) {
		this.size = size;
		this.hints = hints;
		this.callback = callback;
		this.getCell = getCell;

		this.extents = extents;
		this.eventDone = eventDone;
	}

	bool isChecked(pos pos) {
		if (pos in eventDone) {
			return true;
		} else {
			return false;
		}
	}
	public void checkUp() {
		checkUpFunc(this.extents, this.size, this.callback);
	}
	private static void checkUpFunc(Extent[] extents, pos size, SetCell callback) {
		if (extents.length == 0) {
			for (int i = 0; i < size; i ++) {
				callback(Cell.Empty, i);
			}
		} else {
			pos prevMax = -1;
			foreach (Extent ex; extents) {
				if (ex.isFixed()) {
					if (ex.min-1 >= 0)
						callback(Cell.Empty, ex.min-1);
					if (ex.max+1 < size)
						callback(Cell.Empty, ex.max+1);
				}
				for (pos i = prevMax + 1; i < ex.min; i ++) {
					callback(Cell.Empty, i);
				}
				ex.fillCenter(x => callback(Cell.Fill, x));
				prevMax = ex.max;
			}
			for (pos i = prevMax + 1; i < size; i ++) {
				callback(Cell.Empty, i);
			}
		}
	}
	unittest {
		Extent[] testExtentList(GetCell getCell, pos[][] fromToList) {
			Extent prev = null;
			Extent[] list = [];
			foreach (pos[] fromTo; fromToList) {
				Extent obj = new Extent(getCell, fromTo[0], prev);
				obj.min = fromTo[1];
				obj.max = fromTo[2];
				prev = obj;
				list ~= obj;
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
			checkUpFunc(testExtentList(null, [[1,0,3]]), 4, callbackForTest(stock));
			assert(stock.length == 0);
			checkUpFunc(testExtentList(null, [[1,1,2]]), 4, callbackForTest(stock));
			assert(stock == [cast(pos)(0):Cell.Empty, cast(pos)(3):Cell.Empty]);
		}
		{
			Cell[pos] stock;
			checkUpFunc(testExtentList(null, [[2,1,3]]), 5, callbackForTest(stock));
			assert(stock == [cast(pos)(2):Cell.Fill, cast(pos)(0):Cell.Empty, cast(pos)(4):Cell.Empty]);
		}
		{
			Cell[pos] stock;
			checkUpFunc(testExtentList(null, [[2,1,3], [2,5,8]]), 9, callbackForTest(stock));
			assert(stock == [cast(pos)(2):Cell.Fill, cast(pos)(0):Cell.Empty, cast(pos)(4):Cell.Empty]);
		}
	}

	/**
	 セルを設定します。その結果として、各Extentは縮小する可能性があります。
	 各Extentが縮小した場合、checkUpをおこないます。
	 設定のキャンセルはできません。(Unknown指定はエラー仕様外)
	 Questに対して矛盾が検知されると、ExclusiveException例外が送出します。
	**/
	void set(Cell cell, pos pos) {
		assert(cell != Cell.Unknown);
		if (pos in eventDone) {
			return;
		} else {
			eventDone[pos] = true;
		}
		bool hasChange = false;
		if (cell == Cell.Empty) {
			hasChange |= setEmpty(pos);
		} else if (cell == Cell.Fill) {
			hasChange |= setFill(pos);
		} else {
			assert(false, "Invalid cell setting.");
		}
		if (hasChange) {
			checkUp();
		}
	}
	unittest {
		/*
		 テスト用の状況設定は以下。
		 ??????_???X???
		 ----2----
		        ---4---
		*/
		Cell[] init = [Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Empty, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown];
		LinePossibility initTest(Cell[] cells, SetCell callback, Extent[] extents, GetCell getCell) {
			bool[pos] eventDone;
			return new LinePossibility(
				cells.length,
				[2,4],
				extents,
				eventDone,
				callback,
				getCell);
		}
		Extent[] testExtentList(GetCell getCell, pos[][] fromToList) {
			Extent prev = null;
			Extent[] list = [];
			foreach (pos[] fromTo; fromToList) {
				Extent obj = new Extent(getCell, fromTo[0], prev);
				obj.min = fromTo[1];
				obj.max = fromTo[2];
				prev = obj;
				list ~= obj;
			}
			return list;
		}
		Cell[] cells;
		Cell getCell(pos pos) {
			return cells[pos];
		}
		Cell[pos] called = null;
		void myCallBack(Cell c, pos pos) {
			called[pos] = c;
		}
		testSetFill: {
			cells = .deepCopy!(Cell)(init);
			called = null;

			Extent[] extents = testExtentList(&getCell, [[2,0,8],[4,7,13]]);
			auto lp = initTest(cells, &myCallBack, extents, &getCell);
			lp.set(Cell.Fill, 9);
			assert(called == [cast(pos)(9): Cell.Fill, cast(pos)(13): Cell.Empty]
				|| called == [cast(pos)(9): Cell.Fill, cast(pos)(10): Cell.Fill, cast(pos)(13): Cell.Empty] // Fill@10 はコールバックされてもされなくてもOK(決定済み)
				|| called == [cast(pos)(6): Cell.Empty, cast(pos)(9): Cell.Fill, cast(pos)(13): Cell.Empty] // Empty@6 はコールバックされてもされなくてもOK(決定済み)
				|| called == [cast(pos)(6): Cell.Empty, cast(pos)(9): Cell.Fill, cast(pos)(10): Cell.Fill, cast(pos)(13): Cell.Empty]);
			assert(extents[0].min == 0);
			assert(extents[0].max == 5);
			assert(extents[1].min == 7);
			assert(extents[1].max == 12);
		}
		testSetEmpty: {
			cells = .deepCopy!(Cell)(init);
			called = null;

			Extent[] extents = testExtentList(&getCell, [[2,0,8],[4,7,13]]);
			auto lp = initTest(cells, &myCallBack, extents, &getCell);
			lp.set(Cell.Empty, 8);
			assert(called == [cast(pos)(7): Cell.Empty, cast(pos)(8): Cell.Empty, cast(pos)(11): Cell.Fill, cast(pos)(12): Cell.Fill]
				|| called == [cast(pos)(6): Cell.Empty, cast(pos)(7): Cell.Empty, cast(pos)(8): Cell.Empty, cast(pos)(11): Cell.Fill, cast(pos)(12): Cell.Fill] // Empty@6 はコールバックされてもされなくてもOK(決定済み)
				|| called == [cast(pos)(7): Cell.Empty, cast(pos)(8): Cell.Empty, cast(pos)(10): Cell.Fill, cast(pos)(11): Cell.Fill, cast(pos)(12): Cell.Fill] // Fill@10 はコールバックされてもされなくてもOK(決定済み)
				|| called == [cast(pos)(6): Cell.Empty, cast(pos)(7): Cell.Empty, cast(pos)(8): Cell.Empty, cast(pos)(10): Cell.Fill, cast(pos)(11): Cell.Fill, cast(pos)(12): Cell.Fill]);
			assert(extents[0].min == 0);
			assert(extents[0].max == 5);
			assert(extents[1].min == 9);
			assert(extents[1].max == 13);
		}
		testSet3: {
			/*
			 テスト用の状況設定は以下。
			     X
			 ??X????X???
			 -1-
			   --1---
			       -2--
			*/
			cells = [Cell.Unknown, Cell.Unknown, Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown];
			void _myCallBack1(Cell c, pos pos) {
				cells[pos] = c;
			}

			Extent[] extents = testExtentList(&getCell, [[1,0,2],[1,2,7],[2,6,10]]);
			auto lp = initTest(cells, &_myCallBack1, extents, &getCell);
			lp.set(Cell.Fill, 4);
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

			Extent[] extents = testExtentList(&getCell, [[1,0,2],[2,1,6]]);
			auto lp = initTest(cells, &_myCallBack2, extents, &getCell);
			lp.set(Cell.Empty, 1);
			lp.checkUp();
			writeln(cells);
			writeln(extents);
			assert(cells == [Cell.Empty, Cell.Empty, Cell.Fill, Cell.Empty, Cell.Unknown, Cell.Fill, Cell.Unknown]);
		}
	}
	private bool setEmpty(pos pos) {
		bool ret = false;
		auto containsList = filter!(ex => ex.contains(pos))(extents);
		foreach(Extent ex; containsList) {
			if  (pos - ex.min < ex.length) {
				ex.shortenMin(pos + 1);
				ret = true;
			}
			if (ex.max - pos < ex.length) {
				ex.shortenMax(pos - 1);
				ret = true;
			}
		}
		return ret;
	}
	private bool setFill(pos pos) {
		bool ret = false;
		auto neighbor1List = filter!(ex => ex.min - 1 == pos)(extents);
		foreach (Extent ex; neighbor1List) {
			ex.shortenMin(ex.min + 1);
			ret = true;
		}
		auto neighbor2List = filter!(ex => ex.max + 1 == pos)(extents);
		foreach (Extent ex; neighbor2List) {
			ex.shortenMax(ex.max - 1);
			ret = true;
		}
		ret |= _setFill_checkContains(pos);
		return ret;
	}
	private bool _setFill_checkContains(pos pos) {
		bool ret = false;
		auto containsList = filter!(ex => ex.contains(pos))(extents).array();
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
				eachFillCell(newMax + 1, oldValue, &_setFill_checkContains);
				ret = true;
			}
			if (cLast.min < newMin) {
				auto oldValue = cLast.min;
				cLast.min = newMin;
				eachFillCell(oldValue, newMin - 1, &_setFill_checkContains);
				ret = true;
			}

			emptyIfAllExtentLength_lessThanNow(containsList, pos);
		} else {
			throw new ExclusiveException("No Extent at");
		}
		return ret;
	}
	private void emptyIfAllExtentLength_lessThanNow(Extent[] containsList, pos pos) {
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
		foreach (Extent ex; extents) {
			if (! ex.isFixed()) {
				return false;
			}
		}
		return true;
	}

	/* for force resolve */
	LinePossibility deepCopy(SetCell callback, GetCell getCell) {
		Extent prev = null;
		Extent newExtent(Extent origin) {
			prev = origin.deepCopy(getCell, prev);
			return prev;
		}
		Extent[] cp = map!(newExtent)(this.extents).array();
		bool[pos] ed;
		foreach (key, val; this.eventDone) {
			ed[key] = val;
		}
		return new LinePossibility(size, hints, cp, ed, callback, getCell);
	}

	pos getScore() {
		return reduce!((a, b) => a+b)
			(pos.init, map!(ex => ex.getScore())(extents));
	}

	public override string toString() {
		string str = "";
		foreach (Extent ex; extents) {
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
		auto lp = new LinePossibility(30, [7,5], &setCell, &getCell);
		foreach (pos p; order) {
			lp.setFill(p);
			lp.checkUp();
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
		auto lp = new LinePossibility(2, [1], &setCell, &getCell);
		lp.set(F, 0);
		lp.checkUp();
		writeln(cells);
		assert([F,E] == cells, "Why must set explicit ??");
	}
	test();
}
unittest {
	auto F = Cell.Fill;
	auto E = Cell.Empty;
	auto U = Cell.Unknown;
	auto cells = [E,F,F,E,F,F,E,U,E,U,U,U,F,U,U,U,F,U,U,U,U,U,U,U,U,U,U,U,U,U];
	Cell getCell(pos pos) {
		if (0 <= pos && pos < cells.length) { return cells[pos]; }
		return E;
	}
	void setCell(Cell c, pos pos) {
		if (0 <= pos && pos < cells.length)
			cells[pos] = c;
	}
	auto lp = new LinePossibility(30,[2,2,3,9,5,3], &setCell, &getCell);
	//lp.checkUp();
}
unittest {
	auto F = Cell.Fill;
	auto E = Cell.Empty;
	auto U = Cell.Unknown;
	auto cells = [F,F,E,F,E,E,U,U,U,U,F,U,F,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U,U];
	writeln(cells.length);
	Cell getCell(pos pos) {
		if (0 <= pos && pos < cells.length) { return cells[pos]; }
		return E;
	}
	void setCell(Cell c, pos pos) {
		if (0 <= pos && pos < cells.length)
			cells[pos] = c;
	}
	auto lp = new LinePossibility(30,[2,1,1,1,2,2,1,2,4], &setCell, &getCell);
	lp.set(F, 12);
	lp.set(F, 10);
	lp.set(F, 1);
	lp.set(F, 3);
	lp.set(E, 2);
	lp.set(E, 4);
	lp.set(F, 0);
	lp.checkUp();
	writeln("-----_____-----");
	writeln(cells);
	foreach (Extent ext; lp.extents) {
		writeln(ext);
	}

	lp.set(E, 5);
	lp.checkUp();
	writeln(cells);
	foreach (Extent ext; lp.extents) {
		writeln(ext);
	}
	writeln("-----_____-----");
}
