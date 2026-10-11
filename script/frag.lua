
globalConfig = {
        gravity = Vec(0,-9,0)
 }

weapon = {
	 weaponName 				= "explosion",
  	munitionType 			= "explosive",
  	explosionSize 		= 1,
  	fuze_time 				= 4, 
    reliability       = .25, -- (percentage deviation from expected explosion time)
    shrapnel_damage =  0.1,
    shrapnel_size     =0.03,
    spall_value = 80, --300
  	Create 					= "elboydo",
}

spallHandler = 
  {
    shellNum = 1,
    shells = {

    },
  defaultShell = {active=false, velocity=nil, direction =nil, currentPos=nil, timeLaunched=nil},
  velocity = 200,
  gravity = Vec(0,-25,0),
  shellWidth = 0.3,
  shellHeight = 0.3,
  }


  boom_pos = nil

active_spall = 0 

total_spall = 0

function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end

function init( )
  munition  = FindShape(weapon.weaponName)
  body = GetShapeBody(munition)
  fuze = weapon.fuze_time + rnd(-weapon.fuze_time * weapon.reliability,weapon.fuze_time * weapon.reliability)
  added_cook_time = false

  disclamp = 0
  era = FindShapes("era")
  erabody = FindBody("")

  exploded = false 
  explosion_sound = LoadSound("MOD/snd/grenade_explosion.ogg")
  spalling_sprite =  LoadSprite("MOD/gfx/spalling.png")
end
function rnd(mi, ma)
  return math.random()*(ma-mi)+mi
end
function rndVec(length)
  local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
  return VecScale(v, length)  
end
function tick(dt)
  -- if(boom_pos~=nil) then
  --   DebugCross(boom_pos)
  -- end
  -- DebugWatch("active spall ",active_spall)
  -- DebugWatch("total spall ",total_spall)
  
  if(not exploded) then
    if IsShapeBroken(munition) then
		erabodyT = GetBodyTransform(erabody)
		local min1, max1 = GetShapeBounds(munition)
   	 	local pos = VecLerp(min1, max1, 0.5)		
      --local pos = GetShapeWorldTransform(munition).pos
      local shrapnel_pos = VecAdd(erabodyT.pos,Vec(0,0,0))
      -- boom_pos = shrapnel_pos
	  
      pushshrapnel(Transform(shrapnel_pos))
      -- for i = 1,math.random(4,50) do 
      --   Shoot(pos, rndVec(1), 0, 0.3)
      -- end
      exploded = true
    end
  elseif(active_spall>0) then 
    spallingTick(dt)
  end

end




function pushshrapnel(spallingLoc)

  local spallValue = weapon.spall_value
  -- DebugWatch("spall quant_1",spallValue)
  if(weapon.explosionSize) then 
    spallValue = spallValue *  weapon.explosionSize
  end
  -- DebugWatch("spall quant",spallValue)
  local spallQuant = math.random(spallValue,spallValue*3)

  total_spall = spallQuant
  active_spall = total_spall
  for i=1, spallQuant do 
    local damage_coef = rnd(weapon.shrapnel_damage*.5,weapon.shrapnel_damage*1.5)
    local spallingSizeCoef = math.random(1,4)/10
    local spallPos = TransformCopy(spallingLoc)
    local direction = rndVec(math.random(1,spallValue))
    local point1 = spallPos.pos
    spallHandler.shells[#spallHandler.shells+1] = deepcopy(spallHandler.defaultShell)
    local currentSpall        = spallHandler.shells[#spallHandler.shells] 
    currentSpall.active       = true 
    currentSpall.shellType = {}
    currentSpall.cannonLoc      = spallPos
    currentSpall.point1     = point1 
    --currentSpall.predictedBulletVelocity = rndVec(math.random() * 200)	
    currentSpall.predictedBulletVelocity = rndVec(math.random() * 20)
    currentSpall.shrapnel = true
    currentSpall.originPos    = spallPos 
    currentSpall.maxTimeToLive = (3 *(spallingSizeCoef+0.2))*(math.random(50,100)/100)
    currentSpall.timeToLive   = currentSpall.maxTimeToLive
    currentSpall.dispersion     = 10 
    currentSpall.shellType.bulletdamage = {}
    currentSpall.shellType.bulletdamage[1] = damage_coef * spallingSizeCoef
    currentSpall.shellType.bulletdamage[2] = damage_coef *.7 * spallingSizeCoef
    currentSpall.shellType.bulletdamage[3] = damage_coef *.5 * spallingSizeCoef
    currentSpall.shellType.caliber = (weapon.shrapnel_size * spallingSizeCoef)*0.3
    currentSpall.shellType.shellWidth = math.min(math.random(), 0.1)
    currentSpall.shellType.shellHeight = math.min(math.random(),0.1) 
    currentSpall.penDepth = 0.1

    currentSpall.shellType.r = 2 + (math.random(0,5)/10)
    currentSpall.shellType.g = 1.7 + (math.random(0,5)/10)
    currentSpall.shellType.b = 1 + (math.random(0,10)/10)


    spallHandler.shellNum = (spallHandler.shellNum%#spallHandler.shells) +1

  end

end


function shrapnelOperations(projectile,dt )
    projectile.cannonLoc.pos = projectile.point1
    local shellHeight = projectile.shellType.shellHeight
    local shellWidth = projectile.shellType.shellWidth
    -- local spallDecay =  math.random()* (currentSpall.maxTimeToLive / currentSpall.timeToLive )
    local spallDecay = math.random()
    local r = projectile.shellType.r * spallDecay
    local g = projectile.shellType.g * spallDecay
    local b = projectile.shellType.b * spallDecay


    --- sprite drawing
    DrawSprite(spalling_sprite, projectile.cannonLoc,projectile.shellType.shellWidth,shellHeight , r, g, b, 1, 0, false)
    local altloc = TransformCopy(projectile.cannonLoc)
    altloc.rot = QuatRotateQuat(altloc.rot,QuatEuler(0, 90,0))
    DrawSprite(spalling_sprite, altloc, projectile.shellType.shellWidth, shellHeight, r, g, b, 1, 0, false)
    altloc.rot = QuatRotateQuat(projectile.cannonLoc.rot,QuatEuler(90, 0,0))
    DrawSprite(spalling_sprite, altloc, projectile.shellType.shellWidth, projectile.shellType.shellWidth, r, g, b, 1, 0, false)
    

    projectile.predictedBulletVelocity = VecScale(projectile.predictedBulletVelocity,0.99)

    local dispersion = Vec(math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion)
    if(projectile.shellType.dispersionCoef) then
      dispersion=VecScale(dispersion,dispersionCoef)
    end
    projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(dispersion,dt)))

      projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(globalConfig.gravity,dt)))
 
    --disclamp = disclamp + dt 
	--disclamp = clamp(disclamp, 0, 15)
    --local point2 = VecAdd(projectile.point1,VecScale(projectile.predictedBulletVelocity,disclamp))
    local point2 = VecAdd(projectile.point1,VecScale(projectile.predictedBulletVelocity,dt))

	local temp = FindVehicles(nil, true)
	for i=1, #temp do
 	  QueryRejectVehicle(temp[i])
	end
    local hit, dist1,norm1,shape1 = QueryRaycast(projectile.point1, VecNormalize(VecSub(point2,projectile.point1)),VecLength(VecSub(point2,projectile.point1)))
	--maxdis -> VecLength(VecSub(point2,projectile.point1))
    
    projectile.cannonLoc.rot = QuatRotateQuat(QuatLookAt(point2,projectile.point1),QuatEuler(00, 90, 90))
    


      local hit_player =  inflict_player_damage(projectile,point2)

      if(hit or hit_player)then 
        hitPos = VecAdd(projectile.point1, VecScale(VecNormalize(VecSub(point2,projectile.point1)),dist1))	  
        projectile.point1 = hitPos
		
		local mat, r, g, b, a = GetShapeMaterialAtPosition(shape1, hitPos)		
		dynamicbody = GetShapeBody(shape1)	
		if mat ~= "hardmetal" and IsBodyDynamic(dynamicbody) then --and mat ~= "metal" 
         popSpalling(projectile,shape1)
		end
       
      else
        projectile.point1 = point2
      end
    
end



function popSpalling(shell,hitTarget)

    local holeModifier = math.random(-15,15)/100
    local fireChance = math.random(0,100)/100
    local firethreshold = 0.96
	
    if shell.shellType.hit and shell.shellType.hit <3 then	
			
      if(shell.shellType.hit ==1)then	  

        MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4)
      else
        MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4,shell.shellType.bulletdamage[2]*1.2)
      end

    else
      MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4,shell.shellType.bulletdamage[2]*1.2, shell.shellType.bulletdamage[3]*1.2)	  
	  
    end	


    shell.active = false
    active_spall  = active_spall -1
    for key,val in ipairs( shell ) do 
      val = nil

    end
    shell = deepcopy(spallHandler.defaultShell)

end


function spallingTick(dt)
      -- DebugWatch("shells",#spallHandler.shells  )
      for key,shell in ipairs( spallHandler.shells  )do
        if(shell.active)then
          if(shell.timeToLive > 0) then 
            if(shell.shrapnel) then 
              shrapnelOperations(shell,dt)
              
            else
              spallingOperations(shell,dt)
            end
            shell.timeToLive = shell.timeToLive - dt
          else
            shell.active = false
            active_spall  = active_spall -1
          end
        end
    end
end



function inflict_player_damage(projectile,point2)
  local t= Transform(projectile.point1,QuatLookAt(point2,projectile.point1))
  local p = TransformToParentPoint(t, Vec(0, 0, 1))
  local p2 = TransformToParentPoint(t, Vec(0, 0, 2))

  local d = VecNormalize(VecSub(projectile.point1,point2))

  hurt_dist = VecLength(VecSub(projectile.point1,point2))
  --Hurt player
  local player_cam_pos = GetPlayerCameraTransform().pos
  local player_pos = GetPlayerTransform().pos

  player_pos = VecLerp(player_pos,player_cam_pos,0.5)
  local toPlayer = VecSub(player_pos, t.pos)
  local distToPlayer = VecLength(toPlayer)
  local distScale = clamp(1.0 - distToPlayer / hurt_dist, 0.0, 1.0)
  -- DebugWatch("test",distScale)
  if distScale > 0 then
    -- DebugWatch("dist scale",distScale)
    toPlayer = VecNormalize(toPlayer)
    -- DebugWatch("dot to player",VecDot(d, toPlayer))
      -- DebugWatch("distToPlayer",distToPlayer)
    if VecDot(d, toPlayer) > 0.9 or distToPlayer < 1 then
      -- DebugWatch("player dist scale",distScale)
      -- DebugWatch("distToPlayer",distToPlayer)
      local hit = QueryRaycast(p, toPlayer, distToPlayer)
      if not hit or distToPlayer < 0.7 then
        -- DebugWatch("player would be hit",distToPlayer)
        SetPlayerHealth(GetPlayerHealth() - 0.035 * (projectile.shellType.bulletdamage[1] * (distScale*2)*25)*math.log(VecLength(projectile.predictedBulletVelocity)))
        return true
      end
    end 
  end
  return false
end


function clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end


function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
