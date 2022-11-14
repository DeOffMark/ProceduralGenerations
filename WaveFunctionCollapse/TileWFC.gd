extends Node2D

class queueSorter:
	static func sort_for_entropy(d1, d2)->bool:
		return d1["entropy"].size() < d2["entropy"].size();
export var gridDim:int= 20;
var grid:Array=[];
onready var tilemap:TileMap=$TileMap;
var queue:Array=[];
var rng:RandomNumberGenerator= RandomNumberGenerator.new();
var isPressed:bool=false; # how many times you can recurse through tiles

func _ready():
	tilemap.scale *= (640/ (32 * gridDim));
	rng.randomize();
	grid.resize(gridDim * gridDim);
	for i in range(grid.size()):
		var cell := {
			pos = Vector2(float(i % gridDim), float(i /gridDim)),
			cellId = 0,
			rotMat = 0b0000, # left, top, right, bot, 1 can intersect
			#first 0-3 are turn tiles, 4-5 are line, 6 is cross
			entropy = [0b1100, 0b0110, 0b1001, 0b0011, 0b1010, 0b0101, 0b1111], # array of all possible 
			#entropy = [0b1111], # array of all possible 
			collapsed = false, # one choice left
			checked = false  
		}
		grid[i] = cell;
	
	#pick a random point in map, every tile has equal entropy
	var randX = rng.randi() % (gridDim);
	var randY = rng.randi() % (gridDim);
	queue = [grid[randY * gridDim + randX]];
	#queue = [grid[0]];
	
	
func generate_map():
	
	if(!queue.empty()): # go trhough all the queue until it is done
		var cell = queue.front();
		var X := int(cell["pos"].x);
		var Y := int(cell["pos"].y);
		if (!cell["collapsed"]):
			if (cell["entropy"].size() > 1):
				cell["rotMat"] = cell["entropy"][rng.randi() % cell["entropy"].size()];
			else :
				cell["rotMat"] = cell["entropy"][0];
			match(cell["rotMat"]):
				0b1100, 0b0110, 0b1001, 0b0011:
					cell["cellId"] = 1;
				0b1010, 0b0101: 
					cell["cellId"] = 2;
				0b1111:
					
					cell["cellId"] = 3;
			cell["checked"] = true;
			cell["collapsed"] = true;
			grid[Y * gridDim + X] = cell;
		queue.pop_front();
		#set neighboring cells' entropies
		var minX := X-1;
		var minY := Y-1;
		var maxX := X+1;
		var maxY := Y+1;
		# check the boundary of the cell
		if (X==0):
			minX=X;
		elif(X + 1==gridDim):
			maxX=X;
			
		if (Y==0):
			minY = Y;
		elif(Y + 1==gridDim):
			maxY = Y;
		
		
		var canContinue = set_cells_entropy( grid[Y * gridDim + minX]); #west cell
		if canContinue is GDScriptFunctionState:
			canContinue = yield(canContinue, "completed");
		canContinue = set_cells_entropy( grid[minY * gridDim + X]); #north cell
		if canContinue is GDScriptFunctionState:
			canContinue = yield(canContinue, "completed");
		canContinue = set_cells_entropy( grid[Y * gridDim + maxX]); #east cell
		if canContinue is GDScriptFunctionState:
			canContinue = yield(canContinue, "completed");
		canContinue = set_cells_entropy( grid[maxY * gridDim + X]); #south cell
		if canContinue is GDScriptFunctionState:
			canContinue = yield(canContinue, "completed");
		if (!canContinue):
			set_process(false);
		#sort queue to the lowest entropy size
		queue.sort_custom(queueSorter, "sort_for_entropy")
		
	update();

func _process(delta):
	if (isPressed):
		generate_map()
	
# sets up cell's entropy by checking neighbors and choosing possible solutions from them, if none chosen return false and break the generator
func set_cells_entropy(cell:Dictionary)->bool:
	if (cell["collapsed"]):
		return true;
	var neighbors := [];
	var Xpos := int(cell["pos"].x);
	var Ypos := int(cell["pos"].y);
	
	# get neighbors matrices
	if (Xpos - 1 >= 0): # west neighbor
		if (grid[Ypos * gridDim + (Xpos - 1)]["collapsed"]):
			var mat = grid[Ypos * gridDim + (Xpos - 1)]["rotMat"] & 0b0010; # compare to east
			mat = mat << 2; # make it west
			neighbors.push_back({ "pole": 1, "mat":mat}); #west
	if (Xpos + 1 < gridDim): #east neighbor
		if (grid[Ypos * gridDim + (Xpos + 1)]["collapsed"]):
			var mat = grid[Ypos * gridDim + (Xpos + 1)]["rotMat"] & 0b1000; # get only west value
			mat = mat >> 2; # make it east
			neighbors.push_back({ "pole": 3, "mat":mat}); # east
	if (Ypos - 1 >= 0): #north neighbor
		if (grid[(Ypos - 1) * gridDim + Xpos]["collapsed"]):
			var mat = grid[(Ypos - 1) * gridDim + Xpos]["rotMat"] & 0b0001; # get only south value
			mat = mat << 2; # make it north
			neighbors.push_back({ "pole": 2, "mat":mat}); # north
	if (Ypos + 1 < gridDim): #south neighbor
		if (grid[(Ypos + 1) * gridDim + Xpos]["collapsed"]):
			var mat = grid[(Ypos + 1) * gridDim + Xpos]["rotMat"] & 0b0100; # get only noth value
			mat = mat >> 2; # make it south
			neighbors.push_back({ "pole": 4, "mat":mat}); # south
	# this is where the fun begins, use their rotMat to compare it to every possible cell variation with each id and position	
	# cell 1
	#if (neighbors.size() < 2):
		#cell["entropy"].remove(cell["entropy"].find(0b1111));
	for neighbor in neighbors:
		var i = 0;
		while (i < cell["entropy"].size()):
			if (neighbor["mat"] == 0):
				var bitdata = 1 << (4 - neighbor["pole"])
				if (cell["entropy"][i] & bitdata != 0):
					cell["entropy"].remove(i);
					i -= 1;
			else:
				if (cell["entropy"][i] & neighbor["mat"] == 0):
					cell["entropy"].remove(i);
					i -= 1;
			i += 1;
	#if entropy data is empty, contradiction occured
	if (cell["entropy"].empty()):
		print("stopped abruptly");
		print(cell)
		return false;
	else:
		cell["checked"] = true;
		queue.push_back(cell);
	return true;
	

func _draw():
	for i in grid:
		var xflip:= false;
		var yflip:= false;
		var transposed:= false;
		#calculate the rotation based on the tile id and each of id's matrix
		#90: transpose and flip x. 180: flip x and flip y. 270: transpose and flip y.
		match(i["cellId"]):
			1: # turn tile
				if (i["rotMat"] == 0b0110):
					xflip = true;
					transposed = true;
				elif (i["rotMat"] == 0b0011):
					xflip = true;
					yflip = true;
				elif (i["rotMat"] == 0b1001):
					transposed = true;
					yflip = true;
			2: # line tile
				if (i["rotMat"] == 0b0101):
					xflip = true;
					transposed = true;
			3: #cross tile
				if (i["rotMat"] == 0b1111):
					#var posSign = [0,1]	 
					xflip = true
					transposed =false
		tilemap.set_cell(i["pos"].x, i["pos"].y, i["cellId"], xflip, yflip, transposed);


func _on_Button_pressed():
	queue.clear();
	for i in range(grid.size()):
		var cell := {
			pos = Vector2(float(i % gridDim), float(i /gridDim)),
			cellId = 0,
			rotMat = 0b0000, # left, top, right, bot, 1 can intersect
			#first 0-3 are turn tiles, 4-5 are line, 6 is cross
			entropy = [0b1100, 0b0110, 0b1001, 0b0011, 0b1010, 0b0101, 0b1111], # array of all possible 
			#entropy = [0b1111], # array of all possible 
			collapsed = false, # one choice left
			checked = false  
		}
		grid[i] = cell;
	var randX = rng.randi() % (gridDim);
	var randY = rng.randi() % (gridDim);
	queue = [grid[randY * gridDim + randX]];
	isPressed = not isPressed
