module extent.ExtentFragment;

import std.exception;
private import std.string;
private import std.algorithm;
private import std.stdio;
private import common;

class ExtentFragment {
	ExtentFragment _prev;
	ExtentFragment _next;
	pos _min;
	pos _max;
	pos length() {
		return _max - _min + 1;
	}

	this(pos min, pos max) {
		_min = min;
		_max = max;
		_prev = null;
		_next = null;
	}

	ExtentFragment deepCopy() {
		auto ret = new ExtentFragment(_min, _max);
		if (_next !is null) {
			ret._next = _next.deepCopy();
			ret._next._prev = ret;
		}
		return ret;
	}

	// min値を変更します。
	// 変更後のリンクリストの先頭を返します。
	ExtentFragment minChange(pos newMin, pos extentLength) {
		auto head = this;
		while (head._max - newMin < extentLength - 1) {
			head = head._next;
			head._prev = null;
		}
		if (head._min < newMin) {
			head._min = newMin;
		}
		return head;
	}

	// max値を変更します。
	// 変更後のリンクリストの末尾を返します。
	ExtentFragment maxChange(pos newMax, pos extentLength) {
		auto tail = this;
		while (newMax - tail._min + 1 < extentLength) {
			tail = tail._prev;
			tail._next = null;
		}
		if (tail._max > newMax) {
			tail._max = newMax;
		}
		return tail;
	}

	ExtentFragment chop(pos p, pos extentLength) {
		auto prev = this._prev;
		auto next = this._next;
		bool fHalfAlive = p - this._min >= extentLength;
		bool sHalfAlive = this._max - p >= extentLength;

		if (fHalfAlive && sHalfAlive) {
			auto newOne = new ExtentFragment(p + 1, this._max);
			this._next = newOne;
			newOne._prev = this;
			newOne._next = next;
			if (next !is null) {
				next._prev = newOne;
			}
			this.maxChange(p - 1, extentLength);
			return this;
		} else if (fHalfAlive) {
			this.maxChange(p - 1, extentLength);
			return this;
		} else if (sHalfAlive) {
			this.minChange(p + 1, extentLength);
			return this;
		} else {
			ExtentFragment ret = null;
			if (next !is null) {
				next._prev = prev;
				ret = next;
			}
			if (prev !is null) {
				prev._next = next;
				ret = prev;
			}
			return ret;
		}
	}
	// 不変条件表明
	invariant() {
		assert(_min <= _max, format("Illegal min-max %d-%d", _min, _max));
	}

	unittest {
		void testMinMax() {
			ExtentFragment exf;
			exf = new ExtentFragment(0, 10);
			auto next = new ExtentFragment(0, 12);
			exf._next = next;
			assert(exf.minChange(7, 4) !is null); // ギリギリ有効
			assert(exf.minChange(8, 4) == next); // ギリギリ無効
			assert(next._min == 8);
		 	exf = new ExtentFragment(5, 10);
			auto prev = new ExtentFragment(0, 8);
			exf._prev = prev;
			assert(exf.maxChange(8, 4) !is null); // ギリギリ有効
			assert(exf.maxChange(7, 4) == prev); // ギリギリ無効
			assert(prev._max == 7);
		}
		void testChop() {
			auto exf = new ExtentFragment(0, 20);
			exf.chop(4, 4);  // 二つに
			assert(exf._min == 0);
			assert(exf._max == 3);
			assert(exf._next._min == 5);
			assert(exf._next._max == 20);

			exf._next.chop(6, 4);  // 欠ける
			assert(exf._min == 0);
			assert(exf._max == 3);
			assert(exf._next._min == 7);
			assert(exf._next._max == 20);
			exf._next.chop(12, 4);  // 二つに
			assert(exf._min == 0);
			assert(exf._max == 3);
			assert(exf._next._min == 7);
			assert(exf._next._max == 11);
			assert(exf._next._next._min == 13);
			assert(exf._next._next._max == 20);

			exf._next.chop(10, 4);  // 二つとも消滅
			assert(exf._min == 0);
			assert(exf._max == 3);
			assert(exf._next._min == 13);
			assert(exf._next._max == 20);
		}
		void testCopy() {
			auto src = new ExtentFragment(3, 5);
			auto srcNext = new ExtentFragment(7, 13);
			src._next = srcNext;
			srcNext._prev = src;

			auto cpy = src.deepCopy();
			src._max = 17;
			src._next._min = 11;
			assert(cpy._max == 5);
			assert(cpy._next._min == 7);
		}

		testMinMax();
		testChop();
		testCopy();
	}
	bool contains(pos pos) {
		return _min <= pos && pos <= _max;
	}

	public override string toString() {
		if (_next !is null) {
			return  format("%d-%d, %s", _min, _max, _next);
		} else {
			return  format("%d-%d", _min, _max);
		}
	}
}
