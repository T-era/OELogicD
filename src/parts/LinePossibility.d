module parts.LinePossibility;

private import parts.Resolver;
private import parts.Extent;
private import main;

class LinePossibility {
	Resolver parent;
	int[] hints;
	Extent[] extents;
	LinePossibility delegate(int) getCrossLine;

	this(Resolver parent, int size, int[] hints, LinePossibility delegate(int) f) {
		this.parent = parent;
		this.hints = hints;
		this.getCrossLine = f;
		this.extents.length = hints.length;

		int temp = 0;
		for (int i = 0; i < hints.length; i ++) {
			extents[i] = new Extent(this, hints[i]);
			extents[i].min = temp;
			temp += hints[i] + 1;
		}
		temp = size - 1;
		for (int i = hints.length - 1; i >= 0; i --) {
			extents[i].min = temp;
			temp -= hints[i] - 1;
		}
	}

	void checkUp() {
		int prevMax = 0;
		foreach (Extent ex; extents) {
			if (prevMax < ex.min) {
				// Empty 確定
			}
		}
		// TODO
	}
	void set(Cell cell, int pos, void delegate(Cell, int) linkageCallback) {
		if (cell == Cell.Empty) {
			containsList = filter!(ex => ex.contains(pos))
					(extents);
			foreach(Extent ex; containsList) {
				ex.set(
				|| ex.neighbor(pos))(extents);
			foreach(Extent ex; target) {
			}
		}
	}
}
