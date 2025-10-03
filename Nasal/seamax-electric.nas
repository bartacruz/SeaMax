var e = electric;

# Create new electric system that updates 5 times a second.
var electricsystem = e.System.new("seamax",0.2);
var starter_bus = e.Bus.new("starter-bus");
var main_bus = e.Bus.new("main-bus");

# Battery (12v 32a/h 240 CCA as per POH)
# connected to the starter bus to feed the starter directly.
# connected to the main bus from the starter bus via a 40A fuse and the battery switch.
# 
var battery = e.Battery.new("battery",12,32.0,cc_amps=240.0,charge_amps=2.0);
var battery_switch = e.Switch.new("battery-switch","/controls/electric/battery-switch");
var master_breaker = e.Breaker.new("master",40.0);
var master_switch = e.Switch.new("master-switch","/controls/electric/master-switch");

# System.connect support chaining.
electricsystem.connect(battery, battery_switch, starter_bus,master_breaker, master_switch, main_bus);

# Reverse connection for loading the battery...
electricsystem.connect( main_bus, master_switch, master_breaker, starter_bus, battery_switch, battery);

# Alternator (12v 50a/h as per POH)
# Connected to the main bus via a 50A fuse and a switch
electricsystem.connect(
    e.Alternator.new("alternator","/engines/engine[0]/rpm",14.0,50.0,2000),
    starter_bus
);

### Engine related loads

# Starter engine draws 80A while cranking.
electricsystem.connect(
    starter_bus,
    e.Load.new("starter",80.0,"/controls/engines/engine[0]/starter")
);
# 4A Fuel pump with 5A breaker.
electricsystem.connect(
    main_bus,
    e.Breaker.new("fuel-pump",5.0),
    e.Load.new("fuel-pump",4.0,"/controls/fuel/tank[2]/boost-pump")
);

### Exterior lights

# landing light LED 36w @12v => 3A with 5A breaker
electricsystem.add_light(main_bus,"landing-light",3.0,5.0);

var lights_breaker = e.Breaker.new("lights",10.0);
electricsystem.connect(main_bus,lights_breaker);

# 7w average led strobe light
electricsystem.add_light(lights_breaker,"strobe-lights",1.0);
# 2x 15w led nav lights
electricsystem.add_light(lights_breaker,"nav-lights",2.0);

# Interior lights
electricsystem.add_light(lights_breaker,"instrument-lights",0.2);
# Flood Light
electricsystem.add_light(lights_breaker,"flood-light-left",0.3);
electricsystem.add_light(lights_breaker,"flood-light-right",0.3);

### Avionics
electricsystem.add_instrument(main_bus,"transponder",3.0,5.0);
electricsystem.add_instrument(main_bus,"gps",3.0,5.0,"/controls/electric/master-switch");
electricsystem.add_instrument(main_bus,"turn-coordinator",3.0,5.0,"/controls/electric/master-switch");

electricsystem.connect(
    main_bus,
    e.Breaker.new("bilge-pump",3.0),
    e.Load.new("bilge-pump",2.0,"/controls/electric/bilge-pump")
);
electricsystem.connect(
    main_bus,
    e.Breaker.new("landing-gear",10.0),
    e.Load.new("landing-gear",7.0,"/controls/electric/landing-gear")
);

setlistener("sim/signals/fdm-initialized",func{
    electricsystem.enable();
});

print("SeaMax electrical system loaded");


