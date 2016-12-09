module extent.Extent;

import std.exception;
private import std.algorithm;
private import std.array;
private import std.stdio;
private import std.string;

private import common;
private import extent.ExtentFragment;


/// ヒントで示された[長さ]が取りうる位置範囲。
///
/// min, max がそれぞれ左右を指すのか、それとも上下を指すのかは、このオブジェクトを保持するコンテキストに依存します。
/// 両隣の位置範囲情報への参照を持ったリンクリスト実装です。
///
/// shorten**メソッドによって、このオブジェクトは自律的に短縮をします。この際、コンストラクタで指定されたgetCellによって各座標のCell内容を得ます。
/// また、shorten**メソッドによって範囲の見直しが発生すると、両隣のExtentに対してもshorten** の連鎖を起こします。
class Extent {
	private const string dbg;

	private Extent _prev;
	private Extent _next;
	private pos _length;
	private ExtentFragment _fragmentsHead;
	private ExtentFragment _fragmentsTail;

	pos min() { return _fragmentsHead._min; }
	pos max() { return _fragmentsTail._max; }
	pos length() { return _length; }
	Extent prev() { return _prev; }
	Extent next() { return _next; }

	package void min(pos arg) {
		if (_fragmentsHead._min < arg) {
			_fragmentsHead = _fragmentsHead.minChange(arg, _length);
			if (_next !is null) {
				_next.min(_fragmentsHead._min + length + 1);
			}
		}
	}
	package void max(pos arg) {
		if (_fragmentsTail._max > arg) {
			_fragmentsTail = _fragmentsTail.maxChange(arg, _length);
			if (_prev !is null) {
				_prev.max(_fragmentsTail._max - length - 1);
			}
		}
 	}

	this(pos length, Extent prev, string dbg="") {
		this.dbg = dbg;
		this._length = length;
		ExtentFragment exf = new ExtentFragment(0, pos.max);
		this._fragmentsHead = exf;
		this._fragmentsTail = exf;

		this._prev = prev;
		if (prev) {
			prev.setNext(this);
		}
	}
	private void setNext(Extent next) {
		this._next = next;
	}

	// コピーコンストラクタ
	this(Extent src) {
		this.dbg = src.dbg;
		this._length = src.length;
		this._fragmentsHead = src._fragmentsHead.deepCopy();
		auto tail = this._fragmentsHead;
		for(;tail._next !is null;tail = tail._next) {}
		this._fragmentsTail = tail;

		if (src._next) {
			this._next = new Extent(src._next);
			this._next._prev = this;
		}
	}

	public void setCell(pos at, Cell cell) {
		switch (cell) {
		case Cell.Fill:
			setCellFill(at);
			break;
		case Cell.Empty:
			setCellEmpty(at);
			break;
		default:
			enforce(false);
		}
	}
	private void setCellFill(pos at) {
		for (auto temp = _fragmentsHead; temp !is null; temp = temp._next) {
			if (at == temp._min - 1) {
				temp.minChange(at + 1, _length);
			} else if (at == temp._max + 1) {
				temp.maxChange(at + 1, _length);
			}
		}
		if (_fragmentsHead == _fragmentsTail) {
			_fragmentsHead.minChange(at - _length + 1, _length);
			_fragmentsHead.maxChange(at + _length - 1, _length);
		}
	}
	private void setCellEmpty(pos at) {
		pos orgMin = _fragmentsHead._min;
		pos orgMax = _fragmentsTail._max;
		for (auto temp = _fragmentsHead; temp !is null; temp = temp._next) {
			if (temp._min <= at && at <= temp._max) {
				auto chopped = temp.chop(at, _length);
				if (temp == _fragmentsHead) {
					_fragmentsHead = chopped;
				}
				if (temp == _fragmentsTail) {
					for (;chopped._next !is null; chopped = chopped._next) {}
					_fragmentsTail = chopped;
				}
			}
		}
		if (orgMin != _fragmentsHead._min && next !is null) {
			next.min(_fragmentsHead._min + length + 1);
		}
		if (orgMax != _fragmentsTail._max && prev !is null) {
			prev.max(_fragmentsTail._max - length - 1);
		}
	}

	public void cleanUp(SetCell _callback) {
		if (_fragmentsHead == _fragmentsTail) {
			// 一つなら
			pos d = length * 2 - (_fragmentsHead._max - _fragmentsHead._min + 1);
			if (d <= 0) {
				return;
			} else {
				pos fillMin = _fragmentsHead._max - length + 1;
				pos fillMax = _fragmentsHead._min + length - 1;
				for (pos i = fillMin; i <= fillMax; i ++) {
					_callback(Cell.Fill, i);
				}
			}
		}
	}

	public bool contains(pos arg) {
		for (ExtentFragment temp = _fragmentsHead; temp !is null; temp = temp._next) {
			if (temp.contains(arg)) {
				return true;
			}
		}
		return false;
	}
	public bool isFixed() {
		return (_fragmentsHead == _fragmentsTail
				&& _fragmentsHead._max - _fragmentsHead._min + 1 == length);
	}

	public override string toString() {
		return format("%s @%d(%s)", dbg, length, _fragmentsHead);
	}

	// 不変条件表明
	invariant() {
		void check(const(ExtentFragment) temp) {
			if (temp._next !is null) {
				//　断片の範囲は重なり合わない。
				assert(temp._max < temp._next._min);
			}
			// すべての断片が有効なサイズを持つ
			assert(temp._max - temp._min >= _length - 1);
			if (temp._next !is null) {
				check(temp._next);
			}
		}
		check(_fragmentsHead);
	}
	unittest {
		testCopy: {
			Extent ext = new Extent(4, null, "");
			ext.max(20);

			ext.setCell(5, Cell.Empty);
			Extent copy = new Extent(ext);

			assert(ext.toString() == " @4(0-4, 6-20)");
			ext.setCell(12, Cell.Empty);
			assert(ext.toString() == " @4(0-4, 6-11, 13-20)");
			assert(copy.toString() == " @4(0-4, 6-20)");
		}
		testSetClean: {
			Extent ext = new Extent(4, null, "");
			ext.max(20);

			ext.setCell(11, Cell.Empty);
			assert(ext.toString() == " @4(0-10, 12-20)");
			ext.setCell(5, Cell.Empty);
			assert(ext.toString() == " @4(0-4, 6-10, 12-20)");
			ext.setCell(15, Cell.Empty);
			assert(ext.toString() == " @4(0-4, 6-10, 16-20)");
			ext.setCell(12, Cell.Empty);
			assert(ext.toString() == " @4(0-4, 6-10, 16-20)");
			ext.setCell(2, Cell.Empty);
			assert(ext.toString() == " @4(6-10, 16-20)", ext.toString());
			ext.cleanUp((c, x) { assert(false, "CALLED"); });
			ext.setCell(18, Cell.Empty);
			assert(ext.toString() == " @4(6-10)", ext.toString());
			pos[] cleanUpArgs1 = [];
			Cell[] cleanUpArgs2 = [];
			ext.cleanUp((c, x) {
				cleanUpArgs1 ~= x;
				cleanUpArgs2 ~= c;
			});
			assert(cleanUpArgs1.sort().array() == [7,8,9]);
			assert(cleanUpArgs2 == [Cell.Fill,Cell.Fill,Cell.Fill]);
		}
		testRemove: {
			Extent ext = new Extent(1, null, "");
			ext.max(2);
			ext.setCell(1, Cell.Empty);
			ext.setCell(2, Cell.Fill);
			ext.min(1);
			assert(ext._fragmentsHead == ext._fragmentsTail);
			assert(ext._fragmentsHead._min == 2);
			assert(ext._fragmentsHead._max == 2);
		}
	}
}
