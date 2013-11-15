import 'dart:async';
import 'dart:io';

// Just playing with some dart basics.. never used it before.

class PseudoClock {
  int hour;
  int minute;
  int second;
  PseudoClock([this.hour, this.minute = 0, this.second = 0]) {
    this._start();
  }

  PseudoClock.StartOn(DateTime startTime) {
    this.hour = startTime.hour;
    this.minute = startTime.minute;
    this.second = startTime.second;

    this._start();
  }


  static String _zeroPad(num number) {
    // TODO(jzacsh) remove if sprint is ever native:
    return number.toString().length == 1 ?
      '0'+ number.toString() : number.toString();
  }

  void _updateHMS() {
    stdout.write('\r'
        + _zeroPad(this.hour) + ':'
        + _zeroPad(this.minute) + ':'
        + _zeroPad(this.second));
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
    new Timer.periodic(new Duration(seconds:1), (Timer timer) {
      this.advanceHMS();
      this._updateHMS();
    });
  }

  void stop() {
    throw new UnimplementedError('stopping clock is not implemented.');
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
  new PseudoClock.StartOn(new DateTime.now());
  // new PseudoClock(1, 59, 57);
}

// vim: et:ts=2:sw=2
