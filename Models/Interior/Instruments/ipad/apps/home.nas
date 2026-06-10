

var AppEntry = {
    new: func(home, app, index, x, y) {
        var obj = {parents:[AppEntry]};
        obj.home = home;
        obj.app = app;
        obj.index = index;
        obj.x = x;
        obj.y = y;
        obj.init();
        return obj;
    },
    init: func() {
        var key = "app" ~ me.index ~ ".";
        var icon_path = instrument_dir ~ "apps/" ~ me.app.icon;
        
        me._group = me.home._group.createChild('group',key ~ "group")
            .setTranslation(me.x, me.y);
        
        me.icon = me._group.createChild("image", key ~ "icon")
            .set("src", icon_path)
            .setSize(me.home.icon_size,me.home.icon_size)
            .setTranslation(0, 0)
            .show();

        var text_x = me.home.icon_size / 2;
        var text_y = me.home.icon_size + 25; # Bajamos 25px para que no se pegue al icono          
        me.label = me._group.createChild("text", key ~ "label")
            .set("font", "LiberationFonts/arial.ttf")
            .set("font-size", 32)
            .set("alignment", "center-top")
            .set("text", me.app.name)
            .setColor(0, 0, 0)
            .setTranslation(text_x, text_y)
            .show();

        var m = me;
        me._group.addEventListener("click",func(e){
            ipad.showApp(me.app.name);
        });
    }
};

var HomeApp = {
  parents: [BaseApp],
  name: "Home",
  icon: "home.png",
  svg_file: "home.svg",
  icon_size: 128,
  started: false,
  
  new: func(a_canvas) {
        var obj = {parents:[HomeApp]};
        print("new ", obj.name);
        obj._canvas = a_canvas;
        obj._group = a_canvas.createGroup(obj.name);
        obj._entries = [];
        return obj;
  },
  init: func(){
    var width = me._canvas.get("view[0]") or 1024;
    var height = me._canvas.get("view[1]") or 768;
    me.background = me._group.createChild("path", "app_background")
        .rect(0, 0, width, height)
        .set("fill", "#f0f0f0")
        .set("stroke", "none")
        .setInt("z-index", -1);   

    print("HomeApp initiated");
  },
  update: func(dt) {
    if (me.started) {
        return;
    }
    var apps  = values(ipad.apps);
    var max_cols = 4;          # Número máximo de apps por fila
    var padding_x = 40;        # Espacio horizontal entre apps
    var padding_y = 50;        # Espacio vertical entre filas de apps
    var start_x = 40;          # Margen izquierdo inicial de la pantalla
    var start_y = 128;         # Margen superior inicial de la pantalla

    for(var i=0; i < size(apps); i+=1) {
        var col = math.mod(i, max_cols);
        var row = int(i / max_cols); # 'int()' remueve los decimales para dar la fila entera
        var x = start_x + (me.icon_size + padding_x) * col;
        var y = start_y + (me.icon_size + padding_y) * row;
        var app = apps[i];
        var entry = AppEntry.new(me,app,i,x,y);
        append(me._entries,entry);
    }
    print("HomeApp started");
    me.started = true;
  }
};
ipad.home_app = HomeApp.new(ipad._canvas);
ipad.home_app.hide();
