module extent_resolver.ExtentResolver;

private import std.stdio;
private import std.string;
private import Quest;
private import extent_resolver.LinePossibility;
private import parts.ExclusiveException;
private import parts.Position;
private import parts.Resolver;

class ExtentResolver : Resolver {
	private Quest quest;
	private LinePossibility[] vPossibility;
	private LinePossibility[] hPossibility;

	this(Quest quest) {
		this.quest = quest;

		vPossibility.length = quest.width;
		hPossibility.length = quest.height;
		for (int x = 0; x < quest.width; x ++) {
			vPossibility[x] = new LinePossibility(
				quest.height
				, quest.vHints[x]
				, this.verticalCallback(x)
				, this.getCellAtX(x));
		}
		for (int y = 0; y < quest.height; y ++) {
			hPossibility[y] = new LinePossibility(
				quest.width
				, quest.hHints[y]
				, this.horizontalCallback(y)
				, this.getCellAtY(y));
		}
	}
	public void checkUp() {
		foreach(LinePossibility lp; vPossibility) {
			lp.checkUp();
		}
		foreach(LinePossibility lp; hPossibility) {
			lp.checkUp();
		}
	}
	public void set(int x, int y, Cell c) {
		hPossibility[y].set(c, x);
		hPossibility[y].checkUp();
		vPossibility[x].set(c, y);
		vPossibility[x].checkUp();
	}

	private auto verticalCallback(int x) {
		void _inner(Cell c, int y) {
			if (0 <= x && x < quest.width
				&& 0 <= y && y < quest.height) {
				if (quest[y, x] != c) {
					quest[y, x] = c;
					hPossibility[y].set(c, x);
					hPossibility[y].checkUp();
				}
			}
		}
		return &_inner;
	}
	private auto horizontalCallback(int y) {
		void _inner(Cell c, int x) {
			if (0 <= x && x < quest.width
				&& 0 <= y && y < quest.height) {
				if (quest[y, x] != c) {
					quest[y, x] = c;
					vPossibility[x].set(c, y);
					vPossibility[x].checkUp();
				}
			}
		}
		return &_inner;
	}

	private auto getCellAtX(int x) {
		Cell _inner(int y) {
			if (0 <= y && y < quest.height
				&& 0 <= x && x < quest.width) {
				return quest[y, x];
			} else {
				return Cell.Unknown;
			}
		}
		return &_inner;
	}
	private auto getCellAtY(int y) {
		Cell _inner(int x) {
			if (0 <= y && y < quest.height
				&& 0 <= x && x < quest.width) {
				return quest[y, x];
			} else {
				return Cell.Unknown;
			}
		}
		return &_inner;
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
