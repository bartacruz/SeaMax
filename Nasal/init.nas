var check_ground = func() {
    var solid = getprop("/fdm/jsbsim/ground/solid");
    print("SOLID? ", solid);
    if (solid == 0) {
        setprop("/controls/gear/gear-down",0);
    }
    
} 
setlistener("/sim/signals/fdm-initialized", func {
    settimer(check_ground,1);
    print("Checking ground...");
}, 0, 0);