var MetarApp = {
  parents: [BaseApp],
  name: "METAR",
  icon: "weather.png",
  svg_file: "metar.svg",
  
  svg_keys: ["view_list", "view_detail", "btn_back", "det_station", "det_obs1", "det_obs2", "det_obs3",'det_date','det_temp','det_wspd', 'det_wdir','det_visib','det_altim','det_cover', 'curr_temp','curr_press','curr_wind'],
  tempNode: props.globals.getNode("/environment/temperature-degc", 1),
  pressNode: props.globals.getNode("/environment/pressure-inhg", 1),
  windFromNode: props.globals.getNode("/environment/wind-from-heading-deg", 1),
  windSpeedNode: props.globals.getNode("/environment/wind-speed-kt", 1),
    new: func(a_canvas) {
        var obj = {parents:[MetarApp]};
        obj._canvas = a_canvas;
        obj._group = a_canvas.createGroup(me.name);
        return obj;
    },
    update: func(dt){
        me.elements['curr_temp'].setText( sprintf("%.1f °C", me.tempNode.getDoubleValue()));
        var phg = me.pressNode.getDoubleValue();
        var phpa = math.round(phg * 33.8639);
        me.elements['curr_press'].setText( sprintf("%.2f inHg (%d hPa)", phg, phpa));
        me.elements['curr_wind'].setText(sprintf("%3d@%dkt", me.windFromNode.getDoubleValue(), me.windSpeedNode.getDoubleValue()));
    },
    init: func() {
        me.favorites = ["SAAR", "SABE", "SAEZ"]; 
        me.current_station = "";
        me._cards_group = nil;
        me.cards = {};
        me.obs = {};
  
        me._loadSVG();
        var m = me;
        if (me.elements["btn_back"]) {
            me.elements["btn_back"].addEventListener("click", func() { m.showScreen("list"); });
        }
        me.renderCards();
        me.showScreen("list");
    },
    showScreen: func(screen_name) {
        if (screen_name == "list") {
            if (me.elements["view_list"]) me.elements["view_list"].show();
            if (me.elements["view_detail"]) me.elements["view_detail"].hide();
        } else {
            if (me.elements["view_list"]) me.elements["view_list"].hide();
            if (me.elements["view_detail"]) me.elements["view_detail"].show();
        }
    },
    addCard: func(icao, name) {
        var i =  size(me.cards);
        var card_group = me._cards_group.createChild('group',"row_" ~ i);
        var m = me;
        card_group.addEventListener("click", func() {
            m.showDetails(icao);
        });
        
        canvas.parsesvg(card_group, instrument_dir ~ "apps/metar_card.svg");

        var start_y = 150;
        var padding = 20;
        var card_height = card_group.getHeight();
        print("Card height: ", card_height);
        var calculated_y = start_y + (card_height+padding) * i;
        card_group.setTranslation(0, calculated_y);
        
        # Capturamos los IDs internos que diseñaste dentro de la tarjeta clonada
        var ids = ['icao','cat','temp','wind','altim','cover','name'];
        var card_data = {};
        foreach (var key; ids) {
            print("key",key);
            card_data[key] = card_group.getElementById(key);
            card_data[key].setText("...");
        }
        card_data.icao.setText(icao);
        card_data.name.setText(name);
        me.cards[icao] = card_data;
        if (me.obs[icao]) {
            me.updateCard(icao);
        } else {
            me.fetchMetar(icao);
        }
        return card_data;
    },
    updateCard: func(icao) {
        var card = me.cards[icao];
        var obs = me.obs[icao];
        card.cat.setText(obs.fltCat);
        var temp = obs.temp ~ '°C';
        card.temp.setText(temp);
        var wind = obs.wspd ~"kt@" ~ obs.wdir ~ '°';
        card.wind.setText(wind);
        card.altim.setText("Q"~obs.altim);
        card.cover.setText(obs.cover);
    },
    renderCards: func() {
        var m = me;
        if (me._cards_group == nil) {
            me._cards_group = me.elements["view_list"].createChild('group',"metar-cards");
        } else {
            me._cards_group.removeAllChildren();
        }
        me.cards = {};
        var apts = findAirportsWithinRange(100);
        foreach(var apt; apts){
        # for (var i = 0; i < size(me.favorites); i += 1) {
            # var icao = me.favorites[i];
            if (apt.has_metar) {
                var card = me.addCard(apt.id, apt.name);
            }
            
        }
    },
    showDetails: func(icao) {
        var obs = me.obs[icao];
        if (! obs) {
            print("No metar for " ~ icao);
            return;
        };
        var d = me.elements;
        me.elements.det_station.setText(icao);

        # Spooky way to split the observation...
        var lines = ['','',''];
        var lidx = 0;
        var max_ll = 32; # max line length
        var aux = split(" ",obs.rawOb);
        while (size(aux)> 0) {
            lines[lidx] = lines[lidx] ~ ' ' ~ aux[0];
            print(lidx,aux[0]);
            aux = subvec(aux,1);
            if (size(lines[lidx]) > max_ll) {
                lidx +=1;
            }
        }
        print("det_obs1" ~ lines[0]);
        print("det_obs2" ~ lines[1]);
        print("det_obs3" ~ lines[2]);
        d.det_obs1.setText(lines[0]);
        d.det_obs2.setText(lines[1]);
        d.det_obs3.setText(lines[2]);
        
        d.det_date.setText(obs.reportTime);
        
        d.det_temp.setText(obs.temp ~ '°C');
        #d.det_cat.setText(obs.fltCat);
        d.det_wspd.setText(obs.wspd ~"kt");
        d.det_wdir.setText(obs.wdir ~ '°');
        d.det_altim.setText(sprintf("%d",obs.altim));
        d.det_cover.setText(obs.cover);

        me.showScreen("detail");
    },
    updateObs: func(icao,obs) {
        me.obs[icao] = obs;
        if (me.cards[icao]) {
            me.updateCard(icao);
        }
    },
    fetchMetar: func(icao) {
        var m = me;
        me.current_station = icao;
        
        var url = "https://aviationweather.gov/api/data/metar?ids="~icao~"&format=json&taf=false&hours=1.5";
        var metar = nil;
        http.load(url)
            .done(func(r) {
                if (r.status == 200) {
                    var aux=sprintf("return %s",r.response);
	                var ff = call(compile,[aux],var err=[]);
	                if (size(err)) {
		                print("ERROR processing metar: ", err);
                        return;
                    }
                    metar = ff();
                    debug.dump(metar);
                    me.updateObs(icao,metar[0]);
                } else {
                    print(icao ~ ": Server error " ~ r.status);

                }
            })
            .fail(func(r) {
                print(icao ~ ": Server network error");
            });
    }
};

ipad.addApp(MetarApp);
