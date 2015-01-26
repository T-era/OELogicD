module parts.DeepCopy;

import std.stdio;
import std.string;
import std.algorithm;
import std.range;
import std.traits;

template deepCopy(Type) {
	Type[] deepCopy(Type[] arg) {
		Type[] ret;
		ret.length = arg.length;
		static if (isArray!(Type)) {
			return map!(deepCopy!(ElementType!(Type)))(arg).array();
		} else {
			ret[] = arg[];
			return ret;
		}
	}
}
