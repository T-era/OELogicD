private import std.stdio;
private import std.string;
private import Quest;
private import parts.Resolver;

import std.algorithm;

void main(string[] args) {
	int[][] vHints = [[4],[1]];
	int[][] hHints = [[1],[1],[1],[1],[1]];
	auto q = new Quest(
		vHints,
		hHints);

	auto r = new Resolver(q);
	writeln(r);
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