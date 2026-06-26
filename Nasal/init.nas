canopy  = aircraft.door.new("/sim/model/door-positions/canopy", 1, 0 );
var leftOSD = nil;
var rightOSD = nil;


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
var initOSD = func {
    leftOSD  = screen.display.new(20, 10);
    leftOSD.interval = 0.2;
    leftOSD.format = "%.3g";    
    rightOSD = screen.display.new(-300, 10);
    rightOSD.interval = 0.2;
    rightOSD.format = "%.3g";    

    leftOSD.add("/engines/engine/rpm");
    leftOSD.add("/instrumentation/airspeed-indicator/indicated-speed-kt");
    leftOSD.add("/fdm/jsbsim/propulsion/engine/power-hp");
    leftOSD.add("/fdm/jsbsim/propulsion/engine/thrust-lbs");
    leftOSD.add("/controls/engines/engine/throttle");
    #leftOSD.add("/fdm/jsbsim/aero/force/Lift_alpha");
    #leftOSD.add("/fdm/jsbsim/aero/function/kCLge");
    # leftOSD.add("/fdm/jsbsim/gear/unit[0]/WOW");
    # leftOSD.add("/fdm/jsbsim/gear/unit[1]/WOW");
    # leftOSD.add("/fdm/jsbsim/gear/unit[2]/WOW");
    # leftOSD.add("/fdm/jsbsim/sim-time-sec");
    # leftOSD.add("/orientation/heading-magnetic-deg");
    # leftOSD.add("/fdm/jsbsim/aero/moment/Yaw_alpha");
    # leftOSD.add("/fdm/jsbsim/aero/moment/Yaw_beta");
    # leftOSD.add("/fdm/jsbsim/aero/moment/Yaw_roll_rate");
    # leftOSD.add("/fdm/jsbsim/aero/moment/Yaw_damp");
    # leftOSD.add("/fdm/jsbsim/aero/moment/Yaw_rudder");
    # leftOSD.add("/fdm/jsbsim/aero/moment/Yaw_aileron");
    # leftOSD.add("/fdm/jsbsim/fcs/rudder-pos-rad");
    
    rightOSD.add("/fdm/jsbsim/aero/function/kCLge");
    rightOSD.add("/fdm/jsbsim/hydro/fbz-lbs");
    rightOSD.add("/fdm/jsbsim/hydro/hull-drag-lbsft");
    rightOSD.add("/fdm/jsbsim/contact/unit[3]/compression-ft");
    rightOSD.add("/fdm/jsbsim/contact/unit[4]/compression-ft");
    rightOSD.add("/fdm/jsbsim/contact/unit[5]/compression-ft");
    rightOSD.add("/fdm/jsbsim/aero/alpha-rad");
    rightOSD.add("/fdm/jsbsim/aero/alpha-wing-rad");
    rightOSD.add("/orientation/pitch-deg");
    rightOSD.add("/controls/flight/elevator");
    rightOSD.add("/controls/flight/elevator-trim");
    # rightOSD.add("/fdm/jsbsim/aero/qbar-psf");
    #rightOSD.add("/fdm/jsbsim/propulsion/engine[0]/thrust-coefficient");
    
    
    #rightOSD.add("/fdm/jsbsim/aero/force/Lift_hull");
};

var toggleOSD = func() {
    if (leftOSD == nil) {
        initOSD();
    } else {
        leftOSD.toggle();
        rightOSD.toggle();
    }
};

var engineHasStarted = setlistener("/engines/engine/running", func(val) {
  if( val.getBoolValue() ) {
    setprop("/engines/engine/has-started", 1);
    setprop("/fdm/jsbsim/propulsion/engine/has-started", 1);
    removelistener(engineHasStarted);
  }
});
    
var sl = setlistener("/sim/signals/fdm-initialized", func {
    removelistener(sl);
    print("Checking ground...");
    # setlistener("/controls/gear/gear-down", check_gears,1,1);
    init_gears();
}, 0, 0);