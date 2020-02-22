use v6.d;
use MONKEY-TYPING;
unit module Supply::Folds;

augment class Supply {
    #|[ Performs a fold given an initial value and a callback accepting a
        folded result and a value to be folded. ]
    proto method fold(|) {*}
    multi method fold(::?CLASS:D: &folder is raw --> ::?CLASS:D) {
        self.reduce: &folder
    }
    multi method fold(::?CLASS:D: &folder is raw, $init is raw --> ::?CLASS:D) {
        supply {
            my $result := $init;
            whenever self -> \value {
                $result := folder $result, value;
                LAST { emit $result }
            }
        }
    }

    #|[ Performs a scan given an initial value, a callback accepting a scanned
        result and a value to be scanned, and an optional keep named parameter
        for whether or not to hold on to the initial value. ]
    proto method scan(|) {*}
    multi method scan(::?CLASS:D: &scanner is raw --> ::?CLASS:D) {
        self.produce: &scanner
    }
    multi method scan(::?CLASS:D: &scanner is raw, $init is raw, Bool:D :$keep = False --> ::?CLASS:D) {
        supply {
            my $result := $init;
            emit $result if $keep;
            whenever self -> \value {
                $result := scanner $result, value;
                emit $result;
            }
        }
    }
}
