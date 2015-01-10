module parts.LinePossibility;

private import std.algorithm;
private import std.range;
private import std.stdio;
private import std.string;
private import parts.Resolver;
private import parts.Extent;
private import Quest;

class LinePossibility {
	Resolver parent;
	int[] hints;
	bool[int] eventDone;
	Extent[] extents;
	int size;
	void delegate(Cell, int) callback;
	Cell delegate(int) getCell;

	this(Resolver parent, int size, int[] hints, void delegate(Cell, int) f, Cell delegate(int) getF) {
		void mixedF(Cell c, int p) {
			set(c, p);
			f(c,p);
		}
		this.parent = parent;
		this.size = size;
		this.hints = hints;
		this.callback = &mixedF;
		this.getCell = getF;
		this.extents.length = hints.length;

		int temp = 0;
		for (int i = 0; i < hints.length; i ++) {
			extents[i] = new Extent(this, hints[i]);
			extents[i].min = temp;
			temp += hints[i] + 1;
		}
		temp = size - 1;
		for (int i = hints.length - 1; i >= 0; i --) {
			extents[i].max = temp;
			temp -= hints[i] + 1;
		}
	}

	void checkUp() {
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

	void set(Cell cell, int pos) {
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
			throw new Exception("??");
		}
		if (hasChange) {
			checkUp();
		}
	}
	private bool setEmpty(int pos) {
		bool ret = false;
		auto containsList = filter!(ex => ex.contains(pos))(extents);
		foreach(Extent ex; containsList) {
			if  (pos - ex.min < ex.length) {
				ex.min = pos + 1;
				while (getCell(ex.min) == Cell.Empty)
					ex.min++;
				ret = true;
			}
			if (ex.max - pos < ex.length) {
				ex.max = pos - 1;
				while (getCell(ex.max) == Cell.Empty)
					ex.max--;
				ret = true;
			}
		}
		return ret;
	}
	private bool setFill(int pos) {
		bool ret = false;
		auto neighbor1List = filter!(ex => ex.min - 1 == pos)(extents);
		foreach (Extent ex; neighbor1List) {
			ex.min ++;
			while (getCell(ex.min-1) == Cell.Fill) {
				ex.min ++;
			}
			ret = true;
		}
		auto neighbor2List = filter!(ex => ex.max + 1 == pos)(extents);
		foreach (Extent ex; neighbor2List) {
			ex.max --;
			while (getCell(ex.min+1) == Cell.Fill) {
				ex.min --;
			}
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
			set(Cell.Empty, min - 1);
			set(Cell.Empty, max + 1);
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

	public override string toString() {
		string str = "";
		foreach (Extent ex; extents) {
			str ~= ex.toString();
			str ~= " ";
		}
		return str;
	}
}
