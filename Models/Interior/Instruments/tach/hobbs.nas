# Stolen from c172p and adapted for single engine.

var hobbsmeter = aircraft.timer.new("/engines/engine[0]/hobbs", 60, 1);
setlistener("/engines/engine[0]/running", func {
        if (getprop("/engines/engine[0]/running")) {
            hobbsmeter.start();
            print("Hobbs system started");
        } else {
            hobbsmeter.stop();
            print("Hobbs system stopped");
        }
    }, 1, 0
);
var update_hobbs_meter = func {
    # in seconds
    var hobbs = getprop("/engines/engine[0]/hobbs") or 0.0;
    
    # This uses minutes, for testing
    #hobbs = hobbs / 60.0;
    # in hours
    #hobbs = (hobbs_160hp + hobbs_180hp) / 3600.0;
    # tenths of hour

    hobbs = hobbs / 3600.0;

    setprop("/instrumentation/hobbs-meter/digits0", math.mod(int(hobbs * 10), 10));
    # rest of digits
    setprop("/instrumentation/hobbs-meter/digits1", math.mod(int(hobbs), 10));
    setprop("/instrumentation/hobbs-meter/digits2", math.mod(int(hobbs / 10), 10));
    setprop("/instrumentation/hobbs-meter/digits3", math.mod(int(hobbs / 100), 10));
    setprop("/instrumentation/hobbs-meter/digits4", math.mod(int(hobbs / 1000), 10));
};

setlistener("/engines/engine[0]/hobbs", update_hobbs_meter, 1, 0);
