module extent.LineThread;

private import std.concurrency;
private import std.stdio;
private import std.string;

private import extent.LinePossibility;
private import common;
private import Quest;

enum Done { Done, Conflict }
enum Direction { Vertical, Horizontal }

class EventContent {
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

  public string imToString() immutable {
    return format("%s %d %d %s", D, Line, Pos, CellType);
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
    this.ownerTid = owner;
    size = _size;
    hints = _hints;
    d = _d;
    line = _line;
  }

  Tid start() {
    return spawn(&threadAction, this.ownerTid, size, hints, d, line, "");
  }

  private static void threadAction(Tid myOwnerTid, pos size, immutable(pos[]) hints, Direction d, pos line, string dbg="") {
    LinePossibility lp = new LinePossibility(size, hints, dbg);
    SetCell callbackSetCell = (c, p) {
      send(
        myOwnerTid,
        new immutable(EventContent)(
          d == Direction.Vertical ? Direction.Horizontal : Direction.Vertical,
          c,
          line,
          p));
    };
    bool done = false;
    while (! done) {
      receive(
        (immutable(EventContent) content) {
          try {
            if (content.Pos > 0) {
              lp.set(content.CellType, content.Pos);
            }
            lp.checkUp(callbackSetCell);
            send(myOwnerTid, Done.Done);
          } catch (ExclusiveException ex) {
            send(myOwnerTid, Done.Conflict);
          }
        },
        (Done _) {
          done = true;
        });
    }
  }
}
