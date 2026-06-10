# Map implementation
var MapApp = {
  parents: [BaseApp],
  name: "Map",
  icon: "map.png",
  maps_base: getprop("/sim/fg-home") ~ '/cache/maps',
  num_tiles: [3, 3],
  tile_size:1024,
  zoom: 14,
  svg_keys: ["groundspeed","altitude","vertspeed","track"],
  svg_file: "map.svg",

  new: func(a_canvas) {
        var obj = {parents:[MapApp]};
        print("new ", obj.name);
        obj._canvas = a_canvas;
        obj._group = a_canvas.createGroup(me.name);
        return obj;
  },
  init: func() {
    me.screen_center_x = me._canvas.get("view[0]") / 2;
    me.screen_center_y = me._canvas.get("view[1]") / 2;
    me.setupTiles();
    me._group.addEventListener("wheel", func(e) {
      print("wheel ", e.deltaY);
      me.set_zoom(e.deltaY);
    });
    me._loadSVG();
    me.marker_group = me._group.createChild('group','marker-group');
    me.marker_svg = canvas.parsesvg(me.marker_group, instrument_dir ~ "apps/" ~ "outlinedAirplane.svg");
    me.marker = me.marker_group.getElementById('airplane')
        .setTranslation(me.screen_center_x, me.screen_center_y);


    print("init Map end", me.name);
  },
  update: func(dt){
    me.updateTiles(dt);
    me.updateOverlay(dt);
  },
  setupTiles: func() {
    me.makeUrl = string.compileTemplate('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    me.makePath = string.compileTemplate(me.maps_base ~ '/tablet-cache/{z}/{x}/{y}.png');
    me.center_tile_offset = [
      (me.num_tiles[0] - 1)/2.0,
      (me.num_tiles[1] - 1)/2.0
    ];
    me.tiles = setsize([], me.num_tiles[0]);
    for(var x = 0; x < me.num_tiles[0]; x += 1){
      me.tiles[x] = setsize([], me.num_tiles[1]);
      for(var y = 0; y < me.num_tiles[1]; y += 1)
        me.tiles[x][y] = me._group.createChild("image", "map-tile");
    }
    me.last_tile = [-1,-1];
  },
    updateTiles: func(dt) {
    var lat = getprop('/position/latitude-deg') or 0;
    var lon = getprop('/position/longitude-deg') or 0;

    var n = math.pow(2, me.zoom);
    var exact_x = n * ((lon + 180) / 360);
    
    var lat_rad = lat * math.pi / 180;
    var exact_y = (1 - (math.ln(math.tan(lat_rad) + (1 / math.cos(lat_rad))) / math.pi)) / 2 * n;

    var center_tile_x = int(exact_x);
    var center_tile_y = int(exact_y);

    var ox = me.screen_center_x - (exact_x - center_tile_x) * me.tile_size - (me.center_tile_offset[0] * me.tile_size);
    var oy = me.screen_center_y - (exact_y - center_tile_y) * me.tile_size - (me.center_tile_offset[1] * me.tile_size);

    for(var x = 0; x < me.num_tiles[0]; x += 1)
    for(var y = 0; y < me.num_tiles[1]; y += 1) {
        me.tiles[x][y].setTranslation(
            int(ox + (x * me.tile_size) + 0.5), 
            int(oy + (y * me.tile_size) + 0.5)
        );
    }
  
    if(center_tile_x != me.last_tile[0] or center_tile_y != me.last_tile[1]) {
      me.last_tile = [center_tile_x, center_tile_y];

      for(var x = 0; x < me.num_tiles[0]; x += 1) {
        for(var y = 0; y < me.num_tiles[1]; y += 1) {
          
          var pos = {
            z: me.zoom,
            x: int(center_tile_x + x - me.center_tile_offset[0]),
            y: int(center_tile_y + y - me.center_tile_offset[1]),
          };

          (func {            
            var img_path = me.makePath(pos);
            var tile = me.tiles[x][y];            
            if(io.stat(img_path) == nil) {
              var img_url = me.makeUrl(pos);
              print('Requesting tile: ' ~ img_url);
              http.save(img_url, img_path)
              .done(func { tile.set("src", img_path); })
              .fail(func (r){ print('Failed to get tile ' ~ img_path ~ ' ' ~ r.status); });
            } else {
              tile.set("src", img_path);
            }
            tile.setSize(me.tile_size, me.tile_size);
          })();
        }
      }
    }
  },


  updateOverlay: func(dt) {
    
		me.elements["groundspeed"].setText(sprintf("%3d", math.round(getprop("/velocities/groundspeed-kt"))));
		me.elements["altitude"].setText(sprintf("%5d", math.round(getprop("/position/altitude-ft"))));
		me.elements["vertspeed"].setText(sprintf("%+4d", math.round(getprop("/velocities/vertical-speed-fps")*60) ));
		me.elements["track"].setText(sprintf("%3d", math.round(getprop("/orientation/track-deg")))~"°");
  },
  set_zoom: func(direction) {
    me.zoom = me.zoom + direction;
    if (me.zoom <1) me.zoom = 1;
    if (me.zoom >18) me.zoom = 18;
  }
};
ipad.addApp(MapApp);
