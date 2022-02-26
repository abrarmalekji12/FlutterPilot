class RevertWork {
  final List<Work> _stack = [];

  RevertWork();

  factory RevertWork.init() {
    return RevertWork();
  }

  int get totalOperations {
    return _stack.length;
  }

  void clear() {
    _stack.clear();
  }

  void add(
      dynamic oldValue, void Function() work, void Function(dynamic) workUndo) {

    _stack.add(Work(oldValue, work, workUndo));
    work.call();
  }

  void revert() {
    while (_stack.isNotEmpty) {
      final Work work = _stack.removeAt(_stack.length - 1);
      work.undoWork.call(work.oldValue);
    }
  }

  void undo() {
    if(totalOperations>0) {
      final work = _stack.removeAt(_stack.length - 1);
      work.undoWork.call(work.oldValue);
    }

  }
}

class ApplyWork {
  final List<Work> _stack = [];

  ApplyWork();

  factory ApplyWork.init() {
    return ApplyWork();
  }

  int get totalOperations {
    return _stack.length;
  }

  void clear() {
    _stack.clear();
  }

  void add(dynamic oldValue, void Function(dynamic) work) {
    _stack.add(Work(oldValue, () {}, work));
  }

  void apply() {
    while (_stack.isNotEmpty) {
      final Work work = _stack.removeAt(_stack.length - 1);
      work.undoWork.call(work.oldValue);
    }
  }
}

class Work {
  final dynamic oldValue;
  final void Function() work;
  final void Function(dynamic) undoWork;

  Work(this.oldValue, this.work, this.undoWork);
}
