module extent.ExtentResolver;

private import std.algorithm;
private import std.range;
private import std.stdio;
private import std.string;

private import Quest;
private import extent.LinePossibility;
private import parts.Resolver;
private import common;

class ExtentResolver {
	public Quest quest;
	private LinePossibility[] vPossibility;
	private LinePossibility[] hPossibility;

	this(Quest quest) {
		LinePossibility[] vp;
		vp.length = quest.width;
		LinePossibility[] hp;
		hp.length = quest.height;
		for (pos x = 0; x < quest.width; x ++) {
			vp[x] = new LinePossibility(
				quest.height
				, quest.vHints[x]
				, this.verticalCallback(x)
				, this.getCellAtX(x)
, format("x=%d", x));
		}
		for (pos y = 0; y < quest.height; y ++) {
			hp[y] = new LinePossibility(
				quest.width
				, quest.hHints[y]
				, this.horizontalCallback(y)
				, this.getCellAtY(y)
, format("y=%d", y));
		}
		this.quest = quest;
		this.vPossibility = vp;
		this.hPossibility = hp;
	}
	private this(Quest quest, LinePossibility[] originVPossibility, LinePossibility[] originHPossibility) {
		this.quest = quest.copy();
		pos x = 0;
		pos y = 0;
		this.vPossibility = map!(
			item => item.deepCopy(
				this.verticalCallback(x),
				this.getCellAtX(x++)
			))(originVPossibility).array();
		this.hPossibility = map!(
			item => item.deepCopy(
				this.horizontalCallback(y),
				this.getCellAtY(y++)
			))(originHPossibility).array();
	}
	public void checkUp() {
		foreach(LinePossibility lp; vPossibility) {
			lp.checkUp();
		}
		foreach(LinePossibility lp; hPossibility) {
			lp.checkUp();
		}
	}
	public void set(pos x, pos y, Cell c) {
		writeln(x, y, c);
		if (quest[y, x] == Cell.Unknown) {
			quest[y, x] = c;
			hPossibility[y].set(c, x);
			vPossibility[x].set(c, y);
			hPossibility[y].checkUp();
			vPossibility[x].checkUp();
		} else {
			throw new ExclusiveException(x, y,
				format("%s -> %s", quest[y, x], c));
		}
	}

	private auto verticalCallback(pos x) {
		void _inner(Cell c, pos y) {
			if (0 <= x && x < quest.width
				&& 0 <= y && y < quest.height) {
				LinePossibility lp = hPossibility[y];
				if (! lp.isChecked(x)) {
					quest[y, x] = c;
					lp.set(c, x);
					lp.checkUp();
				}
			}
		}
		return &_inner;
	}
	private auto horizontalCallback(pos y) {
		void _inner(Cell c, pos x) {
			if (0 <= x && x < quest.width
				&& 0 <= y && y < quest.height) {
				LinePossibility lp = vPossibility[x];
				if (! lp.isChecked(y)) {
					quest[y, x] = c;
					lp.set(c, y);
					lp.checkUp();
				}
			}
		}
		return &_inner;
	}

	private auto getCellAtX(pos x) {
		Cell _inner(pos y) {
			if (0 <= y && y < quest.height
				&& 0 <= x && x < quest.width) {
				return quest[y, x];
			} else {
				return Cell.Unknown;
			}
		}
		return &_inner;
	}
	private auto getCellAtY(pos y) {
		Cell _inner(pos x) {
			if (0 <= y && y < quest.height
				&& 0 <= x && x < quest.width) {
				return quest[y, x];
			} else {
				return Cell.Unknown;
			}
		}
		return &_inner;
	}
	public bool done() {
		checkUp();
		foreach (LinePossibility lp; vPossibility) {
			if (!lp.done()) {
				return false;
			}
		}
		foreach (LinePossibility lp; hPossibility) {
			if (!lp.done()) {
				writeln(lp);
				throw new Exception(format("??\n%s", quest));
			}
		}
		return true;
	}

	/* for force resolve */
	ExtentResolver deepCopy() {
		return new ExtentResolver(this.quest
			, this.vPossibility
			, this.hPossibility);
	}
	Position getEasyPoint() {
		// TODO
		for (pos y = 0; y < quest.height; y ++) {
			for (pos x = 0; x < quest.width; x ++) {
				if (quest[y, x] == Cell.Unknown) {
					return new Position(x,y);
				}
			}
		}
		foreach (LinePossibility lp; vPossibility) {
			if (!lp.done()) {
				writeln(lp);
			}
		}
		foreach (LinePossibility lp; hPossibility) {
			if (!lp.done()) {
				writeln(lp);
			}
		}
//		writeln(quest);
		throw new Exception(format("done"));
	}

	override string toString() {
		string str = "||";
		foreach (LinePossibility lb; vPossibility) {
			str ~= lb.toString();
		}
		str ~= "=";
		foreach (LinePossibility lb; hPossibility) {
			str ~= lb.toString();
		}
		return str;
	}
}
