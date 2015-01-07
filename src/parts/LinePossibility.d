module parts.LinePossibility;

private import std.algorithm;
private import std.range;
private import std.stdio;
private import std.string;
private import parts.Resolver;
private import parts.Extent;
private import main;

class LinePossibility {
	Resolver parent;
	int[] hints;
	Extent[] extents;
	int size;
	void delegate(Cell, int) callback;

	this(Resolver parent, int size, int[] hints, void delegate(Cell, int) f) {
		this.parent = parent;
		this.size = size;
		this.hints = hints;
		this.callback = f;
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
					writeln("f" ~ ex.toString());
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
				ret = true;
			}
			if (ex.max - pos < ex.length) {
				ex.max = pos - 1;
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
			ret = true;
		}
		auto neighbor2List = filter!(ex => ex.max + 1 == pos)(extents);
		foreach (Extent ex; neighbor2List) {
			ex.max --;
			ret = true;
		}
		auto containsList = filter!(ex => ex.contains(pos))(extents).array();
		if (containsList.length == 1) {
			auto cEx = containsList[0];
			write("hoge");
			writeln(cEx);
			int newMin = pos - cEx.length + 1;
			int newMax = pos + cEx.length - 1;
			if (cEx.min < newMin) {
				cEx.min = newMin;
				ret = true;
			}
			if (cEx.max > newMax) {
				cEx.max = newMax;
				ret = true;
			}
		}
		return ret;
	}
}
