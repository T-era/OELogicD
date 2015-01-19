module extent_resolver.ForceResolver;

private import std.stdio;
private import std.string;
private import Quest;
private import parts.ExclusiveException;
private import parts.Position;
private import parts.Resolver;
private import parts.DeepCopy;

class ForceResolver : Resolver {
	private Quest quest;
	private Resolver sence;

	this(Quest quest, Resolver another) {
		this.quest = quest;
		this.sence = another;

	}
	public void checkUp() {
		while (true) {
			sence.checkUp();

			bool done = true;
			for (int x = 0; x < quest.width; x ++) {
				for (int y = 0; y < quest.height; y ++) {
					if (quest[y, x] == Cell.Unknown) {
						done = false;
						try {
							// TODO copy
							set(x, y, Cell.Fill);
						} catch (ExclusiveException ex) {
							set(x, y, Cell.Empty);
						}
					}
				}
			}
			if (done) {
				break;
			}
		}
	}

	public void set(int x, int y, Cell cell) {
		sence.set(x, y, cell);
	}
}
