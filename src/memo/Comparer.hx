package memo;

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

class EqualityComparer<T> implements ComparerObject<T> {
	static var inst:EqualityComparer<Dynamic> = new EqualityComparer();
	public static function get<T>():EqualityComparer<T> return cast inst;
	function new() {}
	public function equals(v1:T, v2:T):Bool
		return v1 == v2;
}