extends Control
const FinishOverlay = preload("res://game/finish_overlay.gd")

const Controls = preload("res://game/systems/controls.gd")
var touch_font = FontVariation.new()
var touch_bold = FontVariation.new()
var mobile = preload("res://game/mobile_hud.gd").new()
var race: Node3D
var font = SystemFont.new()
var bold = SystemFont.new()
var cream = Color("d8d3bd")
var faded = Color("8e948d")
var red = Color("c74632")
var gold = Color("bb9d54")
var clicks: Array[Dictionary] = []
var waiting_action: String = ""
var garage_index: int = 0
var hover: Vector2
var trophy_view: SubViewport
var garage_view: SubViewportContainer

func _ready() -> void:
	var ui_font_path = "res://assets/fonts/RedlineUI.ttf" if OS.has_feature("web") else "res://assets/fonts/NotoSansSC.ttf"
	font = FontVariation.new()
	font.base_font = load(ui_font_path)
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):400}
	bold = FontVariation.new()
	bold.base_font = font.base_font
	bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):600}
	touch_font = font
	touch_bold = bold
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trophy_view = preload("res://game/trophy_view.gd").new()
	add_child(trophy_view)
	garage_view = preload("res://game/garage_view.gd").new()
	add_child(garage_view)
	garage_view.visible = false

func _process(_dt: float) -> void:
	trophy_view.present(race.mode=="finished" and race.finish_presentation.champion and race.finish_presentation.age>=.85,race.finish_presentation.age)
	if race.touch.enabled and not mobile_landscape() and race.mode in ["racing","countdown"]:
		race.suspend_input()
	garage_view.visible = race.mode == "garage" and (not race.touch.enabled or mobile_landscape())
	if race.touch.enabled:
		var factor = mobile_scale()
		garage_view.position = mobile_origin()+Vector2(448,130)*factor
		garage_view.size = Vector2(488,maxf(100,mobile_height()-228))*factor
		return
	var scale_value = get_viewport_rect().size/Vector2(1440,900)
	garage_view.position = Vector2(643,190)*scale_value
	garage_view.size = Vector2(735,465)*scale_value

func enter_garage() -> void:
	for i in range(race.career.catalog.bikes.size()):
		if race.career.catalog.bikes[i].id == race.career.selected:
			garage_index = i
	garage_view.show_bike(race.career.catalog.bikes[garage_index])


func mobile_landscape() -> bool:
	return get_viewport_rect().size.x>=get_viewport_rect().size.y

func mobile_scale() -> float:
	return minf(get_viewport_rect().size.x/960.0,get_viewport_rect().size.y/432.0)

func mobile_origin() -> Vector2:
	return Vector2((get_viewport_rect().size.x-960*mobile_scale())*.5,0)

func mobile_height() -> float:
	return get_viewport_rect().size.y/mobile_scale()

func mobile_point(point: Vector2) -> Vector2:
	return (point-mobile_origin())/mobile_scale()

func control_mode_label() -> String:
	return ["Auto-detect","Touch","Keyboard / Controller"][race.career.settings.control_mode]

func cycle_control_mode() -> void:
	race.career.settings.control_mode = (race.career.settings.control_mode+1)%3
	race.apply_control_mode()
	save_settings()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = mobile_point(event.position) if race.touch.enabled else event.position/get_viewport_rect().size*Vector2(1440,900)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point = mobile_point(event.position) if race.touch.enabled else event.position/get_viewport_rect().size*Vector2(1440,900)
		for button in clicks:
			if button.rect.has_point(point):
				button.callback.call()
				accept_event()
				return
		if not race.touch.enabled and event.device!=InputEvent.DEVICE_ID_EMULATION and race.mode=="racing":
			race.primary_attack(true)
			accept_event()

func rebind(key: int) -> void:
	if key == KEY_ESCAPE:
		waiting_action = ""
		return
	if key in [KEY_ENTER,KEY_R,KEY_M,KEY_F3] or key in Controls.FIXED_KEYS:
		race.notify("That key is reserved for menus, movement, or attacks. Choose another key.",3)
		return
	var bindings: Dictionary = race.career.settings.bindings
	var old = Controls.binding_key(waiting_action,bindings)
	for action in Controls.LABELS:
		if action != waiting_action and Controls.binding_key(action,bindings) == key:
			bindings[action] = old
	bindings[waiting_action] = key
	Controls.setup(bindings)
	waiting_action = ""
	save_settings()

func quality_label() -> String:
	return race.RenderQuality.LABELS[race.career.settings.render_quality]

func cycle_quality() -> void:
	race.career.settings.render_quality = (race.career.settings.render_quality+1)%3
	race.apply_render_quality()
	save_settings()

func save_settings() -> void:
	if not race.test_mode and not race.career.save_profile():
		race.notify("Could not save settings.",3)

func text(value: String,x: float,y: float,size: int = 18,color: Color = Color("d8d3bd"),heavy: bool = false) -> void:
	var selected_font = (touch_bold if heavy else touch_font) if race.touch.enabled else (bold if heavy else font)
	draw_string(selected_font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func panel(rect: Rect2, color: Color = Color(0.035,.042,.04,.94)) -> void:
	draw_rect(rect,color)
	draw_rect(rect,Color(.5,.51,.45,.30),false,1)

func button(rect: Rect2,label: String,callback: Callable,primary: bool = false,disabled: bool = false,selected: bool = false) -> void:
	var color = Color("a63728") if primary else (Color("30382f") if selected else Color("202723"))
	if rect.has_point(hover) and not disabled:
		color = color.lightened(.15)
	if disabled:
		color = Color("191e1c")
	panel(rect,color)
	if selected and not disabled:
		draw_rect(rect,gold,false,1)
		draw_rect(Rect2(rect.position,Vector2(3,rect.size.y)),gold)
	var label_size = 21 if race.touch.enabled else 19
	var label_font = bold if primary else font
	var baseline = rect.get_center().y+(label_font.get_ascent(label_size)-label_font.get_descent(label_size))*.5
	text(label,rect.position.x+18,baseline,label_size,faded if disabled else cream,primary)
	if not disabled:
		clicks.append({"rect":rect,"callback":callback})

func bar(x: float,y: float,width: float,value: float,color: Color) -> void:
	draw_rect(Rect2(x,y,width,7),Color("303732"))
	draw_rect(Rect2(x,y,width*clampf(value/100,0,1),7),color)

func dial(center: Vector2,radius: float,value: float,maximum: float,label: String) -> void:
	draw_circle(center,radius+5,Color("747a72"))
	draw_circle(center,radius+2,Color("242925"))
	draw_circle(center,radius,Color("0a100e"))
	for i in range(25):
		var a = deg_to_rad(140+i*10.8)
		var dir = Vector2(cos(a),sin(a))
		draw_line(center+dir*(radius-5),center+dir*(radius-(14 if i%4==0 else 8)),red if i>20 else cream,2)
		if i%4==0:
			text(str(int(float(i)/24*maximum)),center.x+dir.x*(radius-28)-10,center.y+dir.y*(radius-28)+5,12,faded)
	var angle = deg_to_rad(140+clampf(value/maximum,0,1)*259)
	draw_line(center-Vector2(cos(angle),sin(angle))*9,center+Vector2(cos(angle),sin(angle))*(radius-20),red,3)
	draw_circle(center,5,cream)
	text(label,center.x-19,center.y+radius*.54,11,faded)

func _draw() -> void:
	if race != null and race.touch.enabled:
		clicks.clear()
		draw_set_transform(mobile_origin(),0,Vector2.ONE*mobile_scale())
		mobile.draw(self)
		return
	draw_set_transform(Vector2.ZERO,0,get_viewport_rect().size/Vector2(1440,900))
	clicks.clear()
	if race == null or race.player == null:
		return
	if race.mode == "loading":
		draw_loading(Vector2(1440,900))
		return
	if race.mode in ["ready","garage","settings"]:
		draw_menu()
	else:
		draw_race()
	if race.message_time>0 and race.mode in ["ready","garage","settings"]:
		panel(Rect2(480,821,880,45))
		text(race.message,500,850,17,gold)

func draw_loading(view: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO,view),Color("101713"))
	var center = view*.5
	text("REDLINE",center.x-180,center.y-74,38,cream,true)
	text(race.loading_title,center.x-180,center.y-25,26,gold)
	text("LOADING   %d%%" % int(race.loading_progress*100),center.x-180,center.y+24,18,faded)
	draw_rect(Rect2(center+Vector2(-180,48),Vector2(360,5)),Color("303b34"))
	draw_rect(Rect2(center+Vector2(-180,48),Vector2(360*race.loading_progress,5)),gold)

func draw_menu() -> void:
	draw_rect(Rect2(0,0,1440,100),Color(.03,.04,.04,.90))
	text("REDLINE",48,59,34,cream,true)
	text("REDLINE   /   CLASSIC HIGHWAY COMBAT",285,55,16,faded)
	text("$ %s" % race.career.credits,1210,54,25,gold,true)
	if race.mode == "ready":
		panel(Rect2(45,145,465,619))
		text("THE ROAD BELONGS",73,197,22,cream,true)
		text("TO NOBODY.",73,241,32,cream,true)
		text("Race through traffic and leave your rivals behind.",73,284,18,faded)
		text("SELECT A RACE",73,333,14,gold)
		for i in range(race.career.catalog.tracks.size()):
			var track: Dictionary = race.career.catalog.tracks[i]
			var locked = track.id not in race.career.unlocked
			button(Rect2(73,349+i*61,408,51),("▶ " if race.track.id == track.id else "   ")+track.name+(" · 12 km" if track.id=="interstate" else "")+(" · LOCKED" if locked else ""),func(): race.select_track(i),false,false,race.track.id == track.id)
		button(Rect2(73,548,408,61),"START RACE     ENTER",func(): race.start(),true)
		button(Rect2(73,621,197,48),"GARAGE",func(): race.menu_action("garage"))
		button(Rect2(284,621,197,48),"SETTINGS",func(): race.menu_action("settings"))
		button(Rect2(73,683,408,48),"PRACTICE · NO REWARD",func(): race.start(true))
		text("WASD / ARROWS RIDE · SPACE ATTACK · SHIFT BOOST",73,754,14,faded)
		text(race.track.subtitle,875,668,21,gold,true)
		text(race.career.bike().name,875,710,26,cream,true)
		text("%d km/h   ·   %s" % [int(race.player.top_speed*3.6),race.difficulty().name],875,744,18,cream)
		text("3D REMAKE / 90s HIGHWAY SPIRIT",48,851,14,faded)
	elif race.mode == "garage":
		draw_garage()
	else:
		draw_settings()

func draw_garage() -> void:
	draw_rect(Rect2(0,100,1440,800),Color("101713"))
	panel(Rect2(633,136,755,657))
	text("360° SHOWROOM",655,174,22,cream,true)
	panel(Rect2(45,136,570,657))
	text("GARAGE",73,190,37,cream,true)
	text("Win races, earn cash, and upgrade your ride.",73,223,18,faded)
	for i in range(3):
		var bike: Dictionary = race.career.catalog.bikes[i]
		button(Rect2(73,250+i*66,512,55),bike.name+("  /  OWNED" if bike.id in race.career.owned else "  /  $%d" % bike.price),func(): preview_bike(i),false,false,garage_index == i)
	var selected: Dictionary = race.career.catalog.bikes[garage_index]
	text(selected.description,73,480,18,faded)
	text("TOP SPEED",73,522,15)
	bar(143,512,315,selected.top_speed/65*100,gold)
	text("%d km/h" % int(selected.top_speed*3.6),474,522,17,gold)
	text("ACCELERATION",73,554,15)
	bar(143,544,315,selected.acceleration/18*100,gold)
	text("%.1f" % selected.acceleration,474,554,17,cream)
	text("HANDLING",73,586,15)
	bar(143,576,315,selected.handling/6*100,gold)
	text("%.1f" % selected.handling,474,586,17,cream)
	text("DURABILITY",73,618,15)
	bar(143,608,315,selected.durability/130*100,gold)
	text("%d" % selected.durability,474,618,17,cream)
	var owned = selected.id in race.career.owned
	button(Rect2(73,652,512,52),"RIDE THIS BIKE" if owned else "BUY  $%d" % selected.price,func(): purchase_bike(),true,not owned and race.career.credits<int(selected.price))
	button(Rect2(73,722,512,44),"← BACK TO RACES",func(): race.menu_action("home"))
	text(selected.name,660,711,32,cream,true)
	text(selected.body_style,660,744,17,gold)
	text("DRAG TO ROTATE / VERTICAL DRAG TO PITCH · SCROLL TO ZOOM",659,774,15,faded)
	button(Rect2(1125,665,235,47),"AUTO ROTATE: "+("ON" if garage_view.auto_rotate else "OFF"),func(): garage_view.auto_rotate=not garage_view.auto_rotate)
	button(Rect2(1125,727,235,42),"RESET VIEW",func(): garage_view.reset_view())

func preview_bike(index: int) -> void:
	garage_index = index
	garage_view.show_bike(race.career.catalog.bikes[index])
	race.sound.click()

func purchase_bike() -> void:
	var selected: Dictionary = race.career.catalog.bikes[garage_index]
	if selected.id in race.career.owned:
		race.career.selected = selected.id
	elif not race.career.buy(selected.id):
		return
	save_settings()
	race.reset_race()
	race.mode = "garage"
	race.notify("Selected "+selected.name)

func draw_settings() -> void:
	panel(Rect2(45,133,1350,670))
	text("DRIVING SETUP",75,186,35,cream,true)
	text("KEYBOARD / CONTROLLER · SETTINGS SAVE AUTOMATICALLY",75,217,17,faded)
	var settings = race.career.settings
	button(Rect2(75,249,400,50),"DIFFICULTY: "+race.difficulty().name,func(): settings.difficulty=(int(settings.difficulty)+1)%3; save_settings())
	button(Rect2(75,312,400,50),"SFX VOLUME: %d%%" % (settings.volume*100),func(): settings.volume=0.0 if settings.volume>=.99 else minf(1,settings.volume+.25); save_settings())
	button(Rect2(75,375,400,50),"CAMERA SHAKE: %d%%" % (settings.shake*100),func(): settings.shake=0.0 if settings.shake>.9 else settings.shake+.5; save_settings())
	button(Rect2(75,438,400,50),"OFF-ROAD ASSIST: "+("ON" if settings.assist else "OFF"),func(): settings.assist=not settings.assist; race.player.assist=settings.assist; save_settings())
	button(Rect2(75,501,400,50),"LARGE SPEED DISPLAY: "+("ON" if settings.large_hud else "OFF"),func(): settings.large_hud=not settings.large_hud; save_settings())
	button(Rect2(75,564,400,42),"MUSIC: %d%%" % (settings.music*100),func(): settings.music=0.0 if settings.music>=.99 else minf(1,settings.music+.25); save_settings())
	button(Rect2(75,617,400,42),"GRAPHICS: "+quality_label(),func(): cycle_quality())
	text("CONTROLLER: RT THROTTLE / LT BRAKE / LEFT STICK STEER",75,686,16,cream)
	text("X PUNCH / A KICK / Y WEAPON / B BLOCK / RB BOOST",535,640,17,cream)
	text("L3 DODGE / R3 DISARM / LB CRUISE / START PAUSE",535,675,16,faded)
	button(Rect2(75,710,620,60),"INPUT: "+control_mode_label(),func(): cycle_control_mode())
	text("Music: Umplix (CC0) · Engines: dklon (CC-BY-SA 3.0)",75,797,13,faded)
	var actions = Controls.LABELS.keys()
	for i in range(actions.size()):
		var action: String = actions[i]
		var col = i/6
		var row = i%6
		button(Rect2(535+col*405,249+row*60,375,50),Controls.LABELS[action]+"     "+("PRESS A KEY…" if waiting_action == action else Controls.key_label(action,settings.bindings)),func(): waiting_action=action)
	button(Rect2(1028,722,332,48),"SAVE & RETURN",func(): save_settings(); race.mode="ready")

func draw_race() -> void:
	var p = race.player
	# The classic race information belongs on the instrument panel, keeping the road open.
	panel(Rect2(0,730,1440,170),Color("101713"))
	draw_line(Vector2(0,732),Vector2(1440,732),Color("717567"),3)
	text("REDLINE",28,766,22,cream,true)
	text("RIDER",29,804,13,faded)
	bar(97,796,190,p.health,Color("789463"))
	text("BIKE",29,835,13,faded)
	bar(97,827,190,p.durability/p.max_durability*100,gold)
	text("BALANCE",29,866,13,faded)
	bar(97,858,190,p.stability,red if p.stability<40 else Color("758e82"))
	dial(Vector2(397,817),67,p.speed*3.6,240,"KM/H")
	text("%03d" % int(p.speed*3.6),490,830,62 if race.career.settings.large_hud else 49,cream,true)
	text("KM/H",495,855,13,faded)
	text("GEAR",635,779,12,faded)
	text(str(race.sound.gear),648,823,35,gold,true)
	text("BURST",635,851,12,faded)
	bar(635,862,86,race.nitro,gold)
	text("POSITION",770,778,13,faded)
	text("%d / 6" % race.rank,770,827,41,cream,true)
	text("%02d:%05.2f" % [int(race.elapsed)/60,fmod(race.elapsed,60)],770,859,19,faded)
	text("%04d / %d M" % [int(p.distance),int(race.track.length)],951,778,17,cream)
	bar(951,794,208,p.distance/float(race.track.length)*100,gold)
	text("%d KO   /   %d ENVIRONMENTAL" % [p.knockouts,p.environment_kos],951,831,17,cream)
	text("%d HIT COMBO" % p.combo,951,862,15,gold)
	draw_mini_map(Vector2(1300,818))
	panel(Rect2(40,570,270,116))
	text(race.Combat.WEAPONS[p.weapon].name+"  /  "+("BLOCKING" if p.guarding else ("COUNTER!" if p.counter_time>0 else "READY")),58,601,19,gold,true)
	text("STAMINA",58,632,14,faded)
	bar(108,623,177,p.stamina,Color("758e82"))
	text("DODGE %.1f s" % p.dodge_cooldown if p.dodge_cooldown>0 else "LEFT CLICK AUTO-ATTACK / DISARM · I DODGE",58,663,14,faded)
	if race.endurance.index>=0:
		panel(Rect2(465,107,340,36),Color(.02,.035,.03,.7))
		text(race.endurance.stages[race.endurance.index].name,480,132,21,gold,true)
	if p.condition_power()<.98: text("BIKE DAMAGE · POWER REDUCED",97,858,15,red,true)
	if race.police.active or race.heat>15:
		panel(Rect2(1110,28,300,72))
		text("POLICE PURSUIT" if race.police.active else "HEAT",1127,57,17,red if race.police.active else gold,true)
		bar(1127,76,264,race.heat,red)
	var opponent = race.nearest_target(18)
	if opponent>=0 and race.mode == "racing":
		var r = race.racers[opponent]
		panel(Rect2(40,30,264,81))
		text(r.name+(("  /  DISARMING" if r.stealing else "  /  WINDING UP") if (r.windup>0 and r.combat_target==-1) else "  /  "+race.RacerAI.intent_label(r)),58,60,18,red if (r.windup>0 and r.combat_target==-1) else cream,true)
		bar(58,82,226,r.hp,red)
	if race.tutorial and race.mode == "racing":
		var lessons = ["01  HOLD THROTTLE TO REACH 70 KM/H","02  STEER LEFT OR RIGHT TO CHANGE LANES","03  GET CLOSE AND LAND A HIT WITH J / K / L","04  HOLD SHIFT TO CHARGE, THEN RELEASE TO BOOST","TUTORIAL COMPLETE · RACE TO THE FINISH; YOU CAN'T WRECK IN PRACTICE"]
		panel(Rect2(415,30,610,59))
		text(lessons[race.lesson],436,68,20,gold)
	if race.flash>0:
		draw_rect(Rect2(0,0,1440,730),Color(.65,.12,.05,race.flash*.3))
	if race.debug_hud:
		panel(Rect2(25,144,350,104))
		text("FPS %d   DRAW %d" % [Engine.get_frames_per_second(),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)],41,175,17)
		text("%.0f triangles" % Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),41,204,17)
		text("F3 HIDE · PHYSICS 60 HZ",41,231,14,faded)
	if race.mode in ["paused","finished","countdown"]:
		draw_overlay()

const MAP_BEHIND = 30.0
const MAP_AHEAD = 258.0

func mini_map_position(center: Vector2, distance: float, lane: float = 0.0) -> Vector2:
	var relative = race.route.point(distance)-race.route.point(race.player.distance)
	return center+Vector2(relative.x*.16+lane*2,40-(distance-race.player.distance)/3)

func mini_map_riders(center: Vector2) -> Array[Vector2]:
	var markers: Array[Vector2] = []
	for rider in race.racers:
		var gap: float = rider.s-race.player.distance
		if gap>=-MAP_BEHIND and gap<=MAP_AHEAD:
			markers.append(mini_map_position(center,rider.s,rider.lane))
	return markers

func draw_mini_map(center: Vector2) -> void:
	var p = race.player
	var prev = Vector2.ZERO
	for i in range(25):
		var s = clampf(p.distance-MAP_BEHIND+i*(MAP_BEHIND+MAP_AHEAD)/24,0,float(race.track.length))
		var pos = mini_map_position(center,s)
		if i>0:
			draw_line(prev,pos,Color("657268"),5)
		prev = pos
	for pos in mini_map_riders(center):
		draw_circle(pos,3.5,Color("101713"))
		draw_circle(pos,2.5,Color("e0c778"))
	var player_pos = mini_map_position(center,p.distance,p.lane)
	draw_circle(player_pos,5,Color("101713"))
	draw_circle(player_pos,4,red)
	text("ROUTE",center.x-24,center.y+65,11,faded)

func draw_overlay() -> void:
	if race.mode=="finished":
		FinishOverlay.draw(self,1440,900)
		return
	if race.mode == "countdown":
		# Keep the overhead starting lamps unobscured throughout the countdown.
		panel(Rect2(580,475,280,150))
		text(str(int(ceil(race.countdown))),695,555,72,gold,true)
	text("READY TO THROTTLE  /  RT OR W",606,601,19)
		return
	draw_rect(Rect2(0,0,1440,730),Color(.02,.03,.025,.6))
	panel(Rect2(410,150,620,505))
	text("PAUSED",450,221,49,cream,true)
	text("RACE PAUSED",450,269,22,gold)
	text("WASD / ↑ ↓ ← → TO RIDE",450,330,21)
	text("LEFT CLICK / SPACE TO ATTACK; BRAKING CANCELS CRUISE CONTROL.",450,375,19,faded)
	button(Rect2(450,480,540,56),"RESUME RACE / ESC",func(): race.menu_action("resume"),true)
	button(Rect2(450,552,540,51),"BACK TO RACES / GARAGE",func(): race.menu_action("home"))
