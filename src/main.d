private import std.stdio;
private import std.string;
private import Quest;
private import parts.Resolver;

import std.algorithm;

void main(string[] args) {
	int[][] vHints = [[1],[1],[6],[7],[1,8],[9],[3,5],[4,9],[3,9],[9,2],[1,4,2],[7],[6],[1],[1]];
	int[][] hHints = [[1],[3],[5],[7],[1,1],[1,1],[5],[7],[9],[11],[13],[1,3,2,2,1],[3,2,2],[3,6],[3,6]];
	//int[][] vHints = [[2,4,1],[1,1,1],[1,1,1],[1,3,1],[5],[3,1],[5],[2,1],[1,2],[2]];
	//int[][] hHints = [[2,3],[1,6],[4],[2,1,2],[1,8],[1,1],[3],[1],[2],[1,1]];
	auto q = new Quest(
		vHints,
		hHints);

	auto r = new Resolver(q);
	//writeln(r);
	r.checkUp();
	writeln(r);
	r.showDetail();
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