module extent_resolver.Shortage;
private import Quest;
import std.stdio;
class Shortage {
	private bool[int] fills;
	private bool hasChange;
	bool HasChange() { return hasChange; }

	void addRange(int min, int max, Cell delegate(int) getCell) {
		hasChange = true;
		if (min > max) assert(false);
		foreach (pos; min..max+1) {
			Cell c = getCell(pos);
			if (c == Cell.Fill
				&& pos !in fills) {
				fills[pos] = true;
			}
		}
	}
	void forEachFill(void delegate(int) f) {
		foreach (pos, val; fills) {
			f(pos);
		}
	}
}
unittest {
	auto r1 = new Shortage;
	Cell getC(int x) { return Cell.Fill; }
	assert(!r1.HasChange);
	r1.addRange(1, 2, &getC);
	assert(r1.HasChange);
	int[] stock = [];
	r1.forEachFill(delegate(p) { stock ~= p; });
	assert(stock == [1,2] || stock == [2,1]);
}
