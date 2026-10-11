#include "frag.lua"

function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end

function init()
nocollision = FindShapes("nocol")
era = FindShapes("era")
explosive = FindShapes("explosion")
detonation = false
deletetime = 0
sequence = 1

	SndTable_close = {
		"MOD/snd/close1.ogg",
		"MOD/snd/close2.ogg",
		"MOD/snd/close3.ogg",
		"MOD/snd/close4.ogg"	
	}	
	SndTable_far = {
		"MOD/snd/far1.ogg",
		"MOD/snd/far2.ogg",
		"MOD/snd/far3.ogg"
	}	

	size = 0.3
	life = 3	

end



function tick(dt)

	for i=1, #explosive do	
		local explosives = explosive[i]		
		if IsShapeBroken(explosives) and sequence == 1 then
			detonation = true
		end
		local min1, max1 = GetShapeBounds(explosives)
   		pos = VecLerp(min1, max1, 0.5)		
	end	

	for i=1, #era do	
		local eras = era[i]		
		if detonation == true then
    		local min, max = GetShapeBounds(eras)
    		local shapeCenter1 = VecLerp(min, max, 0.5)
					for i=1, 100 do -- ex particle									
						ParticleReset()
						ParticleType("smoke")
						ParticleCollide(0)
						ParticleRadius(0.6) -- 0.3
						ParticleDrag(0.5)
						ParticleEmissive(0)
						ParticleColor(.2,.2,.2)
						ParticleGravity(0)
						ParticleAlpha(0.6, 0)
						SpawnParticle(VecAdd(pos, Vec(rnd(-size,size),rnd(-size,size),rnd(-size,size))), Vec(rnd(-4,4),rnd(-4,4),rnd(-4,4)), 7)
					end

					for i=1, 20 do -- ex particle									

						ParticleReset()
						ParticleTile(5)
						ParticleType("smoke")
						ParticleCollide(0)
						ParticleRadius(0.2, 0.4) --(0.15, 0.3)
						ParticleDrag(0.5)
						ParticleEmissive(2, 0)
						ParticleColor(.9,.3,.15)
						ParticleGravity(0)
						ParticleAlpha(1, 0)
						SpawnParticle(VecAdd(pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.3),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 1)

						ParticleReset()
						ParticleTile(8)
						ParticleType("smoke")
						ParticleCollide(0)
						ParticleRadius(0.2, 0.4) --(0.15, 0.4)
						ParticleDrag(1)
						ParticleEmissive(2, 0)
						ParticleColor(0.9,.6,.3)
						ParticleGravity(0)
						ParticleAlpha(1, 0)
						SpawnParticle(VecAdd(pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.3),rnd(-0.3,0.3))), Vec(rnd(-1,1),rnd(0,0.5),rnd(-1,1)), 1)

						ParticleReset()
						ParticleType("smoke")
						ParticleCollide(0)
						ParticleTile(5)
						ParticleRadius(0.2, 0.4) --(0.15, 0.3)
						ParticleDrag(0.5)
						ParticleEmissive(2, 0)
						ParticleColor(1,.5,.3)
						ParticleGravity(0)
						ParticleAlpha(1, 0)
						SpawnParticle(VecAdd(pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.3),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 0.8)						


			ParticleReset() -- SPARKS
			ParticleType("plain")
			ParticleTile(6)
			ParticleSticky(0)			
			ParticleRadius(0.05, 0.01) --0.01
			ParticleAlpha(1, 0)
			ParticleEmissive(5,0)
			ParticleGravity(-10)
			ParticleDrag(0.1)

			ParticleColor(rnd(.9,1),rnd(.3,.5),rnd(.2,.3),rnd(.7,.8),rnd(.3,.4),rnd(.1,.2))
			SpawnParticle(VecAdd(pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.3),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 0.8)	

						
					end

					PointLight(pos.pos, 1, .20, .0130, 5)	



    		--PlaySound()
			
			if VecLength(VecSub(pos,GetCameraTransform().pos)) <= 13 then
				snd = LoadSound(SndTable_close[math.random(1, 4)])
				PlaySound(snd, pos)		
			elseif VecLength(VecSub(pos,GetCameraTransform().pos)) > 13 then
				snd = LoadSound(SndTable_far[math.random(1, 3)])
				PlaySound(snd, pos,30)					
			end			
			
			--SetTag(explosive,"active")
			sequence = 2

		end
		
		if sequence == 2 then
			deletetime = deletetime + dt			
			if deletetime > 0.01 then
				detonation = false
				Delete(eras)
			end		
		end
		
	end		



end
