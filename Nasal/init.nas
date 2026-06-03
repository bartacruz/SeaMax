canopy  = aircraft.door.new("/sim/model/door-positions/canopy", 1, 0 );

var autostart = func{
    setprop("controls/electric/master-switch",1);
    setprop("controls/fuel/tank[0]/fuel_selector", 1);
    setprop("controls/fuel/tank[1]/fuel_selector", 1);
    setprop("controls/fuel/tank[2]/boost-pump", 1);
  
    setprop("/controls/engines/engine[0]/magnetos",3);

    setprop("controls/engines/engine[0]/mixture",1);
    setprop("controls/flight/throttle",0.15);
    setprop("/controls/gear/brake-parking",1);
    setprop("controls/switches/strobe-lights", 0);
    setprop("controls/switches/nav-lights", 1);
    setprop("sim/messages/copilot", "Now press the s key to start the engine");
}

var init_gears = func() {
    var solid = getprop("/fdm/jsbsim/ground/solid");
    print("SOLID? ", solid);
    if (solid == 0) {
        setprop("/controls/gear/detecting",1);
        setprop("/controls/gear/gear-down",0);
        setprop("/controls/gear/gear-position-norm",0);
        settimer(func(){
            setprop("/controls/gear/detecting",0);
        },5);
    } 
};

var check_gears = func(n) {
    var gear_down = n.getBoolValue();
    if (gear_down == 1) {
        # pitch up the water surfaces
        setprop("/fdm/jsbsim/contact/unit[3]/z-position",1.0);
        setprop("/fdm/jsbsim/contact/unit[4]/z-position",1.0);
        print("Water surfaces up");
    } else {
        # pitch down the water surfaces
        # TODO: keep the original position inside a variable.
        setprop("/fdm/jsbsim/contact/unit[3]/z-position",0);
        setprop("/fdm/jsbsim/contact/unit[4]/z-position",0);
        print("Water surfaces down");
    }
}
 ###############################################################################
# On-screen displays
var enableOSD = func {
    var left  = screen.display.new(20, 10);
    var right = screen.display.new(-300, 10);

    left.add("/engines/engine/rpm");
    left.add("/instrumentation/airspeed-indicator/indicated-speed-kt");
    left.add("/fdm/jsbsim/propulsion/engine/power-hp");
    left.add("/controls/engines/engine/throttle");
    #left.add("/fdm/jsbsim/aero/force/Lift_alpha");
    #left.add("/fdm/jsbsim/aero/function/kCLge");
    # left.add("/fdm/jsbsim/gear/unit[0]/WOW");
    # left.add("/fdm/jsbsim/gear/unit[1]/WOW");
    # left.add("/fdm/jsbsim/gear/unit[2]/WOW");
    # left.add("/fdm/jsbsim/sim-time-sec");
    # left.add("/orientation/heading-magnetic-deg");
    # left.add("/fdm/jsbsim/aero/moment/Yaw_alpha");
    # left.add("/fdm/jsbsim/aero/moment/Yaw_beta");
    # left.add("/fdm/jsbsim/aero/moment/Yaw_roll_rate");
    # left.add("/fdm/jsbsim/aero/moment/Yaw_damp");
    # left.add("/fdm/jsbsim/aero/moment/Yaw_rudder");
    # left.add("/fdm/jsbsim/aero/moment/Yaw_aileron");
    # left.add("/fdm/jsbsim/fcs/rudder-pos-rad");

    right.add("/fdm/jsbsim/aero/alpha-rad");
    right.add("/fdm/jsbsim/aero/alpha-wing-rad");
    right.add("/orientation/pitch-deg");
    right.add("/controls/flight/elevator");
    right.add("/controls/flight/elevator-trim");
    # right.add("/fdm/jsbsim/aero/qbar-psf");
    #right.add("/fdm/jsbsim/propulsion/engine[0]/thrust-coefficient");
    #right.add("/fdm/jsbsim/aero/function/kCLge");
    
    #right.add("/fdm/jsbsim/aero/force/Lift_hull");
}

var engineHasStarted = setlistener("/engines/engine/running", func(val) {
  if( val.getBoolValue() ) {
    setprop("/engines/engine/has-started", 1);
    setprop("/fdm/jsbsim/propulsion/engine/has-started", 1);
    removelistener(engineHasStarted);
  }
});
    
setlistener("/sim/signals/fdm-initialized", func {
    print("Checking ground...");
    setlistener("/controls/gear/gear-down", check_gears,1,1);
    init_gears();
    
    enableOSD();
}, 0, 0);