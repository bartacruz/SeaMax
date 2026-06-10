var GpsMap = {
    parents: [BaseApp],
    name: "GpsMap",
    icon: "gpsmap.png",
    zoom: 14,
    RANGES: [
        {range: 500/6076.12, label: "500ft"},
        {range: 750/6076.12, label: "750ft"},
        {range: 1000/6076.12, label: "1000ft"},
        {range: 1500/6076.12, label: "1500ft"},
        {range: 2000/6076.12, label: "2000ft"},
        {range: 0.5, label: "0.5nm"},
        {range: 0.75, label: "0.75nm"},
        {range: 1, label: "1nm"},
        {range: 2, label: "2nm"},
        {range: 3, label: "3nm"},
        {range: 4, label: "4nm"},
        {range: 6, label: "6nm"},
        {range: 8, label: "8nm"},
        {range: 10, label: "10nm"},
        {range: 12, label: "12nm"},
        {range: 15, label: "15nm"},
        {range: 20, label: "20nm"},
        {range: 25, label: "25nm"},
        {range: 30, label: "30nm"},
        {range: 40, label: "40nm"},
        {range: 50, label: "50nm"},
        {range: 75, label: "75nm"},
        {range: 100, label: "100nm"},
        {range: 200, label: "200nm"},
        {range: 500, label: "500nm"},
        {range: 1000, label: "1000nm"},
        {range: 1500, label: "1500nm"},
        {range: 2000, label: "2000nm"}, 
    ],
    
    new: func(a_canvas) {
        var obj = {parents:[GpsMap]};
        print("new ", obj.name);
        obj._canvas = a_canvas;
        obj._group = a_canvas.createGroup(me.name);
        return obj;
    },
    init: func() {
        print("init Map ", me.name);
        me.range_idx=8;
        me.map = me._group.createChild("map");
        me.map.setController("Aircraft position");
        me.map.setRange(1); # TODO: implement zooming/panning via mouse/wheel here, for lack of buttons :-/
        me.map.setTranslation(
            me._canvas.get("view[0]")/2,
            me._canvas.get("view[1]")/2
        );
        me.map.addEventListener("wheel", func(e) {
            print("wheel ", e.deltaY);
            me.setRange(me.range_idx+e.deltaY);
        });
        var r = func(name,vis=1,zindex=4) return caller(0)[0];
        foreach(var type; [r('TFC',0),r('APT'),r('DME'),r('VOR'),r('NDB'),r('FIX',0),r('RTE'),r('WPT'),r('FLT'),r('WXR'),r('APS'), ] )
            me.map.addLayer(factory: canvas.SymbolLayer, type_arg: type.name,
                        visible: type.vis, priority: type.zindex,
            );
        foreach(var type; [ r('OSM',1,1) ]) {
            me.map.addLayer(factory: canvas.OverlayLayer, type_arg: type.name,
                            visible: type.vis, priority: type.zindex);
                            # style: Styles.get(type.name),
                            # options: Options.get(type.name) );
        }
    },
    setRange: func(idx) {
        if (idx < 0) idx = 0;
        if (idx >= size(me.RANGES)) idx = size(me.RANGES) -1;
        var r = me.RANGES[idx];
        me.map.setRange(r.range);
        print(r.label);
        me.range_idx = idx;
    }
};
ipad.addApp(GpsMap);
