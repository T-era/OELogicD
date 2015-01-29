module force_resolver.ForceResolver;

private import std.stdio;
private import std.string;
private import Quest;
private import parts.ExclusiveException;
private import parts.Position;
private import extent_resolver.ExtentResolver;
private import parts.DeepCopy;

class ForceResolver {
	private ExtentResolver sence;

	this(ExtentResolver another) {
		this.sence = another;
	}

	public void checkUp() {
		sence.checkUp();
		if (sence.done()) {
			return;
		} else {
			scope Position p = sence.getEasyPoint();
			try {
				auto newSence = sence.deepCopy();
//				writeln("try to set ", p);
				newSence.set(p.x, p.y, Cell.Fill);
				ForceResolver child = new ForceResolver(newSence);
				child.checkUp();
//				writeln(newSence.quest);
//				writeln(newSence);
//				writeln();
			} catch (ExclusiveException ex) {
				this.sence.set(p.x, p.y, Cell.Empty);
				checkUp();
			}
		}
	}
}
