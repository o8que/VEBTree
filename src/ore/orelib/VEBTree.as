package ore.orelib {
	
	public class VEBTree {
		private var _maxSize:int;               // 最大で保持できるキーの数
		private var _lowBits:int;               // キーの下位ビット数（上位ビット取得用）
		private var _lowMask:int;               // キーの下位ビットマスク（下位ビット取得用）
		
		private var _children:Vector.<VEBTree>; // サブツリーのコレクション
		private var _aux:VEBTree;               // サブツリーが空でないかどうかを保持する補助ツリー
		private var _min:int;                   // 最小値のキャッシュ
		private var _max:int;                   // 最大値のキャッシュ
		private var _size:int;                  // 保持しているキーの数
		
		/**
		 * 指定された数のキーを保持できるvan Emde Boas木を作成します。
		 * @param	maxSize	最大で保持できるキーの数を指定する値です。値は2のべき乗に切り上げられます。
		 */
		public function VEBTree(maxSize:int) {
			// m-bit integer key
			var m:int = Math.ceil(Math.log(Math.max(2, maxSize)) / Math.LN2);
			_maxSize = Math.min(int.MAX_VALUE, uint(1 << m)); // Math.pow(2, m)
			_lowBits = m >> 1; // int(m / 2)
			_lowMask = (1 << _lowBits) - 1;
			
			_children = new Vector.<VEBTree>(1 << Math.ceil(m / 2), true);
			_aux = null;
			_min = int.MAX_VALUE;
			_max = int.MIN_VALUE;
			_size = 0;
		}
		
		/**
		 * 指定されたキーをツリーに追加します。
		 * @param	key	追加されるキーの値です。
		 * @return	キーが重複なしにツリーに追加された場合にtrueを返します。
		 */
		public function add(key:int):Boolean {
			// 範囲外のキーか、重複キーなら終了
			if ((key < 0 || key >= _maxSize) || (key == _min || key == _max)) { return false; }
			
			// ツリーが空なら、キーをキャッシュして終了
			if (_size == 0) {
				_min = _max = key;
				_size++;
				return true;
			}
			
			// キーがキャッシュを更新できるなら、キーとキャッシュをスワップする
			// スワップ後のキーを、サブツリーに追加する必要が無いなら終了
			var temp:int;
			if (key < _min) {
				temp = key; key = _min; _min = temp;
				if (key == _max) {
					_size++;
					return true;
				}
			}else if (key > _max) { 
				temp = key; key = _max; _max = temp;
				if (key == _min) {
					_size++;
					return true;
				}
			}
			
			// キーをサブツリーに追加する
			var i:int = key >> _lowBits;
			var j:int = key & _lowMask;
			if (!_children[i]) {
				_children[i] = new VEBTree(1 << _lowBits);
				_aux ||= new VEBTree(_children.length);
				_aux.add(i);
			}
			if (_children[i].add(j)) {
				_size++;
				return true;
			}else {
				return false;
			}
		}
		
		/**
		 * 指定されたキーをツリーから削除します。
		 * @param	key	削除されるキーの値です。
		 * @return	ツリー内に存在するキーが削除された場合にtrueを返します。
		 */
		public function remove(key:int):Boolean {
			// 範囲外のキーか、ツリーが空なら終了
			if (key < _min || key > _max) { return false; }
			
			// キーが唯一のキャッシュ（保持キー数が1）なら、ツリーを空にして終了
			if (key == _min && key == _max) {
				_min = int.MAX_VALUE;
				_max = int.MIN_VALUE;
				_size--;
				return true;
			}
			
			// キーがキャッシュにあり、
			// サブツリーが無い（保持キー数が2）なら削除(保持キー数を1に）して終了
			// サブツリーがあるなら（最小or最大の）キーを取得、キャッシュを更新してそのキーを削除候補にする
			var i:int;
			var j:int;
			if (key == _min) {
				if (!_aux) {
					_min = _max;
					_size--;
					return true;
				}else {
					i = _aux.min;
					j = _children[i].min;
					_min = (i * _children[i].maxSize) + j;
				}
			}else if (key == _max) {
				if (!_aux) {
					_max = _min;
					_size--;
					return true;
				}else {
					i = _aux.max;
					j = _children[i].max;
					_max = (i * _children[i].maxSize) + j;
				}
			// キーがキャッシュに無いなら、キーを削除候補にする
			// サブツリーが無いなら終了
			}else {
				i = key >> _lowBits;
				j = key & _lowMask;
				if (!_children[i]) { return false; }
			}
			
			// 削除候補をサブツリーから削除する
			// 削除成功後、サブツリーと補助ツリーが空ならそれも削除する
			if (_children[i].remove(j)) {
				if (_children[i].size == 0) {
					_children[i] = null;
					_aux.remove(i);
					if (_aux.size == 0) {
						_aux = null;
					}
				}
				_size--;
				return true;
			}else {
				return false;
			}
		}
		
		/**
		 * 指定されたキーがツリー内に存在するかどうか調べます。
		 * @param	key	ツリー内に存在するかどうか調べるキーの値です。
		 * @return	指定されたキーがツリー内に存在した場合にtrueを返します。
		 */
		public function contains(key:int):Boolean {
			// 範囲外のキーか、ツリーが空ならfalse
			if (key < _min || key > _max) { return false; }
			
			// キーがキャッシュされているならtrue
			if (key == _min || key == _max) { return true; }
			
			// サブツリーを調べる（サブツリーが空ならfalse）
			var i:int = key >> _lowBits;
			var j:int = key & _lowMask;
			return _children[i] && _children[i].contains(j);
		}
		
		/**
		 * 指定された値の、次に存在するキーの値を取得します。
		 * @param	key	次に存在するキーを調べるための基準となる値です。
		 * @return	次に存在するキーの値を返します。存在しなければ-1を返します。
		 */
		public function next(key:int):int {
			// ツリーが空か、値が最大値以上なら存在しない
			if (_size == 0 || key >= _max) { return -1; }
			
			// 値が最小値未満なら最小値を返す
			if (key < _min) { return _min; }
			
			// 値と同じサブツリー内にあるなら、そのサブツリーを調べる
			var i:int = key >> _lowBits;
			var j:int = key & _lowMask;
			if (_children[i] && j < _children[i].max) {
				return (i * _children[i].maxSize) + _children[i].next(j);
			}
			// 次のサブツリーがあるなら、そのサブツリーの最小値を返す
			if (_aux) {
				var nextChild:int = _aux.next(i);
				if (nextChild >= 0) {
					return (nextChild * _children[nextChild].maxSize) + _children[nextChild].min;
				}
			}
			// サブツリーが無いなら最大値を返す
			return _max;
		}
		
		/**
		 * 指定された値の、前に存在するキーの値を取得します。
		 * @param	key	前に存在するキーを調べるための基準となる値です。
		 * @return	前に存在するキーの値を返します。存在しなければ-1を返します。
		 */
		public function prev(key:int):int {
			// ツリーが空か、値が最小値以下なら存在しない
			if (_size == 0 || key <= _min) { return -1; }
			
			// 値が最大値より大きいなら最大値を返す
			if (key > _max) { return _max; }
			
			// 値と同じサブツリー内にあるなら、そのサブツリーを調べる
			var i:int = key >> _lowBits;
			var j:int = key & _lowMask;
			if (_children[i] && j > _children[i].min) {
				return (i * _children[i].maxSize) + _children[i].prev(j);
			}
			// 前のサブツリーがあるなら、そのサブツリーの最大値を返す
			if (_aux) {
				var prevChild:int = _aux.prev(i);
				if (prevChild >= 0) {
					return (prevChild * _children[prevChild].maxSize) + _children[prevChild].max;
				}
			}
			// サブツリーが無いなら最小値を返す
			return _min;
		}
		
		/** 最大で保持できるキーの数を取得します。 */
		public function get maxSize():int { return _maxSize; }
		/** ツリー内に存在する最小のキーの値を取得します。 */
		public function get min():int { return _min; }
		/** ツリー内に存在する最大のキーの値を取得します。 */
		public function get max():int { return _max; }
		/** ツリー内に保持しているキーの数を取得します。 */
		public function get size():int { return _size; }
	}
}