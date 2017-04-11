package memo;

import memo.Comparer;
using tink.CoreApi;

@:forward
abstract Memo<In, Out>(MemoObject<In, Out>) from MemoObject<In, Out> to MemoObject<In, Out> {
	public inline function new(f:Next<In, Out>, ?comparer:Comparer<In>)
		this = new SimpleMemo(f, comparer);
	
	@:from
	public static inline function ofNext<In, Out>(f:Next<In, Out>):Memo<In, Out>
		return new Memo(f);
		
	public inline function map<A>(f:Next<Out, A>, ?comparer:Comparer<Out>):Memo<In, A>
		return new MapMemo(this, f, comparer);
		
	public function combine<In2, Out2, Combined>(other:Memo<In2, Out2>, f:Combiner<Out, Out2, Combined>, ?c1:Comparer<Out>, ?c2:Comparer<Out2>):Memo<Pair<In, In2>, Combined> {
		var comparer = switch [c1, c2] {
			case [null, null]:
				PairComparer.get();
			default: 
				if(c1 == null) c1 = EqualityComparer.get();
				if(c2 == null) c2 = EqualityComparer.get();
				new PairComparer(c1, c2);
		}
		return new CombinedMemo(this, other, f, comparer);
	}
		
	
}

interface MemoObject<In, Out> {
	function get(v:In):Promise<Out>;
	function invalidate():Void;
}

typedef Cache<In, Out> = Pair<In, Promise<Out>>;

class MemoBase<In, CIn, Out> implements MemoObject<In, Out> {
	var comparer:Comparer<CIn>;
	var cache:Cache<CIn, Out>;
	
	public function new(?comparer:Comparer<CIn>)
		this.comparer = comparer != null ? comparer : EqualityComparer.get();
	
	public function get(v:In):Promise<Out>
		throw 'abstract';
		
	public function invalidate()
		cache = null;
}

class SimpleMemo<In, Out> extends MemoBase<In, In, Out> {

	var f:Next<In, Out>;
	
	public function new(f, ?comparer) {
		super(comparer);
		this.f = f;
	}
	
	override function get(v:In):Promise<Out> {
		if(cache == null || !comparer.equals(cache.a, v))
			cache = new Pair(v, f(v));
		return cache.b;
	}
}

class MapMemo<In, Mid, Out> extends MemoBase<In, Mid, Out> {

	var prev:Memo<In, Mid>;
	var f:Next<Mid, Out>;
	
	public function new(prev, f, ?comparer) {
		super(comparer);
		this.prev = prev;
		this.f = f;
	}
	
	override function get(v:In):Promise<Out> {
		return prev.get(v).next(function(o) {
			if(cache == null || !comparer.equals(cache.a, o))
				cache = new Pair(o, f(o));
			return cache.b;
		});
	}
	
}

class CombinedMemo<In1, In2, Out1, Out2, Combined> extends MemoBase<Pair<In1, In2>, Pair<Out1, Out2>, Combined> {

	var m1:Memo<In1, Out1>;
	var m2:Memo<In2, Out2>;
	var f:Combiner<Out1, Out2, Combined>;
	
	public function new(m1, m2, f, ?comparer) {
		super(comparer);
		this.m1 = m1;
		this.m2 = m2;
		this.f = f;
	}
	
	override function get(v:Pair<In1, In2>):Promise<Combined> {
		return (m1.get(v.a) && m2.get(v.b))
			.next(function(out) {
				if(cache == null || !comparer.equals(cache.a, out))
					cache = new Pair(out, f(out.a, out.b));
				return cache.b;
			});
	}
}
