module extent.SurfacePossibility;

private import std.concurrency;
private import std.string;

private import extent.LinePossibility0;
private import Quest;
private import common;

class SurfacePossibility {
  private Quest quest;
  private Tid[] hTid;
  private Tid[] vTid;
  private long activeThreads;
  private void delegate() suspendedCallback;

  this(Quest q, void delegate() suspendedCallback) {
    this.suspendedCallback = suspendedCallback;
    this.quest = quest;
  }

  void start() {
    activeThreads = 0;
    for (pos x = 0; x < quest.width; x ++) {
      LineThread lt = new LineThread(
        thisTid,
        quest.height,
        cast(immutable)(quest.vHints[x]),
        Direction.Vertical,
        x);
      vTid[x] = lt.start();
    }
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
      send(tid, new immutable(Content)(Direction.Vertical, Cell.Empty, -1,-1));
      activeThreads ++;
    }
    foreach (tid; hTid) {
      send(tid, new immutable(Content)(Direction.Horizontal, Cell.Empty, -1, -1));
      activeThreads ++;
    }

    while(activeThreads > 0) {
      receive(
        (Done _) {
          activeThreads --;
        },
        (immutable(Content) content) {
          if (content.D == Direction.Vertical) {
            send(vTid[content.Line], content);
            activeThreads ++;
          } else if (content.D == Direction.Horizontal) {
            send(hTid[content.Line], content);
            activeThreads ++;
          }
        });
    }
    suspendedCallback();
  }
}
enum Done { Done }
enum Direction { Vertical, Horizontal }
class Content {
  Direction D;
  Cell CellType;
  pos Pos;
  pos Line;

  this(Direction d, Cell type, pos p, pos l) immutable {
    D = d;
    CellType = type;
    Pos = p;
    Line = l;
  }
}

class LineThread {
  private Tid ownerTid;
  private bool done = false;
  private pos size;
  private immutable(pos[]) hints;
  private Direction d;
  private pos line;

  this(Tid owner, pos _size, immutable(pos[]) _hints, Direction _d, pos _line) {
    ownerTid = owner;
    size = _size;
    hints = _hints;
    d = _d;
    line = _line;
  }

  Tid start() {
    return spawn(&threadAction, ownerTid, size, hints, d, line, "");
  }
}
void threadAction(Tid ownerTid, pos size, immutable(pos[]) hints, Direction d, pos line, string dbg="") {
  LinePossibility lp = new LinePossibility(size, hints, dbg);
  SetCell callbackSetCell = (c, p) {
    send(
      ownerTid,
      new immutable(Content)(
        d == Direction.Vertical ? Direction.Horizontal : Direction.Vertical,
        c,
        line,
        p));
  };
  bool done = false;
  while (! done) {
    receive(
      (Content content) {
        if (content.Pos > 0) {
          lp.set(content.CellType, content.Pos);
        }
        lp.checkUp(callbackSetCell);
        send(ownerTid, Done.Done);
      },
      (Done _) {
        done = true;
      });
  }
}
