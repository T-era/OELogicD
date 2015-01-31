module force_resolver.ForceResolver;

private import std.stdio;
private import std.string;
private import Quest;
private import parts.ExclusiveException;
private import parts.Position;
private import extent_resolver.ExtentResolver;
private import parts.CompList;

class ForceResolver {
	private ExtentResolver sence;
	bool[Position] done;

	this(ExtentResolver another) {
		this.sence = another;
	}

	public void checkUp() {
		sence.checkUp();
		if (sence.done()) {
			return;
		} else {
			scope Position p = sence.getEasyPoint();
			if (p in done) throw new Exception("!?");

			done[p] = true;
			try {
				auto newSence = sence.deepCopy();
				newSence.set(p.x, p.y, Cell.Fill);
				ForceResolver child = new ForceResolver(newSence);
				child.checkUp();

				copyInto!(Cell[])(newSence.quest.cells, sence.quest.cells);
			} catch (ExclusiveException ex) {
				this.sence.set(p.x, p.y, Cell.Empty);
				checkUp();
			}
		}
	}
}
