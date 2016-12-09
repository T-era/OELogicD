module extent.ExtentResolver;

private import std.concurrency;
private import std.stdio;
private import std.string;

private import extent.LineThread;
private import Quest;
private import common;

alias immutable(Cell[][]) ImCells;
alias void delegate(bool, ImCells) SuspendedCallback;

class ExtentResolver {
  private Quest quest;
  private Tid[] hTid;
  private Tid[] vTid;
  private long activeThreads;
  private SuspendedCallback suspendedCallback;

  this(Quest q, SuspendedCallback suspendedCallback) {
    this.suspendedCallback = suspendedCallback;
    this.quest = q;
  }

  void start() {
    activeThreads = 0;
    vTid.length = quest.width;
    for (pos x = 0; x < quest.width; x ++) {
      LineThread lt = new LineThread(
        thisTid,
        quest.height,
        cast(immutable)(quest.vHints[x]),
        Direction.Vertical,
        x);
      vTid[x] = lt.start();
    }
    hTid.length = quest.height;
    for (pos y = 0; y < quest.height; y ++) {
      LineThread lt = new LineThread(
        thisTid,
        quest.width,
        cast(immutable)(quest.hHints[y]),
        Direction.Horizontal,
        y);
      hTid[y] = lt.start();
    }
    foreach (tid; vTid) {
      send(tid, new immutable(EventContent)(Direction.Vertical, Cell.Empty, -1,-1));
      activeThreads ++;
    }
    foreach (tid; hTid) {
      send(tid, new immutable(EventContent)(Direction.Horizontal, Cell.Empty, -1, -1));
      activeThreads ++;
    }
    Cell[][] cells = quest.cells;  // TODO コピーする？(それともquestをコピーするからここでは不要？)
    bool legal = true;

    while(activeThreads > 0 && legal) {
      receive(
        (Done d) {
          if (d == Done.Done) {
            activeThreads --;
          } else {
            legal = false;
            activeThreads = 0;
          }
        },
        (immutable(EventContent) content) {
          final switch (content.D) {
            case Direction.Vertical:
              if (quest.isIn(content.Line, content.Pos)
                  && cells[content.Pos][content.Line] == Cell.Unknown) {
                cells[content.Pos][content.Line] = content.CellType;
                send(vTid[content.Line], content);
                activeThreads ++;
              }
              break;
            case Direction.Horizontal:
              if (quest.isIn(content.Pos, content.Line)
                  && cells[content.Line][content.Pos] == Cell.Unknown) {
                cells[content.Line][content.Pos] = content.CellType;
                send(hTid[content.Line], content);
                activeThreads ++;
              }
          }
        });
    }
    foreach (tid; vTid) {
      send(tid, Done.Done);
    }
    foreach (tid; hTid) {
      send(tid, Done.Done);
    }

    suspendedCallback(legal, cast(immutable) cells);
  }
}

unittest {
  void testQuest(Quest q, Cell[][] expected) {
    auto sp = new ExtentResolver(q, (legal, cells){
      assert(legal);
      assert(expected == cells, format("%s <-> %s", expected, cells));
    });
    sp.start();
  }
  Cell E = Cell.Empty;
  Cell F = Cell.Fill;
  Cell U = Cell.Unknown;

  test1: {
    auto q = new Quest(
      ["2", "4", "4", "2"],
      ["2", "4", "4", "2"],
      " ");
    testQuest(q, [[E,F,F,E],[F,F,F,F],[F,F,F,F],[E,F,F,E]]);
  }
  test2: {
    auto q = new Quest(
      ["3", "1 1 1", "2 2", "1 1 1", "3"],
      ["3", "1 1 1", "2 2", "1 1 1", "3"],
      " ");
    testQuest(q, [[E,F,F,F,E],[F,E,F,E,F],[F,F,E,F,F],[F,E,F,E,F],[E,F,F,F,E]]);
  }
  test_unfixable: {
    auto q = new Quest(
      ["1", "3", "3", "1"],
      ["2", "2", "2", "2"],
      " ");
    testQuest(q, [[U,U,U,U],[E,F,F,E],[E,F,F,E],[U,U,U,U]]);
  }
  test_rect: {
    auto q = new Quest(
      ["3", "3"],
      ["2", "2", "2"],
      " ");
    testQuest(q, [[F,F],[F,F],[F,F]]);
  }
}
