private import std.stdio;
private import std.string;
private import Quest;
private import extent_resolver.ExtentResolver;
private import std.algorithm;

void main(string[] args) {
	auto q = new Quest(
		["5 3 4 2 2 3", "4 3 4 1 3 3", "3 2 3 3 3 4", "4 4 6 3 2 2", "3 3 2 1 3 3 2", "3 2 3 4 3 6 1", "3 3 2 3 3 2", "2 3 3 3 3 2", "2 2 3 2 3 2", "3 1 4 5 2 1 2", "4 2 3 4 2 2 1", "3 4 4 1 1 1 1 1", "10 2 1 2", "3 2 4 5 1 5", "2 5 2 2 2 9", "2 4 2 5 8 1 2", "1 16 2 2 1 1", "1 1 3 5 3 2 2", "1 4 2 2 1 4 2", "1 8 1 2 2 7", "1 1 2 2 2 1 2 4", "4 2 1 1 1 2", "1 6 2", "3 1 3 2", "5 4 1 1", "1 6 4 1 2", "1 3 5 1 5 1", "1 3 4 2 4", "4 11 1", "1 12 2 3"],
		["20 1 1 1", "16 1 1 3", "7 5 2 2 2 1 1", "2 1 1 1 2 2 1 2 4", "1 1 1 12 4 1", "2 2 3 9 5 3", "1 1 2 3 4 2 1 3 2", "2 2 2 6 1 6 5", "1 1 1 1 5 2 9", "1 1 2 2 3 2 2 8", "2 1 3 1 2 1 3 1 4", "1 1 2 2 3 2 2", "2 1 2 3 3 5", "1 4 2 4 2 3", "1 1 1 2 6 2 2", "2 1 1 3 4 2 3", "1 1 3 2 2 2 1 2", "1 3 3 2 1 2 2 3 1", "1 2 2 3 4 2 1", "1 2 5 3", "2 5 1 1 1 1", "1 2 2 6 2", "3 2 1 4 1", "2 1 6 5", "3 2 1 3 3", "1 3 2 2 4", "5 6 4", "3 3 2 1 2", "5 3 4 9", "6 16 2"],
		//["5", "5", "4 5 5", "7 1 4 5", "10 5 2 4", "7 7 3 4", "8 4 3 5", "7 2 3 5 4", "8 2 2 7 3", "4 1 2 1 4 4 2", "3 2 3 1 1 1 5 2", "2 4 1 1 4 3 2 1", "2 2 1 1 1 2 1 1", "2 3 1 1 2 1 1", "2 2 1 1 1 4 3 2 1", "2 4 3 2 1 6 2", "3 2 2 1 3 7 3", "4 1 2 1 1 3 4 3", "7 2 5 4 1", "8 2 3 2", "8 2 2 4 4", "9 2 4 5", "10 6 6", "10 3 4", "11 1 4 2 3", "12 2 1 1 3", "12 2 4", "9 7 5", "6 5", "5"],
		//["15", "18", "6 9", "6 2 2 9", "5 5 9", "6 2 1 2 10", "25", "7 10", "5 9 8", "3 4 5 7", "3 3 2 2 3 6", "4 2 5", "3 3 3 2 5", "2 1 1 2 1 2 3", "3 1 3 1 3 6", "1 2 1 1 1 1 1 1 4 2", "1 2 1 6 3 3 1 1", "1 2 2 1 2 2 2 1", "1 1 1 2 1 1 1", "2 1 2 1 2 2 1", "1 4 5 1 1", "1 5 6 2", "2 13 3", "1 12 2", "1 3 3 2", "7 1 1 9", "8 2 2 1 11", "10 4 7 6", "5 5 3 3 4", "4 3 7 3 3"],
		" ");

	int[][] vHints = [[1],[1],[6],[7],[1,8],[9],[3,5],[4,9],[3,9],[9,2],[1,4,2],[7],[6],[1],[1]];
	int[][] hHints = [[1],[3],[5],[7],[1,1],[1,1],[5],[7],[9],[11],[13],[1,3,2,2,1],[3,2,2],[3,6],[3,6]];
	//int[][] vHints = [[2,4,1],[1,1,1],[1,1,1],[1,3,1],[5],[3,1],[5],[2,1],[1,2],[2]];
	//int[][] hHints = [[2,3],[1,6],[4],[2,1,2],[1,8],[1,1],[3],[1],[2],[1,1]];
	auto q2 = new Quest(
		vHints,
		hHints);

	auto r = new ExtentResolver(q);
	r.checkUp();
	writeln(q);
	//writeln(r);
}

enum Cell {
	Unknown,
	Fill,
	Empty
}
