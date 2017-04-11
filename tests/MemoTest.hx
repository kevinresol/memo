package;

import memo.Memo;

using tink.CoreApi;
using Lambda;

@:asserts
class MemoTest {
	public function new() {}
	
	public function memo() {
		var i = 0;
		var memo = new Memo(function(a:Array<Int>) {
			i++;
			return a.fold(function(i, sum) return sum + i, 0);
		});
		
		function _test(_in, _i, _out, ?pos:haxe.PosInfos)
			memo.get(_in).handle(function(o) switch o {
				case Success(out):
					asserts.assert(i == _i, null, pos);
					asserts.assert(out == _out, null, pos);
				case Failure(e):
					asserts.fail(e, pos);
			});
			
		var a = [1,2,3];
		_test(a, 1, 6);
		_test(a, 1, 6);
		
		var a = [2,3,4];
		_test(a, 2, 9);
		_test(a, 2, 9);
		
		memo.invalidate();
		_test(a, 3, 9);
		_test(a, 3, 9);
		
		return asserts.done();
	}
	
	public function map() {
		var i = 0;
		var j = 0;
		var memo = new Memo(function(a:Array<Int>) {
			i++;
			return a.fold(function(i, sum) return sum + i, 0);
		});
		
		var mapped = memo.map(function(v) {
			j++;
			return v * v;
		});
		
		function _test(_in, _i, _j, _out, ?pos:haxe.PosInfos)
			mapped.get(_in).handle(function(o) switch o {
				case Success(out):
					asserts.assert(i == _i, null, pos);
					asserts.assert(j == _j, null, pos);
					asserts.assert(out == _out, null, pos);
				case Failure(e):
					asserts.fail(e, pos);
			});
			
		var a = [1,2,3];
		_test(a, 1, 1, 36);
		_test(a, 1, 1, 36);
		
		var a = [2,3,4];
		_test(a, 2, 2, 81);
		_test(a, 2, 2, 81);
		
		mapped.invalidate();
		_test(a, 2, 3, 81);
		_test(a, 2, 3, 81);
		
		memo.invalidate();
		_test(a, 3, 3, 81);
		_test(a, 3, 3, 81);
		
		return asserts.done();
	}
	
	public function combine() {
		var i = 0;
		var j = 0;
		var k = 0;
		
		var memo1 = new Memo(function(a:Array<Int>) {
			i++;
			return a.fold(function(i, sum) return sum + i, 0);
		
		});
		var memo2 = new Memo(function(a:Array<Int>) {
			j++;
			return a.fold(function(i, sum) return sum + i * i, 0);
		});
		
		var combined = memo1.combine(memo2, function(v1, v2) {
			k++;
			return v1 + v2;
		});
		
		function _test(_in1, _in2, _i, _j, _k, _out, ?pos:haxe.PosInfos)
			combined.get(new Pair(_in1, _in2)).handle(function(o) switch o {
				case Success(out):
					asserts.assert(i == _i, null, pos);
					asserts.assert(j == _j, null, pos);
					asserts.assert(k == _k, null, pos);
					asserts.assert(out == _out, null, pos);
				case Failure(e):
					asserts.fail(e, pos);
			});
			
		var a = [1,2,3];
		_test(a, a, 1, 1, 1, 20);
		_test(a, a, 1, 1, 1, 20);
		
		var b = [2,3,4];
		_test(a, b, 1, 2, 2, 35);
		_test(a, b, 1, 2, 2, 35);
		
		_test(b, a, 2, 3, 3, 23);
		_test(b, a, 2, 3, 3, 23);
		
		combined.invalidate();
		_test(b, a, 2, 3, 4, 23);
		_test(b, a, 2, 3, 4, 23);
		
		return asserts.done();
	}
}