enum RepeatMode { none, one, all }

extension RepeatModeExtension on RepeatMode {
  RepeatMode next() {
    switch (this) {
      case RepeatMode.none: return RepeatMode.all;
      case RepeatMode.all:  return RepeatMode.one;
      case RepeatMode.one:  return RepeatMode.none;
    }
  }

  String get label {
    switch (this) {
      case RepeatMode.none: return 'No Repeat';
      case RepeatMode.all:  return 'Repeat All';
      case RepeatMode.one:  return 'Repeat One';
    }
  }
}
