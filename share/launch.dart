import 'dart:async';

// Just playing with some dart basics.. never used it before.

class PseudoClock {
  int hour;
  int minute;
  int second;
  PseudoClock([this.hour, this.minute = 0, this.second = 0]) {
    this._start();
  }

  PseudoClock.StartOn(Date startTime) {
    this.hour = startTime.hour;
    this.minute = startTime.minute;
    this.second = startTime.second;

    this._start();
  }


  static String _zeroPadNumber(num number) {
    // TODO(jzacsh) remove if sprint is ever native:
    return number.toString().length == 1 ?
      '0'.concat(number.toString()) : number.toString();
  }

  void _printHMS() {
    // TODO(jzacsh) import sprintf pub package for \r
    print('\r'
        .concat(_zeroPadNumber(this.hour))
        .concat(':')
        .concat(_zeroPadNumber(this.minute))
        .concat(':')
        .concat(_zeroPadNumber(this.second)));
  }

  void advanceHMS() {
    if (++this.second == 60) {
      this.second = 0;
      if (++this.minute == 60) {
        this.minute = 0;
        if (++this.hour == 24) {
          this.hour = 0;
        }
      }
    }
  }

  void _start() {
    new Timer.repeating(1000, (Timer timer) {
      this.advanceHMS();
      this._printHMS();
    });
  }

  void stop() {
    throw const NotImplementedException();
  }
}

// NB: object-fields accessed dynamically, as array items is not quite possible.
//void advanceHMS() {
//  checkMaxReset(this, 'second', 59, () {
//    this.second = 0;
//    checkMaxReset(this, 'minute', 59, () {
//      this.minute = 0;
//      checkMaxReset(this, 'hour', 23, () {
//        this.hour = 0;
//      });
//    });
//  });
//}

//void checkMaxReset(PseudoClock pseudoClock, String timeField, num max, Object reset) {
//  pseudoClock[timeField];
//  if (pseudoClock[timeField] == max) {
//    reset();
//  } else {
//    ++pseudoClock[timeField];
//  }
//}

main() {
  new PseudoClock.StartOn(new Date.now());
  // new PseudoClock(1, 59, 57);
}

// vim: et:ts=2:sw=2
