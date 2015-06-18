module parts.Resolver;
import common;

interface Resolver {
	public void checkUp();
	public void set(pos  x, pos  y, Cell cell);
	public bool done();
}
