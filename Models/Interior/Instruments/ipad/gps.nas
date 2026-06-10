var gps_canvas = canvas.new({
  "name": "gps_canvas",   # The name is optional but allow for easier identification
  "size": [1848, 2524], # Size of the underlying texture (should be a power of 2, required) [Resolution]
  "view": [3072, 4096],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
                        # which will be stretched the size of the texture, required)
  "mipmapping": 1       # Enable mipmapping (optional)
});

var TestMap = gps_canvas.createGroup().createChild("map");
var ctrl_ns = canvas.Map.Controller.get("Aircraft position");
var source = ctrl_ns.SOURCES["gps_canvas"]; 
if (source == nil) { 
    # TODO: amend 
    var source = ctrl_ns.SOURCES["gps_canvas"] = { 
        getPosition: func subvec(geo.aircraft_position().latlon(), 0, 2), 
        getAltitude: func getprop('/position/altitude-ft'), 
        getHeading: func { 
            if (me.aircraft_heading) getprop('/orientation/heading-deg') else 0;
        }, 
        aircraft_heading: 1, 
    }; 
} 
setlistener("/instrumentation/ipad/gps/aircraft-heading-up", func(n) { 
    source.aircraft_heading = n.getBoolValue(); 
    }, 1); 
# Make it move with our aircraft: 
TestMap.setController("Aircraft position", "gps_canvas");
TestMap.setRange(2);
TestMap.setTranslation( gps_canvas.get("view[0]")/2, gps_canvas.get("view[1]")/2 );

var ToggleLayerVisible = func(name) { (var l = TestMap.getLayer(name)).setVisible(l.getVisible()); }; 
var SetLayerVisible = func(name,n=1) { TestMap.getLayer(name).setVisible(n); }; 
var SetProjection = func(projection) { TestMap._node.setValue("projection", projection)};

var r = func(name,vis=1,zindex=nil) return caller(0)[0];

foreach(var type; [ r('APT'), r('VOR'), r('NDB'), r('APS') ]) { 
    TestMap.addLayer(
        factory: canvas.SymbolLayer, 
        type_arg: type.name, 
        visible: type.vis, 
        priority: 4, 
    ); 
    SetLayerVisible(type.name,1);
}
foreach(var type; [ r('OSM')]) { 
    TestMap.addLayer(
        factory: canvas.OverlayLayer, 
        type_arg: type.name, 
        visible: type.vis, 
        priority: 1, 
    ); 
}
gps_canvas.addPlacement({"node": "chartsscreen", "capture-events":1});


var volt_prop = "/systems/electrical/outputs/gps";
var start_prop = "/aircraft/ipad/ison";
setlistener(volt_prop, func (i) {
	if( i.getValue() <= 9  and getprop(start_prop) != 0){
    setprop(start_prop,0);
  }else if ( i.getValue() > 9 and getprop(start_prop) == 0){
    setprop(start_prop,1);
  }
});