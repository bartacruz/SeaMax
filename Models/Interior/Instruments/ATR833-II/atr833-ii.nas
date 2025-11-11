# Simulation of the F.U.N.K.E. ATR833-II COM by Bea Wolf (D-ECHO) based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

# Updated by:
# Julio Santa Cruz (barta) Memory and last frequency management.

#Information based on manual https://www.funkeavionics.de/wp-content/uploads/2020/07/01.143.010.71d_ATR833-II_OI-Rev1.05_180425_WEB-PRINT.pdf
#######################################

var ATR833_main = nil;
var ATR833_start = nil;
var ATR833_display = nil;

var volts = props.globals.getNode("/systems/electrical/outputs/comm", 1);

var instrument_dir = "Aircraft/SeaMax/Models/Interior/Instruments/ATR833-II/";
var comm = props.globals.getNode("/instrumentation/comm[0]");
var base = props.globals.initNode("/instrumentation/atr833-ii");

var cursor_sel = base.initNode("cursor-selection", 0, "INT"); # currently only manipulates the standby frequency, 0 = off, 1 = mhz, 2 = 100 khz, 3 = 1 khz
setlistener( cursor_sel, func{ ATR833_main.update_cursor() } );

var current_sel = base.initNode("current-selection", 0, "INT");	# ref p. 17:	0 = VOL, 1 = SQL, 2 = VOX, 3 = INT, 4 = STL, 5 = STR, 6 = EXT, 7 = BRT
var setting_labels = [ "VOL", "SQL", "VOX", "INT", "STL", "STR", "EXT", "BRT" ];
var setting_values = [
	comm.initNode("volume", 0.5, "DOUBLE"),
	comm.initNode("squelch", 5, "INT"),
	comm.initNode("vox", 5, "INT"),
	comm.initNode("intercom-volume", 5, "INT"),
	comm.initNode("sidetone-volume[0]", 5, "INT"),
	comm.initNode("sidetone-volume[1]", 5, "INT"),
	comm.initNode("external-volume", 5, "INT"),
	comm.initNode("brightness", 5, "INT"),
];
var setting_listeners = [];

var tx = comm.getNode("ptt", 1);
var rx = comm.getNode("rx", 1);

var freq_act = comm.getNode("frequencies/selected-mhz", 1);
var freq_sby = comm.getNode("frequencies/standby-mhz",  1);

var time = props.globals.getNode("/sim/time/elapsed-sec", 1);

var state = base.initNode("state",0,"INT");	# 0 = off, 1 = starting, 2 = on
var mode  = base.initNode("mode",0,"INT");	# 0 = normal, 1 = memory freq, 2 = last freq,
var memory_index  = base.initNode("memory-idx",0,"INT");

var memory_freq  = base.initNode("memory-freq",0,"DOUBLE");
var last_index  = base.initNode("last-idx",0,"INT");
var last_freq  = base.initNode("last-freq",0,"DOUBLE");
var last_input = base.initNode("last-input",0,"DOUBLE");
# Initialize storage
var storage = base.initNode("storage");
var memory_save_index  = storage.initNode("memory-save-idx",0,"INT");
for (var i=0; i<20 ; i +=1 ) {
	var m = storage.getChild("memory",i,1);
	m.initNode("freq",118.0,"DOUBLE");
	m.initNode("label","","STRING");
	m.initNode("set",0,"BOOL");
	if (m.getNode("set").getBoolValue()) {
		print("selected for persistence: ",m.getPath());
		aircraft.data.add(m);
		aircraft.data.save();
	}
}




var canvas_ATR833_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			if( family == "OLED_5x14" ){
				return "OLED-5_14.ttf";
			} else {
				return "OLED-10_14.ttf";
			}
		};

		
		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		 var svg_keys = me.getKeys();
		 
		foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var clip_el = canvas_group.getElementById(key ~ "_clip");
			if (clip_el != nil) {
				clip_el.setVisible(0);
				var tran_rect = clip_el.getTransformedBounds();
				var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
				tran_rect[1], # 0 ys
				tran_rect[2], # 1 xe
				tran_rect[3], # 2 ye
				tran_rect[0]); #3 xs
				#   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
				me[key].set("clip", clip_rect);
				me[key].set("clip-frame", canvas.Element.PARENT);
			}
		}

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		
		if ( volts.getDoubleValue() > 10 ){
			if( state.getIntValue() == 1 ) {
				ATR833_start.page.show();
				ATR833_main.page.hide();
			} elsif( state.getIntValue() == 2 ){
				ATR833_start.page.hide();
				ATR833_main.page.show();
			} else {
				ATR833_start.page.hide();
				ATR833_main.page.hide();
			}
		} else {
			ATR833_start.page.hide();
			ATR833_main.page.hide();
			if( io_btn_start_time != nil ){ io_btn_start_time = nil; }
		}
	},
};

var canvas_ATR833_start = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_ATR833_start , canvas_ATR833_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [];
	},
};
	
	
var canvas_ATR833_main = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_ATR833_main , canvas_ATR833_base] };
		m.init(canvas_group, file);
	
		return m;
	},
	getKeys: func() {
		return ["freq.act", "freq.sby", "act.flag", "setting_label", "setting_value", "cursor.sby.mhz", "cursor.sby.100khz", "cursor.sby.1khz","freq.name"];
	},
	clean: func(){
		if 	(last_input.getDoubleValue() == 0) return;
		var time_diff = time.getDoubleValue() -  last_input.getDoubleValue();
		if (time_diff > 10) {
			print("cleaning display", time_diff);
			memory_index.setIntValue(0);
			memory_save_index.setIntValue(0);
			last_index.setIntValue(0);
			current_sel.setIntValue(0);
			mode.setIntValue(0); # last, bc it triggers an update
			last_input.setDoubleValue(0);
		}
	},
	update_act_freq: func() {
		if (state.getIntValue() < 1) {
			return;
		}
		me["freq.act"].setText( sprintf("%6.3f", freq_act.getDoubleValue() ) );
		var lasts = size(storage.getChildren("last"));
		lasts = math.min(lasts,9);
		print("lasts ",lasts);
		for (var i = lasts;i>0;i -= 1) {
			var src = storage.getChild("last",i-1);
			var dest = storage.getChild("last",i,1);
			props.copy(src,dest);
			aircraft.data.add(dest);
		}
		var m = storage.getChild("last",0,1);
		m.initNode("freq",0,"DOUBLE").setDoubleValue(freq_act.getDoubleValue());
		mode.setIntValue(0);
		aircraft.data.add(m);
	},
	update_sby_freq: func() {
		me["freq.sby"].setText( sprintf("%6.3f", freq_sby.getDoubleValue() ) );
		mode.setIntValue(0);
	},
	update_settings: func() {
		# Settings Label
		if (mode.getIntValue() > 0) {
			return;
		}
		me["setting_value"].show();
		var cs = current_sel.getIntValue();
		me["setting_label"].setText( setting_labels[ cs ] );
		if( cs == 0 ){
			me["setting_value"].setText( sprintf("%2d", math.round( setting_values[0].getDoubleValue() * 20 ) ) );
		} else {
			me["setting_value"].setText( sprintf("%2d", setting_values[ cs ].getIntValue() ) );
		}
		me["freq.name"].hide();
	},
	update_mem: func() {
		#cursor_sel.setIntValue(0);
		me["setting_label"].setText("MEM");
		me["setting_value"].setText( sprintf("%2d",memory_index.getIntValue() + 1 ) );
		me["setting_value"].show();
		var record = storage.getChild("memory",memory_index.getIntValue());
		memory_freq.setDoubleValue(record.getNode("freq").getDoubleValue());
		me["freq.sby"].setText( sprintf("%6.3f", memory_freq.getDoubleValue() ) );
		me["freq.name"].setText(record.getNode("label").getValue());
		me["freq.name"].show();
	},
	save_mem: func() {
		me["freq.name"].show();
		me["setting_value"].hide();
		me["setting_label"].setText("MEM");
		
		if (mode.getIntValue() == 4) {
			me["freq.name"].setText(sprintf("     %2d",memory_save_index.getIntValue()+1));
			var record = storage.getChild("memory",memory_save_index.getIntValue());
			record.getNode("freq").setDoubleValue(freq_sby.getDoubleValue());
			record.getNode("label").setValue("STORED");
			record.getNode("set").setBoolValue(1);
			aircraft.data.add(record);
			aircraft.data.save();
		} else {
			me["freq.name"].setText(sprintf("SAVE %2d",memory_save_index.getIntValue()+1));
		}
	},
	update_last: func() {
		if (state.getIntValue() < 1) {
			return;
		}
		#cursor_sel.setIntValue(0);
		me["setting_label"].setText("LST");
		me["setting_value"].setText( sprintf("%2d",last_index.getIntValue() + 1 ) );
		var record = storage.getChild("last",last_index);
		last_freq.setDoubleValue(record.getNode("freq").getDoubleValue());
		# me["freq.name"].setText(record.getNode("label").getValue());
		# me["freq.name"].show();
		me["freq.sby"].setText( sprintf("%6.3f", record.getNode("freq").getDoubleValue() ) );
	},
	update_cursor: func() {
		var cursor_pos = cursor_sel.getIntValue();
		if( cursor_pos == 0 ){
			me["cursor.sby.mhz"].hide();
			me["cursor.sby.100khz"].hide();
			me["cursor.sby.1khz"].hide();
		} elsif( cursor_pos == 1 ){
			me["cursor.sby.mhz"].show();
			me["cursor.sby.100khz"].hide();
			me["cursor.sby.1khz"].hide();
		} elsif( cursor_pos == 2 ){
			me["cursor.sby.mhz"].hide();
			me["cursor.sby.100khz"].show();
			me["cursor.sby.1khz"].hide();
		} elsif( cursor_pos == 3 ){
			me["cursor.sby.mhz"].hide();
			me["cursor.sby.100khz"].hide();
			me["cursor.sby.1khz"].show();
		}
	},
	update_act_flag: func() {
		# TX/RX flag
		if( tx.getBoolValue() ){
			me["act.flag"].setText("TX");
		} elsif( rx.getBoolValue() ){
			me["act.flag"].setText("RX");
		} else {
			me["act.flag"].setText("");
		}
	},
	update: func() {
		me.update_act_freq();
		me.update_sby_freq();
		if (mode.getIntValue() == 0) me.update_settings();
		if (mode.getIntValue() == 1) me.update_mem();
		if (mode.getIntValue() == 2) me.update_last();
		me.update_cursor();
		me.update_act_flag();
		print("update");
	},
};
var swap_memory = func() {
	var val = memory_freq.getDoubleValue();
	var af = freq_act.getDoubleValue();
	freq_sby.setDoubleValue(af);
	freq_act.setDoubleValue(val);
}
var swap_last = func() {
	var val = last_freq.getDoubleValue();
	var af = freq_act.getDoubleValue();
	freq_sby.setDoubleValue(af);
	freq_act.setDoubleValue(val);
}
var io_btn_start_time = nil;

var io_btn = func( a ){
	if( a and volts.getDoubleValue() >= 10 ){
		io_btn_start_time = time.getDoubleValue();
		if( state.getIntValue() == 0 ){
			settimer( func io_btn(0), 0.55 );
		} else {
			settimer( func io_btn(0), 3.05 );
		}
	} else {
		if( io_btn_start_time == nil ){ return; }
		var time_diff = time.getDoubleValue() - io_btn_start_time;
		if( state.getIntValue() == 0 and time_diff > 0.5 ){
			state.setValue(1);
			settimer( func{ state.setValue(2)}, 2.0 );
		} elsif( state.getIntValue() > 0 and time_diff > 3.0 ){
			state.setValue(0);
		}
		io_btn_start_time = nil;
	}
}

var base_updater = maketimer( 0.5, canvas_ATR833_base.update );
base_updater.simulatedTime = 1;

var clean_timer=nil;
var ls = setlistener("sim/signals/fdm-initialized", func {
	removelistener( ls );
	ATR833_display = canvas.new({
		"name": "atr833_ii",
		"size": [256, 128],	# twice the real resolution is necessary to render the font well
		"view": [128, 64],
		"mipmapping": 1
	});
	ATR833_display.addPlacement({"node": "atr833.display"});
	var groupMain = ATR833_display.createGroup();
	var groupStart = ATR833_display.createGroup();



	ATR833_start = canvas_ATR833_start.new(groupStart, instrument_dir~"atr833-ii-start.svg");
	ATR833_main = canvas_ATR833_main.new(groupMain, instrument_dir~"atr833-ii-main.svg");
	clean_timer = maketimer(1,canvas_ATR833_main,canvas_ATR833_main.clean);
	clean_timer.start();
	
	foreach( var el; setting_values ){
		append(setting_listeners, setlistener( el, func{ ATR833_main.update_settings(); } ));
	}
	setlistener( current_sel, func{ ATR833_main.update_settings(); } );
	setlistener(mode, func {
		if (mode.getIntValue() == 0) {
			memory_index.setIntValue(0);
			memory_save_index.setIntValue(0);
			last_index.setIntValue(0);
			ATR833_main.update_settings();
			ATR833_main.update_sby_freq();

		}
		if (mode.getIntValue() == 1) ATR833_main.update_mem();
		if (mode.getIntValue() == 2) ATR833_main.update_last();
		if (mode.getIntValue() == 3) ATR833_main.save_mem();
		if (mode.getIntValue() == 4) ATR833_main.save_mem();

	});
	setlistener( memory_index, func{ ATR833_main.update_mem(); } );
	setlistener( memory_save_index, func{ ATR833_main.save_mem(); } );
	setlistener( last_index, func{ ATR833_main.update_last(); } );
	setlistener( tx, func{ ATR833_main.update_act_flag(); } );
	setlistener( rx, func{ ATR833_main.update_act_flag(); } );
	setlistener( freq_act, func{ ATR833_main.update_act_freq(); } );
	setlistener( freq_sby, func{ ATR833_main.update_sby_freq(); } );
	
	ATR833_main.update();
	base_updater.start();
});
