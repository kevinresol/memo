package memo;

import memo.Comparer;
using tink.CoreApi;

@:forward
abstract Memo<In, Out>(MemoObject<In, Out>) from MemoObject<In, Out> to MemoObject<In, Out> {
	public inline function new(f:Next<In, Out>, ?comparer:Comparer<In>)
		this = new SimpleMemo(f, comparer);
	
	@:from
	public static function ofNext<In, Out>(f:Next<In, Out>):Memo<In, Out>
		return new Memo(f);
		
	public function map<A>(f:Next<Out, A>, ?comparer:Comparer<Out>):Memo<In, A>
		return new MapMemo(this, f, comparer);
		
	public function combine<In2, Out2, Combined>(other:Memo<In2, Out2>, f:Combiner<Out, Out2, Combined>, ?c1:Comparer<Out>, ?c2:Comparer<Out2>):Memo<Pair<In, In2>, Combined>
		return new CombinedMemo(this, other, f, c1, c2);
		
	
}

interface MemoObject<In, Out> {
	function get(v:In):Promise<Out>;
	function invalidate():Void;
}

typedef Cache<In, Out> = Pair<In, Promise<Out>>;

class SimpleMemo<In, Out> implements MemoObject<In, Out> {

	var f:Next<In, Out>;
	var comparer:Comparer<In>;
	var cache:Cache<In, Out>;
	
	public function new(f, ?comparer) {
		this.f = f;
		this.comparer = comparer != null ? comparer : EqualityComparer.get();
	}
	
	public function get(v:In):Promise<Out> {
		if(cache == null || !comparer.equals(cache.a, v))
			cache = new Pair(v, f(v));
		return cache.b;
	}
	
	public function invalidate()
		cache = null;
}

class MapMemo<In, Mid, Out> implements MemoObject<In, Out> {

	var prev:Memo<In, Mid>;
	var f:Next<Mid, Out>;
	var cache:Cache<Mid, Out>;
	var comparer:Comparer<Mid>;
	
	public function new(prev, f, ?comparer) {
		this.prev = prev;
		this.f = f;
		this.comparer = comparer != null ? comparer : EqualityComparer.get();
	}
	
	public function get(v:In):Promise<Out> {
		return prev.get(v).next(function(o) {
			if(cache == null || !comparer.equals(cache.a, o))
				cache = new Pair(o, f(o));
			return cache.b;
		});
	}
	
	public function invalidate()
		cache = null;
}

class CombinedMemo<In1, In2, Out1, Out2, Combined> implements MemoObject<Pair<In1, In2>, Combined> {

	var m1:Memo<In1, Out1>;
	var m2:Memo<In2, Out2>;
	var f:Combiner<Out1, Out2, Combined>;
	var cache:Cache<Pair<Out1, Out2>, Combined>;
	var c1:Comparer<Out1>;
	var c2:Comparer<Out2>;
	
	public function new(m1, m2, f, ?c1, ?c2) {
		this.m1 = m1;
		this.m2 = m2;
		this.f = f;
		this.c1 = c1 != null ? c1 : EqualityComparer.get();
		this.c2 = c2 != null ? c2 : EqualityComparer.get();
	}
	
	public function get(v:Pair<In1, In2>):Promise<Combined> {
		return (m1.get(v.a) && m2.get(v.b))
			.next(function(out) {
				if(cache == null || !c1.equals(cache.a.a, out.a) || !c2.equals(cache.a.b, out.b))
					cache = new Pair(out, f(out.a, out.b));
				return cache.b;
			});
	}
	
	public function invalidate()
		cache = null;
}

@:callable
abstract Combiner<In1, In2, Out>(In1->In2->Promise<Out>) from In1->In2->Promise<Out> {
      
  @:from static function ofSafe<In1, In2, Out>(f:In1->In2->Outcome<Out, Error>):Combiner<In1, In2, Out> 
    return function (x1, x2) return f(x1, x2);
    
  @:from static function ofSync<In1, In2, Out>(f:In1->In2->Future<Out>):Combiner<In1, In2, Out> 
    return function (x1, x2) return f(x1, x2);
    
  @:from static function ofSafeSync<In1, In2, Out>(f:In1->In2->Out):Combiner<In1, In2, Out> 
    return function (x1, x2) return f(x1, x2);
	
}