module extent.ShortenListener;

import std.stdio;
import common;
import extent.Extent;


package interface ShortenOwner(TThis) {
  pos min();
  pos max();
  pos length();
  TThis prev();
  TThis next();
  void shortenMin(pos arg);
  void shortenMax(pos arg);
}

/// 範囲短縮と連鎖が終わったあとで行う処理。
/// 具体的には、短縮した範囲のFillセルについて、包含Extentが一つかどうかを判定する。
/// (一つしか包含Extentがないなら、そのExtentはそのFillセルに束縛される)
class ShortenListener(TOwner) {
  private ShortenOwner!(TOwner) owner;

  this(ShortenOwner!(TOwner) owner) {
    this.owner = owner;
  }

  void minShorted(pos previousMin, GetCell getCell) {
    pos currentMin = owner.min;
    ShortenOwner!(TOwner) prev = owner.prev;
    if (prev !is null) {
      auto granO = prev.prev;
      pos loopStart = (granO is null || granO.max < previousMin)
          ? previousMin
          : granO.max + 1;

      foreach (pos p; loopStart..currentMin) {
        if (getCell(p) == Cell.Fill) {
          prev.shortenMax(p + prev.length - 1);
          prev.shortenMin(p - prev.length + 1);
        }
      }
    }
  }
  void maxShorted(pos previousMax, GetCell getCell) {
    pos currentMax = owner.max;
    ShortenOwner!(TOwner) next = owner.next;
    if (next !is null) {
      auto granO = next.next;
      pos loopEnd = (granO is null || granO.min > previousMax)
          ? previousMax
          : granO.min - 1;

      foreach (pos p; (currentMax+1)..(loopEnd+1)) {
        if (getCell(p) == Cell.Fill) {
          next.shortenMax(p + next.length - 1);
          next.shortenMin(p - next.length + 1);
        }
      }
    }
  }
}

unittest {
  pos[] sMinCalled = [];
  pos[] sMaxCalled = [];

  class TestExtent : ShortenOwner!(TestExtent) {
    pos _min, _max, _length;
    TestExtent _prev, _next;
    this(pos min, pos max, pos length, TestExtent next) {
      this._min = min;
      this._max = max;
      this._length = length;
      this._next = next;
      if (next) {
        next._prev = this;
      }
    }

    pos min() { return _min; }
    pos max() { return _max; }
    pos length() { return _length; }
    TestExtent prev() { return _prev; }
    TestExtent next() { return _next; }
    void shortenMin(pos arg) { sMinCalled ~= arg; }
    void shortenMax(pos arg) { sMaxCalled ~= arg; }
  }
  Cell[] cells = [Cell.Unknown, Cell.Unknown, Cell.Unknown, Cell.Unknown,
    Cell.Fill];
  Cell getCell(pos p) {
    if (0 <= p && p < cells.length) {
      return cells[p];
    }
    return Cell.Unknown;
  }
  void testGranNextExists_then() {
    auto te = new TestExtent(0, 1, 1,
                new TestExtent(1, cells.length-2, 1,
                  new TestExtent(2, cells.length-1, 1, null)));

    auto sl = new ShortenListener!(TestExtent)(te);
    sMinCalled = [];
    sMaxCalled = [];

    sl.maxShorted(4, &getCell);
    assert([] == sMinCalled); // Fill セルは、まだ所有者が二人。
    assert([] == sMaxCalled);
  }
  void testGranNextExists_but() {
    auto te = new TestExtent(0, 1, 1,
                new TestExtent(1, cells.length-2, 1,
                  new TestExtent(5, cells.length-1, 1, null)));

    auto sl = new ShortenListener!(TestExtent)(te);
    sMinCalled = [];
    sMaxCalled = [];

    sl.maxShorted(4, &getCell);
    assert([4] == sMinCalled); // Fill セルはnext Extentが所有。
    assert([4] == sMaxCalled);
  }
  void testGranNextNot() {
    auto te = new TestExtent(0, 1, 1,
                new TestExtent(1, cells.length-2, 1, null));

    auto sl = new ShortenListener!(TestExtent)(te);
    sMinCalled = [];
    sMaxCalled = [];

    sl.maxShorted(4, &getCell);
    assert([4] == sMinCalled); // Fill セルはnext Extentが所有。
    assert([4] == sMaxCalled);
  }
  testGranNextExists_but();
  testGranNextExists_then();
  testGranNextNot();
}
