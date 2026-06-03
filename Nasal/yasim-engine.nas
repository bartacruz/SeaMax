###
# Yasim engine and fuel management.
# 
# (c) 2025 Julio Santa Cruz
#
# Work in progress...
#

print("Engine management loading...");
var GAL2LBS = 6.152;

var FuelTank = {
    new: func( index ) {
        var o = {parents : [FuelTank]};
        o.index = index;
        return o;
    },
    getProp: func(prop) {
        return getprop("/consumables/fuel/tank["~ me.index ~ "]/" ~ prop);
    },
    setProp: func(prop,val) {
        return setprop("/consumables/fuel/tank["~ me.index ~ "]/" ~ prop,val);
    },
    isEmpty: func() {
        return me.getProp("empty");
    },
    isSelected: func() {
        return getprop("/controls/fuel/tank["~ me.index ~ "]/fuel_selector")
        #return me.getProp("selected");
    },
    has: func(qty, unit) {

        return me.isSelected() and me.getProp("level-" ~ unit) >= has;
    },
    getLbs: func() {
        return me.getProp("level-lbs");
    },
    setLbs: func(qty) {
        me.setProp("level-lbs",qty);
    },
    addLbs: func(qty) {
        me.setLbs(me.getLbs()+qty);
    },
    toFill: func(){
        return me.getProp("capacity-gal_us")*GAL2LBS - me.getLbs();
    }
};

var engine = {};
var ENGINE_NODE = "/aircraft/engine";
var fuel_pump_el_psi = 5;
var tanks = [];
var sump = nil;

var setup_fuel = func() {
    append(tanks,FuelTank.new(0));
    append(tanks,FuelTank.new(1));
    tanks[0].setProp("selected",0);
    tanks[1].setProp("selected",0);
    sump = FuelTank.new(2);
    sump.setProp("selected",1);
    sump.setLbs(0);
}

var read_engine=func() {
    # var path = pts.Sim.fgHome.getValue() ~ "/Export/A320SavedWaypoints.xml";
	# 	# create file if it doesn't exist
	# 	if (io.stat(path) == nil) {
	# 		me.write();
	# 		return;
	# 	}
	# 	var data = io.readxml(path).getChild("waypoints");
    foreach(var n; props.globals.getNode(ENGINE_NODE).getChildren()){
       engine[n.getName()] = n.getValue();
    }
};

var fuel_loop = func(dt) {
    # First, check the sump's level.
    # 0.1 lbs total capacity. 
    # The float valve opens at 0.075 lbs and closes at 0.09 to avoid spilling.
    var sump_debt = sump.toFill()-0.01; # 0.09 lbs max fill
    if (sump_debt >0.015) { 
        var feeders = [];
        foreach (var t; tanks) {
            if (t.isSelected() and ! t.isEmpty()) {
                append(feeders,t);
            }
        }
        var refill = 0;

        foreach (var f; feeders) {
            var take =math.min(sump_debt / size(feeders), f.getLbs());
            refill += take;
            f.addLbs(-1*take);
        }
        sump.addLbs(refill);
    }
    if (sump.isEmpty()) {
        # No fuel, exit.
        setprop("/engines/engine/fuel-flow-real-gph",0);
        return;
    }

    var consumed = getprop("/engines/engine/fuel-consumed-lbs");
    var give = math.min(consumed,sump.getLbs());
    var gph = 3600 * (give / GAL2LBS) / dt ;
    
    sump.addLbs(-1*give);
    setprop("/engines/engine/fuel-consumed-lbs",consumed - give);
    setprop("/engines/engine/fuel-flow-real-gph",gph);

};

var fuel_pump_loop = func() {
    var fuel_psi = 0;
    if (!sump.isEmpty()) {
        var el_pump = getprop("/systems/electrical/outputs/fuel-pump") > 7;
        var eng_rpm = getprop("/engines/engine/rpm") ;
        var eng_pump = eng_rpm > 300;
        var fuel_psi = math.max(el_pump * fuel_pump_el_psi, eng_rpm*eng_pump*0.001);
    }
    setprop("/engines/engine/fuel-pressure-psi",fuel_psi);
    setprop("/engines/engine/out-of-fuel",fuel_psi < 0.001);    
};

var loop = nil;
var EngineLoop = {
    new: func(interval) {
        var o = {parents:[EngineLoop]};
        o.interval = interval;
        o.loop = updateloop.UpdateLoop.new(components: [o], update_period: interval, enable: 1);
        return o;
    },
    reset: func {},
    update: func(dt) {
        fuel_loop(dt);
        fuel_pump_loop(dt);
    },
};


setlistener("/sim/signals/fdm-initialized", func() {
    if (contains(globals, "fuel") and typeof(fuel) == "hash")
		fuel.loop = func nil;       # kill $FG_ROOT/Nasal/fuel.nas' loop
    
    #read_engine();
    setup_fuel();
    loop = EngineLoop.new(0.2);
    print("Engine management started");

});
print("Engine management hooked");