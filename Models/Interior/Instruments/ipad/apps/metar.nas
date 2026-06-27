var MetarApp = {
  parents: [BaseApp],
  name: "METAR",
  icon: "weather.png",
  svg_file: "metar.svg",
  
  # Mapeamos los contenedores del SVG principal
  svg_keys: ["view_list", "view_detail", "btn_back", "det_station", "det_obs1", "det_obs2", "det_obs3",'det_date','det_temp','det_wspd', 'det_wdir','det_visib','det_altim','det_cover'],

    new: func(a_canvas) {
        var obj = {parents:[MetarApp]};
        obj._canvas = a_canvas;
        obj._group = a_canvas.createGroup(me.name);
        return obj;
    },

    init: func() {
        # Lista inicial de aeropuertos favoritos
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
    addCard: func(icao) {
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
        var ids = ['icao','cat','temp','wind','altim','cover'];
        var card_data = {};
        foreach (var key; ids) {
            print("key",key);
            card_data[key] = card_group.getElementById(key);
            card_data[key].setText("...");
        }
        card_data.icao.setText(icao);
        me.cards[icao] = card_data;
        if (me.obs[icao]) {
            me.updateCard(icao);
        } else {
            me.fetchMetar(icao);
        }
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
        for (var i = 0; i < size(me.favorites); i += 1) {
            var icao = me.favorites[i];
            me.addCard(icao);
            
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
        var max_ll = 35; # max line length
        var aux = split(obs.rawOb,' ');
        while (size(aux)> 0) {
            lines[lidx] = lines[lidx] ~ ' ' ~ aux[0];
            aux = subvec(aux,1);
            if (size(lines[lidx]) > max_ll) {
                lidx +=1;
            }
        }
        d.det_obs1.setText(lines[0]);
        d.det_obs2.setText(lines[1]);
        d.det_obs3.setText(lines[2]);
        
        d.det_date.setText(obs.reportTime);
        
        d.det_temp.setText(obs.temp ~ '°C');
        #d.det_cat.setText(obs.fltCat);
        d.det_wspd.setText(obs.wspd ~"kt");
        d.det_wdir.setText(obs.wdir ~ '°');
        d.det_altim.setText(obs.altim);
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
                    print("Server error " ~ response.status);
                }
            })
            .fail(func(response) {
                print("Server network error");
            });
    }
};

# Inyección asíncrona en tu iPad genérico
ipad.addApp(MetarApp);
