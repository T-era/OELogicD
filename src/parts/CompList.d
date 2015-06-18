module parts.CompList;

import std.stdio;
import std.string;
import std.algorithm;
import std.range;
import std.traits;

Type[] deepCopy(Type)(Type[] arg) {
	Type[] ret;
	ret.length = arg.length;
	static if (isArray!(Type)) {
		return map!(deepCopy!(ElementType!(Type)))(arg).array();
	} else {
		ret[] = arg[];
		return ret;
	}
}
unittest {
	singleList: {
		int[] list = [3,1,4,2,5];
		int[] cp = deepCopy!(int)(list);
		assert(list == cp);
		assert(list !is cp);
	}
	doubleList: {
		int[][] list = [[1,11,111], [2,22,222], [3,33,333]];
		int[][] cp = deepCopy!(int[])(list);
		assert(list == cp);
		assert(list !is cp);
		foreach (index, inner; list) {
			assert(inner == cp[index]);
			assert(inner !is cp[index]);
		}
	}
}

void copyInto(Type)(Type[] org, Type[] dest) {
	foreach (i, item; org) {
		static if (isArray!(Type)) {
			copyInto!(ElementType!(Type))(item, dest[i]);
		} else {
			dest[i] = item;
		}
	}
}
unittest {
	singleList: {
		int[] list = [3,1,4,2,5];
		int[] cp = new int[](5);
		copyInto!(int)(list, cp);
		assert(list == cp);
		assert(list !is cp);
	}
	doubleList: {
		int[][] list = [[1,11,111], [2,22,222], [3,33,333]];
		int[][] cp = new int[][](3,3);
		copyInto!(int[])(list, cp);
		assert(list == cp);
		assert(list !is cp);
		foreach (index, inner; list) {
			assert(inner == cp[index]);
			assert(inner !is cp[index]);
		}
	}
	error: {
		int[] list = [1,2,3];
		int[] cp = new int[2]; // less than origin.
		try {
			copyInto!(int)(list, cp);
			assert(false);
		} catch {
			// This is ERROR case test.
			assert(true);
		}
	}
}

TRet fetchDoubleList(TItem, TRet)(
			TItem[][] list,
			TRet delegate(TItem) map,
			TRet delegate(TRet, TRet) reduceLine,
			TRet delegate(TRet, TRet) reduce) {
	TRet ret;
	foreach (y, row; list) {
		TRet line;
		foreach (x, item; row) {
			TRet val = map(item);
			line = (x == 0 ? val : reduceLine(val, line));
		}
		ret = (y == 0 ? line : reduce(line, ret));
	}
	return ret;
}
unittest {
	int[][] list = [[1,4,7],[2,5,8],[3,6,9]];
	strJoin: {
		string ret = fetchDoubleList!(int, string)(
			list,
			(i) => format("%d", i),
			(a, b) => b ~ a,
			(a, b) => b ~ "\n" ~ a);
		assert(ret == "147\n258\n369");
	}
	complex: {
		int ret = fetchDoubleList!(int, int)(
			list,
			(i) => i,
			(a, b) => b * a,
			(a, b) => b + a);
		assert(ret == (1*4*7)+(2*5*8)+(3*6*9));
	}
}
