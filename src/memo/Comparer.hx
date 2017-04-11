package memo;

using tink.CoreApi;

@:forward
abstract Comparer<T>(ComparerObject<T>) from ComparerObject<T> to ComparerObject<T> {
	@:from
	public static function ofFunc<T>(f:T->T->Bool):Comparer<T>
		return new FuncComparer(f);
		
}

interface ComparerObject<T> {
	function equals(v1:T, v2:T):Bool;
}

class FuncComparer<T> implements ComparerObject<T> {
	var f:T->T->Bool;
	public function new(f)
		this.f = f;
	public function equals(v1:T, v2:T):Bool
		return f(v1, v2);
}

class PairComparer<T1, T2> implements ComparerObject<Pair<T1, T2>> {
	static var inst:PairComparer<Dynamic, Dynamic> = new PairComparer(EqualityComparer.get(), EqualityComparer.get());
	public static function get<T1, T2>():PairComparer<T1, T2> return cast inst;
	var c1:Comparer<T1>;
	var c2:Comparer<T2>;
	public function new(c1, c2) {
		this.c1 = c1;
		this.c2 = c2;
	}
	public function equals(v1:Pair<T1, T2>, v2:Pair<T1, T2>):Bool
		return c1.equals(v1.a, v2.a) && c2.equals(v1.b, v2.b);
}

class EqualityComparer<T> implements ComparerObject<T> {
	static var inst:EqualityComparer<Dynamic> = new EqualityComparer();
	public static function get<T>():EqualityComparer<T> return cast inst;
	function new() {}
	public function equals(v1:T, v2:T):Bool
		return v1 == v2;
}