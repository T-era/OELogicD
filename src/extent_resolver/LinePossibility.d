module extent_resolver.LinePossibility;

private import std.algorithm;
private import std.range;
private import std.stdio;
private import std.string;
private import extent_resolver.Extent;
private import parts.Resolver;
private import parts.ExclusiveException;
private import Quest;

class LinePossibility {
	private int[] hints;
	private bool[int] eventDone;
	private Extent[] extents;
	private int size;
	private void delegate(Cell, int) callback;
	private Cell delegate(int) getCell;

	this(int size, int[] hints, void delegate(Cell, int) f, Cell delegate(int) getF) {
		void mixedF(Cell c, int p) {
			set(c, p);
			f(c,p);
		}
		Extent[] exts;
		exts.length = hints.length;
		int temp = 0;
		for (int i = 0; i < hints.length; i ++) {
			exts[i] = new Extent(getF, hints[i], i == 0 ? null : exts[i-1]);
			exts[i].min = temp;
			temp += hints[i] + 1;
		}
		temp = size - 1;
		for (int i = hints.length - 1; i >= 0; i --) {
			exts[i].max = temp;
			temp -= hints[i] + 1;
		}
		bool[int] ed;
		this(size, hints, exts, ed, &mixedF, getF);
	}

	/*
	 Constructor for copy.
	 */
	private this(int size, int[] hints, Extent[] extents, bool[int] eventDone, void delegate(Cell, int) callback, Cell delegate(int) getCell) {
		this.size = size;
		this.hints = hints;
		this.callback = callback;
		this.getCell = getCell;

		this.extents = extents;
		this.eventDone = eventDone;
	}

	bool isChecked(int pos) {
		if (pos in eventDone) {
			return true;
		} else {
			return false;
		}
	}
	public void checkUp() {
		checkUpFunc(this.extents, this.size, this.callback);
	}
	private static void checkUpFunc(Extent[] extents, int size, void delegate(Cell, int) callback) {
		if (extents.length == 0) {
			for (int i = 0; i < size; i ++) {
				callback(Cell.Empty, i);
			}
		} else {
			int prevMax = -1;
			foreach (Extent ex; extents) {
				if (ex.isFixed()) {
					if (ex.min-1 >= 0)
						callback(Cell.Empty, ex.min-1);
					if (ex.max+1 < size)
						callback(Cell.Empty, ex.max+1);
				}
				for (int i = prevMax + 1; i < ex.min; i ++) {
					callback(Cell.Empty, i);
				}
				ex.fillCenter(x => callback(Cell.Fill, x));
				prevMax = ex.max;
			}
			for (int i = prevMax + 1; i < size; i ++) {
				callback(Cell.Empty, i);
			}
		}
	}
	unittest {
		Extent[] testExtentList(Cell delegate(int) getCell, int[][] fromToList) {
			Extent prev = null;
			Extent[] list = [];
			foreach (int[] fromTo; fromToList) {
				Extent obj = new Extent(getCell, fromTo[0], prev);
				obj.min = fromTo[1];
				obj.max = fromTo[2];
				prev = obj;
				list ~= obj;
			}
			return list;
		}
		auto callbackForTest(ref Cell[int] stock) {
			return (Cell c, int pos) {
				stock[pos] = c;
			};
		}
		{
			Cell[int] stock;
			checkUpFunc(testExtentList(null, [[1,0,3]]), 4, callbackForTest(stock));
			assert(stock.length == 0);
			checkUpFunc(testExtentList(null, [[1,1,2]]), 4, callbackForTest(stock));
			assert(stock == [0:Cell.Empty, 3:Cell.Empty]);
		}
		{
			Cell[int] stock;
			checkUpFunc(testExtentList(null, [[2,1,3]]), 5, callbackForTest(stock));
			assert(stock == [2:Cell.Fill, 0:Cell.Empty, 4:Cell.Empty]);
		}
		{
			Cell[int] stock;
			checkUpFunc(testExtentList(null, [[2,1,3], [2,5,8]]), 9, callbackForTest(stock));
			assert(stock == [2:Cell.Fill, 0:Cell.Empty, 4:Cell.Empty]);
		}
	}

	/**
	 セルを設定します。その結果として、各Extentは縮小する可能性があります。
	 各Extentが縮小した場合、checkUpをおこないます。
	 設定のキャンセルはできません。(Unknown指定はエラー仕様外)
	 Questに対して矛盾が検知されると、ExclusiveException例外が送出します。
	**/
	void set(Cell cell, int pos) {
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
		Cell[] cells = [Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Empty, Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Fill, Cell.Unknown, Cell.Unknown, Cell.Unknown];
		Cell getCell(int pos) {
			return cells[pos];
		}
		LinePossibility initTest(void delegate(Cell, int) callback, Extent[] extents) {
			bool[int] eventDone;
			return new LinePossibility(
				cells.length,
				[2,4],
				extents,
				eventDone,
				callback,
				&getCell);
		}
		Extent[] testExtentList(Cell delegate(int) getCell, int[][] fromToList) {
			Extent prev = null;
			Extent[] list = [];
			foreach (int[] fromTo; fromToList) {
				Extent obj = new Extent(getCell, fromTo[0], prev);
				obj.min = fromTo[1];
				obj.max = fromTo[2];
				prev = obj;
				list ~= obj;
			}
			return list;
		}

		Cell[int] called;
		void myCallBack(Cell c, int pos) {
			called[pos] = c;
		}
		Extent[] extents = testExtentList(&getCell, [[2,0,8],[4,7,13]]);
		auto lp = initTest(&myCallBack, extents);
		lp.set(Cell.Fill, 9);
		assert(called == [9: Cell.Fill, 13: Cell.Empty]
			|| called == [9: Cell.Fill, 10: Cell.Fill, 13: Cell.Empty] // Fill@10 はコールバックされてもされなくてもOK(決定済み)
			|| called == [6: Cell.Empty, 9: Cell.Fill, 13: Cell.Empty] // Empty@6 はコールバックされてもされなくてもOK(決定済み)
			|| called == [6: Cell.Empty, 9: Cell.Fill, 10: Cell.Fill, 13: Cell.Empty]);
		assert(extents[0].min == 0);
		assert(extents[0].max == 5);
		assert(extents[1].min == 7);
		assert(extents[1].max == 12);
	}
	private bool setEmpty(int pos) {
		bool ret = false;
		auto containsList = filter!(ex => ex.contains(pos))(extents);
		foreach(Extent ex; containsList) {
			if  (pos - ex.min < ex.length) {
				ex.shortenMin(pos + 1);
				ret = true;
			}
			if (ex.max - pos < ex.length) {
				writeln(ex.max - pos < ex.length);
				ex.shortenMax(pos - 1);
				ret = true;
			}
		}
		return ret;
	}
	private bool setFill(int pos) {
		bool ret = false;
		auto neighbor1List = filter!(ex => ex.min - 1 == pos)(extents);
		foreach (Extent ex; neighbor1List) {
//			ex.min ++;
			ex.shortenMin(ex.min + 1);
//			while (getCell(ex.min-1) == Cell.Fill) {
//				ex.min ++;
//			}
			ret = true;
		}
		auto neighbor2List = filter!(ex => ex.max + 1 == pos)(extents);
		foreach (Extent ex; neighbor2List) {
//			ex.max --;
			ex.shortenMax(ex.max - 1);
//			while (getCell(ex.min+1) == Cell.Fill) {
//				ex.min --;
//			}
			ret = true;
		}
		ret |= _setFill_checkContains(pos);
		return ret;
	}
	private bool _setFill_checkContains(int pos) {
		bool ret = false;
		auto containsList = filter!(ex => ex.contains(pos))(extents).array();
		if (containsList.length != 0) {
			// first and last one shorten.
			auto cFirst = containsList[0];
			auto cLast = containsList[$-1];

			int newMax = pos + cFirst.length - 1;
			int newMin = pos - cLast.length + 1;
			for (int i = pos+1; i <= newMax; i ++) {
				if (getCell(i) == Cell.Empty) {
					newMax = i - 1;
					break;
				}
			}
			for (int i = pos-1; i >= newMin; i --) {
				if (getCell(i) == Cell.Empty) {
					newMin = i + 1;
					break;
				}
			}
			if (cFirst.max > newMax) {
				int oldValue = cFirst.max;
				cFirst.max = newMax;
				eachFillCell(newMax + 1, oldValue, &_setFill_checkContains);
				ret = true;
			}
			if (cLast.min < newMin) {
				int oldValue = cLast.min;
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
	private void emptyIfAllExtentLength_lessThanNow(Extent[] containsList, int pos) {
		int min = pos;
		int max = pos;
		while (getCell(min-1) ==  Cell.Fill)
			min --;
		while (getCell(max+1) ==  Cell.Fill)
			max ++;
		int length = max - min + 1;
		if (filter!(ex => ex.length > length)(containsList).array().length == 0) {
			callback(Cell.Empty, min - 1);
			callback(Cell.Empty, max + 1);
		}
	}
	private bool eachFillCell(int min, int max, bool delegate(int) action) {
		bool hasChange = false;
		for (int i = min; i <= max; i ++) {
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
	LinePossibility deepCopy(void delegate(Cell, int) callback, Cell delegate(int) getCell) {
		Extent prev = null;
		Extent newExtent(Extent origin) {
			prev = origin.deepCopy(getCell, prev);
			return prev;
		}
		Extent[] cp = map!(newExtent)(this.extents).array();
		bool[int] ed;
		foreach (key, val; this.eventDone) {
			ed[key] = val;
		}
		return new LinePossibility(size, hints, cp, ed, callback, getCell);
	}
	int getScore() {
		return reduce!((a, b) => a+b)
			(0, map!(ex => ex.getScore())(extents));
	}

	public override string toString() {
		string str = "";
		foreach (Extent ex; extents) {
			str ~= ex.toString();
			str ~= " ";
		}
		return str;
	}
}
