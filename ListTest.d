import std.stdio;

void main() {
	int[] l = [1,2,3,4,5];
	writeln(l[0]);
	writeln(l[$-1]);
	int[] l2 = [2,2,2,3];
	int[] b2;
	b2.length = 4;

	b2[] = l2[] + 2;
	writeln(b2);
}