local convs = { cm = "1", inch = "1/(2.54)" }

local screen = platform.window
local w = screen:width()
local h = screen:height()
local inp = ""

exact_settings = {
	{ "Calculation Mode", "Exact" },
}

approx_settings = {
	{ "Calculation Mode", "Approximate" },
}

function setExact()
	math.setEvalSettings(exact_settings)
end

function setApprox()
	math.setEvalSettings(approx_settings)
end

menu = {
	{ "Mode", { "Fraction", setExact }, { "Decimal", setApprox } },
}

function on.construction()
	math.setEvalSettings(exact_settings)
	toolpalette.register(menu)
end

function on.resize()
	w = screen:width()
	h = screen:height()
end

function on.charIn(char)
	inp = inp .. char
	screen:invalidate()
end

function on.backspaceKey()
	inp = inp:usub(0, -2)
	screen:invalidate()
end

function on.paint(gc)
	gc:setColorRGB(0, 0, 0)
	gc:setPen("thin", "smooth")
	gc:drawRect(0.1 * w, h * 0.1, 0.25 * w, 0.1 * h)
	gc:drawString(inp, 0.1 * w + 10, h * 0.1)
	local i = 0
	for k, v in pairs(convs) do
		local out = math.evalStr(v .. "*" .. inp)
		if out then
			gc:drawString(out .. " " .. k, 0.35 * w + 10, 0.1 * h * (i + 1))
		end
		i = i + 1
	end
end
