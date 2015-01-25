private import std.stdio;
private import std.string;
private import Quest;
private import extent_resolver.Resolver;

import std.algorithm;
import CommandLineParser;
import std.conv;
private import std.regex;
private import std.range;

void main(string[] args) {
	int toInt(string str) {
		return to!int(str);
	}
	auto parser = new CommandLineParser();
	auto optStdIn = parser.addStaticOption("--StdIn", "Input from standard input.");
	auto optTest = parser.addValiableOption!(int)("--Test", "On source code.", &toInt);

	string[] remain = parser.parseOptions(args);
	Quest q;
	if (optStdIn.getValue()) {
		string[] vInput = readln()[22..$-3].split(", ");
		string[] hInput = readln()[22..$-3].split(", ");
		string[] vHints = map!(str => str[1..$-1])(vInput).array();
		string[] hHints = map!(str => str[1..$-1])(hInput).array();
		q = new Quest(
			vHints,
			hHints,
			" ");
	} else {
		switch (optTest.getValue()) {
			case 0:
				q = new Quest(
					["4 2 4 3", "3 3 5 6", "2 5 3 3 7", "2 2 2 12 2", "3 2 6 5", "2 1 2 6 5", "1 2 4 2 2 3", "2 4 3 2 2 2", "2 4 2 2 1 3 1", "2 3 2 1 4 1 1", "1 1 3 2 2 1 1", "2 3 2 1", "2 3 2 2 2 1", "1 4 1 2 1 1 1", "1 3 1 4 1 1 1 1", "2 3 2 2 1 3 1 1 1", "1 2 1 4 1 1 3", "2 1 2 1 2 2", "1 4 1 2 2 1 1", "3 3 1 1 2 1", "3 3 2", "4 5 2", "1 3 6 3", "2 2 10 4", "1 1 4 3 2 4 1", "1 3 3 4 3 3 2", "2 3 1 1 1 2 2 3", "3 1 7 1 2 4 1", "5 1 5 6 1 3", "5 3 8 2 2"],
					["1 2 1 2 2 6 2", "2 1 1 2 2 3 2 3", "2 2 1 1 6 1 3", "1 1 2 1 6 2 1 2", "2 1 1 6 1 1 1 2", "1 1 1 6 2 1 3", "1 3 1 3 3 1 2 1", "1 2 2 3 3 2 1 1", "2 2 2 3 1 2 1", "2 1 3 2 2 1 1", "2 1 3 7 1", "1 2 3 5 2 1 2", "2 5 3 3 3", "2 3 2 1 1 4 2", "2 3 1 1 1 2 7", "2 5 1 6 1 1 2", "2 8 4 2 3 1 1", "1 3 2 1 1 2 1 1", "2 1 1 3 1 2 2", "1 2 2 1 1 1 2", "1 1 3 4 1 3", "2 1 2 1 1 2 3", "3 1 7 2 1 1", "4 2 1 5", "4 3 5 2 1 1", "5 2 2 7", "2 3 3 2 3 2", "1 3 3 2 2", "2 3 5 4 1 2", "1 1 2 3 1 2"], " ");
				break;
			case 1:
				int[][] vHints = [[1],[1],[6],[7],[1,8],[9],[3,5],[4,9],[3,9],[9,2],[1,4,2],[7],[6],[1],[1]];
				int[][] hHints = [[1],[3],[5],[7],[1,1],[1,1],[5],[7],[9],[11],[13],[1,3,2,2,1],[3,2,2],[3,6],[3,6]];
				q = new Quest(
					vHints,
					hHints);
				break;
			case 2:
				int[][] vHints = [[2,4,1],[1,1,1],[1,1,1],[1,3,1],[5],[3,1],[5],[2,1],[1,2],[2]];
				int[][] hHints = [[2,3],[1,6],[4],[2,1,2],[1,8],[1,1],[3],[1],[2],[1,1]];
				q = new Quest(
					vHints,
					hHints);
				break;
			default:
				throw new Exception("no data");
		}
	}

	auto r = new Resolver(q);
	r.checkUp();
	writeln(r);
	readln();
}

enum Cell {
	Unknown,
	Fill,
	Empty
}
