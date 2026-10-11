function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end

function init()
era = FindBody("okidokiera")
end


function tick(dt)
DrawBodyOutline(era, 0.5)
end
