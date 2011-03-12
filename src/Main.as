package {
	import com.actionscriptbible.Example;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	import ore.orelib.VEBTree;
	
	[SWF(width="465",height="465")]
	public class Main extends Example {
		private static const KEY_RANGE:int = int.MAX_VALUE;
		private static const NUM_ELEMENTS:int = 1e5;
		private static const LOOP_COUNT:int = 1e5;
		
		private var _sortedArray:Array;
		private var _vEBTree:VEBTree;
		
		public function Main() {
			_sortedArray = [];
			_vEBTree = new VEBTree(KEY_RANGE);
			for (var i:int = 0; i < NUM_ELEMENTS; i++) {
				var key:int = int(KEY_RANGE * Math.random());
				// vEB木に重複なしにキーを追加できたら、配列にもキーを追加する（重複キーなら再試行）
				if (_vEBTree.add(key)) {
					_sortedArray.push(key);
				}else {
					i--;
				}
			}
			_sortedArray.sort(Array.NUMERIC);
			
			trace("整数のキーの範囲 [0," + KEY_RANGE + ")");
			trace("保持キー数 " + NUM_ELEMENTS + " 個");
			trace("範囲内のランダムなキーの検索を " + LOOP_COUNT + " 回試行");
			
			runTest();
			stage.addEventListener(MouseEvent.CLICK, runTest);
		}
		
		/** テストを実行する */
		private function runTest(event:MouseEvent = null):void {
			var temp:int, i:int;
			trace("----------------------------------------");
			temp = getTimer();
			for (i = 0; i < LOOP_COUNT; i++) {
				useBinarySearch(int(KEY_RANGE * Math.random()));
			}
			temp = getTimer() - temp;
			trace("二分探索: " + temp + "ms");
			temp = getTimer();
			for (i = 0; i < LOOP_COUNT; i++) {
				_vEBTree.contains(int(KEY_RANGE * Math.random()));
			}
			temp = getTimer() - temp;
			trace("vEB木検索: " + temp + "ms");
		}
		
		/** ソート済み配列を二分探索する */
		private function useBinarySearch(key:int):Boolean {
			var low:int = 0;
			var high:int = _sortedArray.length - 1;
			while (low <= high) {
				var middle:int = (low + high) / 2;
				var middleValue:int = _sortedArray[middle];
				
				if (key < middleValue) {
					high = middle - 1;
				}else if (key > middleValue) {
					low = middle + 1;
				}else {
					return true;
				}
			}
			return false;
		}
	}
}