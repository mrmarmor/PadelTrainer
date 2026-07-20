import 'package:flutter/foundation.dart';

enum StrokeType {
  forehand,
  backhand,
  volley,
  bandeja,
  vibora,
  smash,
  highReturn,
  lowReturn,
  lob,
  returnServe,
  panerst
}

extension StrokeTypeHebrew on StrokeType {
  String get label {
    switch (this) {
      case StrokeType.forehand: return 'פורהנד';
      case StrokeType.backhand: return 'בקהנד';
      case StrokeType.volley: return 'וולי';
      case StrokeType.bandeja: return 'בנדחה';
      case StrokeType.vibora: return 'ויבריט';
      case StrokeType.smash: return 'סמאש';
      case StrokeType.highReturn: return 'בחזרה גבוהה';
      case StrokeType.lowReturn: return 'בחזרה נמוכה';
      case StrokeType.lob: return 'לוב';
      case StrokeType.returnServe: return 'החזרת סרב';
      case StrokeType.panerst: return 'פנורסט';
    }
  }
}

enum PlayMode {
  withWall,
  beforeWall,
  random
}

extension PlayModeHebrew on PlayMode {
  String get label {
    switch (this) {
      case PlayMode.withWall: return 'עם הקיר';
      case PlayMode.beforeWall: return 'לפני הקיר';
      case PlayMode.random: return 'אקראי';
    }
  }
}

enum Direction {
  straight,
  diagonal,
  lineToLine
}

extension DirectionHebrew on Direction {
  String get label {
    switch (this) {
      case Direction.straight: return 'קו ישר';
      case Direction.diagonal: return 'אלכסון';
      case Direction.lineToLine: return 'מקו לקו';
    }
  }
}

enum Spin {
  none,
  topLight,
  topMedium,
  topHeavy
}

extension SpinHebrew on Spin {
  String get label {
    switch (this) {
      case Spin.none: return 'ללא ספין';
      case Spin.topLight: return 'טופספין קל';
      case Spin.topMedium: return 'טופספין בינוני';
      case Spin.topHeavy: return 'טופספין כבד';
    }
  }
}

enum Height {
  low,
  medium,
  high
}

extension HeightHebrew on Height {
  String get label {
    switch (this) {
      case Height.low: return 'נמוך';
      case Height.medium: return 'בינוני';
      case Height.high: return 'גבוה';
    }
  }
}

enum SideDistribution {
  forehandOnly,
  backhandOnly,
  random,
  alternating
}

extension SideDistributionHebrew on SideDistribution {
  String get label {
    switch (this) {
      case SideDistribution.forehandOnly: return 'רק פורהנד';
      case SideDistribution.backhandOnly: return 'רק בקהנד';
      case SideDistribution.random: return 'אקראי';
      case SideDistribution.alternating: return 'לסירוגין';
    }
  }
}

enum ServeSide {
  right,
  left
}

extension ServeSideHebrew on ServeSide {
  String get label {
    switch (this) {
      case ServeSide.right: return 'ימין';
      case ServeSide.left: return 'שמאל';
    }
  }
}

class PadelMachineSettings extends ChangeNotifier {
  StrokeType _strokeType = StrokeType.forehand;
  PlayMode _playMode = PlayMode.withWall;
  Direction _direction = Direction.straight;
  double _speed = 0.5;
  Spin _spin = Spin.none;
  Height _height = Height.medium;
  int _timeInterval = 2;
  int _ballCount = 10;
  SideDistribution _sideDistribution = SideDistribution.random;
  ServeSide _side = ServeSide.right;

  StrokeType get strokeType => _strokeType;
  set strokeType(StrokeType val) { _strokeType = val; notifyListeners(); }

  PlayMode get playMode => _playMode;
  set playMode(PlayMode val) { _playMode = val; notifyListeners(); }

  Direction get direction => _direction;
  set direction(Direction val) { _direction = val; notifyListeners(); }

  double get speed => _speed;
  set speed(double val) { _speed = val; notifyListeners(); }

  Spin get spin => _spin;
  set spin(Spin val) { _spin = val; notifyListeners(); }

  Height get height => _height;
  set height(Height val) { _height = val; notifyListeners(); }

  int get timeInterval => _timeInterval;
  set timeInterval(int val) { _timeInterval = val; notifyListeners(); }

  int get ballCount => _ballCount;
  set ballCount(int val) { _ballCount = val; notifyListeners(); }

  SideDistribution get sideDistribution => _sideDistribution;
  set sideDistribution(SideDistribution val) { _sideDistribution = val; notifyListeners(); }

  ServeSide get side => _side;
  set side(ServeSide val) { _side = val; notifyListeners(); }
}
