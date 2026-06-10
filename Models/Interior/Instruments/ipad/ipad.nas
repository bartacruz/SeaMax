# var window = canvas.new({
#   "name": "canvas_map",   # The name is optional but allow for easier identification
#   "size": [1848, 2524], # Size of the underlying texture (should be a power of 2, required) [Resolution]
#   "view": [3072, 4096],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
#                         # which will be stretched the size of the texture, required)
#   "mipmapping": 1       # Enable mipmapping (optional)
# });
var window = canvas.new({
  "name": "ipad_canvas",
  "size": [2048, 2048],
  "view": [1024, 1430],
  "mipmapping": 1      
});

window.setColorBackground(0,0,0,1);
var time_base = "/sim/time/utc/";
var baseNode = props.globals.initNode("/instrumentation/ipad");
var homeNode = baseNode.initNode("homebutton",0,"BOOL");
var startedNode = baseNode.initNode("started",0,"BOOL");
var appNode = baseNode.initNode("app","","STRING");
var instrument_dir = "Aircraft/SeaMax/Models/Interior/Instruments/ipad/";
var volt_prop = "/systems/electrical/outputs/gps";


var BaseApp = {
  name: "BaseApp",
  icon: "baseapp.png",
  svg: nil,
  svg_file: nil,
  svg_keys: [],
  elements: {},
  loaded: false,

  # new: func(a_canvas) {
  #       var obj = {parents:[BaseApp]};
  #       obj._canvas = a_canvas;
  #       obj._group = a_canvas.createGroup(obj.name);
  #       obj.init();
  #       return obj;
  # },
  init: func(){
  },
  start: func() {  
  },
  show: func() {
    if( ! me.loaded) {
      me.init();
      me.loaded = true;
    }
    me._group.show();
  },
  hide: func() {
    me._group.hide();
  },
  update: func(dt){
    # Implement
  },
  _loadSVG: func(){
    if (!me.svg_file) {
      print(me.name," _loadSVG: No svgfile defined");
      return;
    }
    me._svg = canvas.parsesvg(me._group, instrument_dir ~ "apps/" ~ me.svg_file);
    
    foreach(var key; me.svg_keys) {
			me.elements[key] = me._group.getElementById(key);
			print("canvas key "~key);
		}
  },
};

var IPad = {
  name: "IPad",
  apps: {},
  active_app: nil,
  home_app: nil,
  update_period: 0.2,
  svg_keys: {},
  new: func(a_canvas) {
    var obj = {parents:[IPad]};
    obj._canvas = a_canvas;
    obj._group = a_canvas.createGroup(obj.name);
    obj._svg = canvas.parsesvg(obj._group, instrument_dir ~ "surround.svg");
    
    obj.init();
    return obj;
  },
  init: func() {
    me._group.setInt("z-index", 4);
    me._group.hide();
    var svg_keys = ["time.utc"];
		foreach(var key; svg_keys) {
			me.svg_keys[key] = me._group.getElementById(key);
			print("canvas key "~key);
		}
    me.loop = updateloop.UpdateLoop.new(components: [me], update_period: me.update_period, enable: 0);
    
    var m = me;
    setlistener(homeNode, func(node) {
        var is_pressed = node.getValue();
        
        if (is_pressed == 1) {
            # 1. Si el iPad está apagado, el botón lo enciende
            if (!startedNode.getValue()) {
                print("IPad: Encendiendo dispositivo desde botón físico");
                m.enable();
            } 
            # 2. Si ya está encendido, actúa como botón de navegación normal
            else {
                print("IPad: Navegando al Home");
                m.goHome();
            }
        }
    }, 0, 0);
  },
  addApp: func(app) {
    me.apps[app.name] = app.new(me._canvas);
    me.apps[app.name]._group.setInt("z-index", 1);
    me.apps[app.name]._group.hide();
  },
  showApp: func(name) {
    if (me.active_app) {
      me.active_app.hide();
    }
    me.active_app = me.apps[name];
    me.active_app.show();
    appNode.setValue(me.active_app.name);
  },
  goHome: func () {
    if (me.active_app) {
      me.active_app.hide();
    }
    me.active_app = me.home_app;
    me.active_app.show();
  },

  # UpdateLoop methods
  enable: func {
    startedNode.setValue(1);
    me._group.show();
    me.loop.reset();
    me.loop.enable();
    me._group.show();
    if (me.active_app) {
      me.active_app.show();
    } else {
      me.goHome();
    }
    
    print("IPad enabled");
  },
  disable: func {
    me.loop.disable();
    me._group.hide();
    if (me.active_app) {
      me.active_app.hide();
    }
    startedNode.setValue(0);
    print("IPad disabled");
  },
  reset: func {},
  update: func(dt){
    # Update time
    me.svg_keys["time.utc"].setText(sprintf("%02d",getprop(time_base~"hour"))~":"~sprintf("%02d",getprop(time_base~"minute")));
    if (me.active_app) {
      me.active_app.update(dt);
    }
  }
};

var ipad = IPad.new(window);

# ipad.showApp(MapApp.name);
# setlistener(volt_prop, func (i) {
# 	if( i.getValue() <= 9  and getprop(start_prop) != 0){
#     setprop(start_prop,0);
#     ipad.disable();
#   }else if ( i.getValue() > 9 and getprop(start_prop) == 0){
#     setprop(start_prop,1);
#     ipad.enable();
#   }
# });

window.addPlacement({"node": "blackscreen", "capture-events":1});
