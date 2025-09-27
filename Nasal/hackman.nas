var last_egt = 0;
var mult = -1;
var step = 0.02;

var hack_it = func() {
    if ( ! getprop("controls/engines/engine/hackman")) {
        return;
    }
    var egt = getprop("engines/engine/egt-degf");
    var mixture = getprop("controls/engines/engine/mixture");
    var new_mix = mixture + step * mult;
    setprop("controls/engines/engine/mixture",new_mix);
    print("last = ",last_egt, " actual = ",egt);
    if (egt > last_egt) {
        settimer(func(){
            hackman.hack_it();
        }, 3, 0);
    }
    last_egt = egt;
}
var listener = setlistener("controls/engines/engine/hackman", func(n){
    hackman.hack_it();
}, 0, 0);
print("Hackman ready");
