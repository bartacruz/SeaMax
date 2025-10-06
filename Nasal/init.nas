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
    setprop("controls/lighting/strobe-lights", 0);
    setprop("controls/lighting/nav-lights", 1);
    setprop("sim/messages/copilot", "Now press the s key to start engine");
}



var check_ground = func() {
    var solid = getprop("/fdm/jsbsim/ground/solid");
    print("SOLID? ", solid);
    if (solid == 0) {
        setprop("/controls/gear/gear-down",0);
    }
    
};
 ###############################################################################
# On-screen displays
var enableOSD = func {
    # var left  = screen.display.new(20, 10);
    var right = screen.display.new(-300, 10);

    # left.add("/fdm/jsbsim/sim-time-sec");
    # left.add("/orientation/heading-magnetic-deg");
    # left.add("/fdm/jsbsim/hydro/true-course-deg");
    # left.add("/fdm/jsbsim/hydro/beta-deg");
    # left.add("/fdm/jsbsim/hydro/pitch-deg");
    # left.add("/fdm/jsbsim/hydro/roll-deg");
    # left.add("/fdm/jsbsim/hydro/float/pitch-deg");
    # left.add("/fdm/jsbsim/hydro/float/roll-deg");
    # left.add("/fdm/jsbsim/hydro/float/height-agl-ft");
    # left.add("/fdm/jsbsim/inertia/cg-x-in");
    # left.add("/fdm/jsbsim/inertia/cg-z-in");
    # left.add("/fdm/jsbsim/hydro/fdrag-lbs");
    # left.add("/fdm/jsbsim/hydro/displacement-drag-lbs");
    # left.add("/fdm/jsbsim/hydro/planing-drag-lbs");
    # left.add("/fdm/jsbsim/hydro/fbz-lbs");
    # left.add("/fdm/jsbsim/hydro/buoyancy-lbs");
    # left.add("/fdm/jsbsim/hydro/planing-lift-lbs");
    #left.add("/fdm/jsbsim/hydro/X/force-lbs");
    #left.add("/fdm/jsbsim/hydro/Y/force-lbs");
    # left.add("/fdm/jsbsim/hydro/yaw-moment-lbsft");
    # left.add("/fdm/jsbsim/hydro/pitch-moment-lbsft");
    # left.add("/fdm/jsbsim/hydro/roll-moment-lbsft");
    #left.add("/fdm/jsbsim/hydro/transverse-wave/wave-length-ft");
    #left.add("/fdm/jsbsim/hydro/transverse-wave/wave-amplitude-ft");
    # left.add("/fdm/jsbsim/hydro/transverse-wave/squat-ft");
    #left.add("/fdm/jsbsim/hydro/transverse-wave/pitch-trim-change-deg");
    #left.add("/fdm/jsbsim/hydro/environment/wave/relative-heading-rad");
    #left.add("/fdm/jsbsim/hydro/orientation/wave-pitch-trim-change-deg");
    #left.add("/fdm/jsbsim/hydro/orientation/wave-roll-trim-change-deg");
    #left.add("/fdm/jsbsim/hydro/environment/wave/angular-frequency-rad_sec");
    #left.add("/fdm/jsbsim/hydro/environment/wave/wave-number-rad_ft");
    #left.add("/fdm/jsbsim/hydro/environment/wave/level-fwd-ft");
    #left.add("/fdm/jsbsim/hydro/environment/wave/level-at-hrp-ft");
    #left.add("/fdm/jsbsim/hydro/environment/wave/level-aft-ft");

    right.add("/engines/engine/rpm");
    right.add("/instrumentation/airspeed-indicator/indicated-speed-kt");
    right.add("/fdm/jsbsim/aero/alpha-rad");
    right.add("/fdm/jsbsim/aero/qbar-psf");
    right.add("/fdm/jsbsim/propulsion/engine[0]/thrust-coefficient");
    right.add("/fdm/jsbsim/aero/function/kCLge");
    right.add("/fdm/jsbsim/aero/force/Lift_alpha");
    right.add("/fdm/jsbsim/aero/force/Lift_hull");
    
    
    # right.add("/fdm/jsbsim/hydro/active-norm");
    # right.add("/fdm/jsbsim/hydro/v-kt");
    # right.add("/fdm/jsbsim/hydro/vbx-fps");
    # right.add("/fdm/jsbsim/hydro/vby-fps");
    # right.add("/fdm/jsbsim/hydro/qbar-u-psf");
    # right.add("/fdm/jsbsim/hydro/Frode-number");
    # right.add("/fdm/jsbsim/hydro/speed-length-ratio");
    # right.add("/fdm/jsbsim/left-pontoon/leaked-water-lbs");
    # right.add("/fdm/jsbsim/right-pontoon/leaked-water-lbs");
}

    
setlistener("/sim/signals/fdm-initialized", func {
    settimer(check_ground,1);
    print("Checking ground...");
    #enableOSD();
}, 0, 0);