#include "umf.lua"
local config = OptionsKeys {
    key = {
        roton = {"string", "r"},
        nextera = {"string", "g"},
        axis = {"string", "rmb"},
        color = {"string", "e"},
        resetrot = {"string", "mmb"},
        autofill = {"string", "x"},
    }
}

function init()
    tool_name = "realisticera"
	RegisterTool(tool_name, "Realistic ERA", "vox/tablet.vox", 2)
	SetBool("game.tool." .. tool_name ..".enabled", true)
	sound_place = LoadSound("metal/hit-s0.ogg")	
	rotatemod = false
	selectedera = 1
	selectedcolor = 1	
	rotation = 0
	rotationy = 0
	rotationz = 0	
	spawnready = true
	autofill_msg = ""
	autofill_cd = 0
	
	rot = 1
end

function tick(dt)

	handle_input(dt)

end


function EraXmlForSelection()
	local folder = "MOD/xml"
	if selectedcolor == 2 then folder = "MOD/xml desert" end
	return folder .. "/" .. (ERA_NAMES[selectedera] or "kontakt1") .. ".xml"
end

function EraSpawnOne(xml, pos, rot)
	local h = Spawn(xml, Transform(pos, rot), false, true)[1]
	if h ~= nil and h ~= 0 then
		PlaySound(sound_place, pos)
	end
	return h
end

-- Auto-cover: flood-fill ERA blocks over the aimed surface (same body, coplanar).
-- Returns number of blocks placed. Manual placement logic untouched.
function EraAutoCover()
	local headTrans = GetCameraTransform()
	local lookDir = TransformToParentVec(headTrans, Vec(0, 0, -1))
	QueryRejectBody(okidokiera)
	QueryRejectAnimator(GetPlayerAnimator())
	local hit, dist, normal, shape = QueryRaycast(headTrans.pos, lookDir, 30)
	if not hit or shape == 0 then
		return 0, "no surface aimed"
	end
	if HasTag(shape, "era") then
		return 0, "aim bare armor, not ERA"
	end
	local seedBody = GetShapeBody(shape)
	if seedBody == 0 then
		return 0, "no surface aimed"
	end
	local n = VecNormalize(normal)
	local up = Vec(0, 1, 0)
	if math.abs(VecDot(n, up)) > 0.95 then up = Vec(1, 0, 0) end
	local u = VecNormalize(VecCross(n, up))
	local v = VecCross(n, u)
	-- tile footprint measured from the live outline ghost (matches selected ERA type)
	local stepU, stepV = 0.35, 0.35
	if okidokiera ~= nil and okidokiera ~= 0 and IsHandleValid(okidokiera) then
		local mn, mx = GetBodyBounds(okidokiera)
		local sz = VecSub(mx, mn)
		stepU = math.abs(VecDot(sz, u)) + 0.03
		stepV = math.abs(VecDot(sz, v)) + 0.03
		if stepU < 0.12 then stepU = 0.35 end
		if stepV < 0.12 then stepV = 0.35 end
	end
	local seedPos = VecAdd(headTrans.pos, VecScale(lookDir, dist))
	local xml = EraXmlForSelection()
	local placed = 0
	local visited = {["0,0"] = true}
	local queue = {{0, 0}}
	local head = 1
	while head <= #queue and placed < 80 do
		local cell = queue[head]
		head = head + 1
		local center = VecAdd(seedPos, VecAdd(VecScale(u, cell[1] * stepU), VecScale(v, cell[2] * stepV)))
		local from = VecAdd(center, VecScale(n, 0.6))
		QueryRequire("physical")
		QueryRejectBody(okidokiera)
		QueryRejectAnimator(GetPlayerAnimator())
		local h2, d2, n2, s2 = QueryRaycast(from, VecScale(n, -1), 1.6)
		if h2 and s2 ~= 0 and not HasTag(s2, "era") and GetShapeBody(s2) == seedBody then
			local nn = VecNormalize(n2)
			if VecDot(nn, n) > 0.85 then
				local hp = VecAdd(from, VecScale(VecScale(n, -1), d2))
				EraSpawnOne(xml, hp, QuatRotateQuat(QuatLookAt(Vec(), nn), QuatEuler(rotation, -90 + rotationz, rotationy)))
				placed = placed + 1
				for _, nb in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
					local k = (cell[1] + nb[1]) .. "," .. (cell[2] + nb[2])
					if not visited[k] then
						visited[k] = true
						queue[#queue + 1] = {cell[1] + nb[1], cell[2] + nb[2]}
					end
				end
			end
		end
	end
	if placed == 0 then
		return 0, "no coplanar surface found"
	end
	return placed, "covered " .. placed .. " blocks"
end


function handle_input(dt)
	-- Shortcuts for camera
	ERA_NAMES = ERA_NAMES or {"kontakt1","kontakt5","relikt","relikt bag","tusk","busk","nozh","karkas"}

	
	-- When holding the camera tool
	if GetString("game.player.tool") == tool_name and GetBool("game.player.canusetool") then
	    okidokiera = FindBody("okidokiera",true)	

		if rotatemod == false and InputPressed(config.key.roton) then
			rotatemod = true
		elseif rotatemod == true and InputPressed(config.key.roton) then
			rotatemod = false
		end

		if InputPressed(config.key.axis) and rotatemod == true then
			rot = rot + 1
		end		
		if rot > 3 then 
			rot = 1
		end		

		if InputPressed(config.key.color) then
			selectedcolor = selectedcolor + 1
		end		
		if selectedcolor > 2 then 
			selectedcolor = 1
		end	


		if rotatemod == true then
			SetBool("game.input.locktool", true)
			if rot == 1 then 
				rotation = rotation + InputValue("mousewheel") * 4
			elseif rot ==2 then
				rotationy = rotationy + InputValue("mousewheel") * 4
			elseif rot ==3 then
				rotationz = rotationz + InputValue("mousewheel") * 4				
			end
			
			if rotation > 360 then
				rotation = 0
			elseif rotation < 0 then
				rotation = 360
			end
		end

		
	   	if InputPressed(config.key.resetrot) then
			rotation = 0
			rotationy = 0
		    rotationz = 0			
		end					
		
		
	   	if InputPressed(config.key.nextera) then
			Delete(okidokiera)
			spawnready = true
		    selectedera = selectedera + 1
			if selectedera > 8 then selectedera = 1 end
		end				

		local headTrans = GetCameraTransform()
		local lookDir = TransformToParentVec(headTrans, Vec(0, 0, -1))
		local maxDist = 5
		QueryRejectBody(okidokiera)
		local hit, dist, normal, shape = QueryRaycast(headTrans.pos, lookDir, maxDist)			
	
		hit_pos = VecAdd(headTrans.pos, VecScale(lookDir, dist))
		local offset = 0.05
				 		
		SetBodyTransform(okidokiera,Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy)))) --QuatRotateQuat(headTrans.rot, QuatEuler(30, 0, 0))
		SetBodyDynamic(okidokiera,false)			
	
		if spawnready == true then
			if selectedera == 1 then
				Spawn("MOD/xml/kontakt1 line.xml", Transform(hit_pos))	
				spawnready = false
			elseif selectedera == 2 then
				Spawn("MOD/xml/kontakt5 line.xml", Transform(hit_pos))	
				spawnready = false				
			elseif selectedera == 3 then
				Spawn("MOD/xml/relikt line.xml", Transform(hit_pos))	
				spawnready = false						
			elseif selectedera == 4 then
				Spawn("MOD/xml/relikt bag line.xml", Transform(hit_pos))	
				spawnready = false		
			elseif selectedera == 5 then
				Spawn("MOD/xml/tusk line.xml", Transform(hit_pos))	
				spawnready = false	
			elseif selectedera == 6 then
				Spawn("MOD/xml/busk line.xml", Transform(hit_pos))	
				spawnready = false	
			elseif selectedera == 7 then
				Spawn("MOD/xml/nozh line.xml", Transform(hit_pos))	
				spawnready = false	
			elseif selectedera == 8 then
				Spawn("MOD/xml/karkas line.xml", Transform(hit_pos))	
				spawnready = false					
			end
		end		

	
	if autofill_cd > 0 then autofill_cd = autofill_cd - dt end
		if InputPressed(config.key.autofill) and autofill_cd <= 0 then
			local c, m = EraAutoCover()
			autofill_msg = m
			autofill_cd = 0.6
			DebugPrint("[era] autofill: " .. m)
		end

		if InputPressed("lmb") and hit then		
			PlaySound(sound_place, hit_pos)	
		  if selectedcolor == 1 then		
			if selectedera == 1 then
				Spawn("MOD/xml/kontakt1.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 2 then
				Spawn("MOD/xml/kontakt5.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 3 then
				Spawn("MOD/xml/relikt.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 4 then
				Spawn("MOD/xml/relikt bag.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 5 then
				Spawn("MOD/xml/tusk.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 6 then
				Spawn("MOD/xml/busk.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 7 then
				Spawn("MOD/xml/nozh.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 8 then
				Spawn("MOD/xml/karkas.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)				
			end	
		  elseif selectedcolor == 2 then	
			if selectedera == 1 then
				Spawn("MOD/xml desert/kontakt1.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 2 then
				Spawn("MOD/xml desert/kontakt5.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 3 then
				Spawn("MOD/xml desert/relikt.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 4 then
				Spawn("MOD/xml desert/relikt bag.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 5 then
				Spawn("MOD/xml desert/tusk.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 6 then
				Spawn("MOD/xml desert/busk.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 7 then
				Spawn("MOD/xml desert/nozh.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)
			elseif selectedera == 8 then
				Spawn("MOD/xml desert/karkas.xml",Transform(hit_pos,QuatRotateQuat(QuatLookAt(Vec(), normal),QuatEuler(rotation, -90+rotationz, rotationy))),false,true)				
			end			  		  		  
		  end		  									
		end	
		
	else
		okidokieraD = FindBodies("okidokiera",true)
		for i=1, #okidokieraD do	 
			local okidokieraDs = okidokieraD[i]	
			Delete(okidokieraDs)		
		end	
		Delete(okidokiera)	
		spawnready = true
	end
end




function draw()

	if GetString("game.player.tool") == tool_name and GetPlayerVehicle() == 0 then
	   --[[ local prox_alert = ""
		
		UiPush()
		    UiTranslate(UiCenter(), UiMiddle()+150)
			UiAlign("center middle")
			UiColor(1, 0, 0)
			UiFont("bold.ttf", 32)
			UiTextOutline(0,0,0,1,0.1)
			UiText(prox_alert)
		UiPop()]]
		UiPush()
	        UiTranslate(UiCenter(), UiHeight()-120)
		    UiAlign("center middle")
		    UiColor(1, 1, 1)
		    UiFont("bold.ttf", 32)
		    UiTextOutline(0,0,0,1,0.1)
			local type_text
			local mode_text
			
		    if selectedera == 1 then 
			    type_text = "Kontakt-1 (G)" 
			elseif selectedera == 2 then 
				type_text =  "Kontakt-5 (G)" 								
			elseif selectedera == 3 then 
				type_text =  "Relikt (G)" 
			elseif selectedera == 4 then 
				type_text =  "Relikt Bag (G)"
			elseif selectedera == 5 then 
				type_text =  "TUSK2 (G)"
			elseif selectedera == 6 then 
				type_text =  "BUSK (G)"
			elseif selectedera == 7 then 
				type_text =  "Nizh(G)"
			elseif selectedera == 8 then 
				type_text =  "Karkas(G)"				
			end
			UiText(type_text)
	    UiPop()
		
		
		UiPush()
	        UiTranslate(UiWidth()-1150, UiHeight()-120)
		    UiAlign("center middle")
		    UiColor(1, 1, 1)
		    UiFont("bold.ttf", 28)
		    UiTextOutline(0,0,0,1,0.1)
			local type_text
			local mode_text
			
		    if selectedcolor == 1 then 
			    type_text = "Green(E)" 
			elseif selectedcolor == 2 then 
				type_text =  "Desert(E)" 																						
			end
			UiText(type_text)
	    UiPop()		
		


		UiPush()
	        UiTranslate(UiWidth()-750, UiHeight()-120)
		    UiAlign("center middle")
		    UiColor(1, 1, 1)
		    UiFont("bold.ttf", 23)
		    UiTextOutline(0,0,0,1,0.1)
			local type_text
			local mode_text
			
		    if rotatemod == true then 
			    type_text = "Rotate (MouseWheel)" 																						
			end
			UiText(type_text)
	    UiPop()		
		
		
		UiPush()
	        UiTranslate(UiCenter(), UiHeight()-90)
		    UiAlign("center middle")
		    UiColor(1, 1, 1)
		    UiFont("bold.ttf", 25)
		    UiTextOutline(0,0,0,1,0.1)
			local type_text2
			local mode_text2
			if rotatemod == true then
				type_text2 = "Reset Rotation(MMB)" 
			end
			UiText(type_text2)
	    UiPop()		

		--[[UiPush()
	        UiTranslate(UiCenter(), UiHeight()-60)
		    UiAlign("center middle")
		    UiColor(1, 1, 1)
		    UiFont("bold.ttf", 25)
		    UiTextOutline(0,0,0,1,0.1)
			local type_text2
			local mode_text2
			if rotatemod == true then
				type_text2 = "Reset Rotation(MMB)" 
			end
			UiText(type_text2)
	    UiPop()	]]


		UiPush()
	        UiTranslate(UiCenter(), UiHeight()-150)
		    UiAlign("center middle")
		    UiColor(1, 1, 1)
		    UiFont("bold.ttf", 28)
		    UiTextOutline(0,0,0,1,0.1)
			local type_text2
			local mode_text2
			
		    if rotatemod == false then 
			    type_text2 = "Rotate On/Off(R)" 
			elseif rotatemod == true and rot == 1 then 
				type_text2 =  "X Rotate(RMB)" 
			elseif rotatemod == true and rot == 2 then 
				type_text2 =  "Y Rotate(RMB)" 	
			elseif rotatemod == true and rot == 3 then 
				type_text2 =  "Z Rotate(RMB)" 					
			end
			UiText(type_text2)
	    UiPop()

		UiPush()
	        UiTranslate(UiCenter(), UiHeight()-60)
		    UiAlign("center middle")
		    UiColor(0.6, 1, 0.6)
		    UiFont("bold.ttf", 24)
		    UiTextOutline(0,0,0,1,0.1)
			UiText("Auto-cover (" .. config.key.autofill .. ")  " .. autofill_msg)
	    UiPop()	


		
		
	end
end







