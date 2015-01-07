private import std.stdio;
private import std.string;
private import Quest;
private import parts.Resolver;
private import parts.LinePossibility;
import std.algorithm;

void main(string[] args) {
	void test(Cell c, int x) {
		writeln(format("%s @ %d", c, x));
	}
	auto obj = new LinePossibility(null, 17, [3,3], &test);
	obj.checkUp();
	obj.set(Cell.Fill, 16);
	writeln("-");
	obj.set(Cell.Empty, 3);
	obj.set(Cell.Fill, 2);
	obj.checkUp();
}

enum Cell {
	Unknown,
	Fill,
	Empty
}
/**
struct MS {
	int sum;
	int max;
}
MS sum_max(int[] args) {
	int sum = 0;
	int max = args[0];
	for (int i = 0; i < args.length; i++) {
		sum += args[i];
		if (max < args[i]) {
			max = args[i];
		}
	}
	MS ret = { sum: sum, max: max };
	return ret;
}
*/