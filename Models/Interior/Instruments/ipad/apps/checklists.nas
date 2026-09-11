var ChecklistsApp = {
  name: "ChecklistsApp",
  icon: "checklists.png",
  svg: nil,
  svg_file: nil,
  svg_keys: [],
  elements: {},
  loaded: false,
  node: nil,

  new: func(a_canvas) {
        var obj = {parents:[BaseApp]};
        obj._canvas = a_canvas;
        obj._group = a_canvas.createGroup(obj.name);
        obj.init();
        return obj;
  },
  init: func(){
  },
  start: func() {  
  },
  update: func() {  
  },
};