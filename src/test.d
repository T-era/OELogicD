private import std.stdio;
private import std.string;
private import Quest;
private import extent_resolver.LinePossibility;
import std.algorithm;

void main(string[] args) {
	Cell[int] fixed;
	void test(Cell c, int x) {
		if (x in fixed) {
		} else {
			writeln(format("%s @ %d", c, x));
			fixed[x] = c;
		}
	}
	Cell get(int x) {
		if (x in fixed) {
			return fixed[x];
		} else {
			return Cell.Unknown;
		}
	}
	auto obj = new LinePossibility(null, 12, [3,3], &test, &get);
	test(Cell.Fill, 5);
	obj.set(Cell.Fill, 5);
	test(Cell.Fill, 7);
	obj.set(Cell.Fill, 7);
	obj.checkUp();
	writeln(obj);
	obj.set(Cell.Fill, 4);
	obj.checkUp();
	writeln(obj);
}
