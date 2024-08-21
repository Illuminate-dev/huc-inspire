local convs = { cm = "1", inch = "1/(2.54)", m = "100", ["in"] = "1/(2.54)" }
local function get_keys(t)
	local keys = {}
	for key, _ in pairs(t) do
		table.insert(keys, key)
	end
	return keys
end

local units = get_keys(convs)

local screen = platform.window
local w = screen:width()
local h = screen:height()
local inp = ""

local function parseUnit(input, idx)
	for _, unit in ipairs(units) do
		if input:sub(idx, idx + #unit - 1) == unit then
			return unit
		end
	end
end

local function parseNum(input, idx)
	local num = ""
	local i = idx
	while i <= #input do
		local c = input:sub(i, i)
		if tonumber(c) then
			num = num .. c
			i = i + 1
		else
			break
		end
	end
	return num
end

local function convertToCGS(us)
	local outn = ""
	local outu = ""

	local i = 1
	while i <= #us do
		local c = us:sub(i, i)
		local unit_maybe = parseUnit(us, i)

		if c == "(" then
			local endparen = us:find(")", i)
			if endparen ~= nil then
				local nums, uns = convertToSI(us:sub(i, endparen - 1))
				outn = outn .. "(" .. nums .. ")"
				outu = outu .. "(" .. uns .. ")"
				i = endparen + 1
			else
				i = i + 1
			end
		elseif c == "*" or c == "/" then
			outn = outn .. c
			outu = outu .. c
			i = i + 1
		elseif c == "^" then
			outn = outn .. "^"
			outu = outu .. "^"
			i = i + 1
			local num = parseNum(us, i)
			outn = outn .. num
			outu = outu .. num
			i = i + #num
		elseif unit_maybe then
			if convs[unit_maybe] then
				outu = outu .. "cm"
				outn = outn .. convs[unit_maybe]
				i = i + #unit_maybe
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end
	return outn, outu
end

local function parse(input)
	local numbers = ""
	local us = ""

	local i = 1
	while i <= #input do
		local unit_maybe = parseUnit(input, i)
		local c = input:sub(i, i)

		if c == "(" then
			local endparen = input:find(")", i)
			if endparen ~= nil then
				local nums, uns = parse(input:sub(i, endparen - 1))
				numbers = numbers .. "(" .. nums .. ")"
				us = us .. "(" .. uns .. ")"
				i = endparen + 1
			else
				i = i + 1
			end
		elseif c == "*" or c == "/" then
			if #input == 0 or input:sub(i - 1, i - 1) == "*" or input:sub(i - 1, i - 1) == "/" then
				us = us .. c
			end
			numbers = numbers .. c
			i = i + 1
		elseif c == "^" then
			numbers = numbers .. "^"
			us = us .. "^"
			i = i + 1
			local num = parseNum(input, i)
			numbers = numbers .. num
			us = us .. num
			i = i + #num
		elseif unit_maybe then
			if input:sub(i - 1, i - 1) == "/" or input:sub(i - 1, i - 1) == "*" then
				numbers = numbers .. "1"
			end
			us = us .. unit_maybe
			i = i + #unit_maybe
		else
			numbers = numbers .. input:sub(i, i)
			i = i + 1
		end
	end

	return numbers, us
end

local function parseAndConvert(input)
	local numbers, us = parse(input)
	if us then
		local nums, uns = convertToCGS(us)
		numbers = numbers .. "*" .. nums
		us = uns
	end

	return numbers, us
end

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

	if inp then
		local nums, uns = parseAndConvert(inp)
		-- print(nums, uns)
		uns = math.evalStr(uns)
		nums = math.evalStr(nums)
		--print(uns, nums)
		if nums and uns then
			local out = math.evalStr(nums .. "*" .. uns)
			if out then
				gc:drawString(out, 0.35 * w + 10, 0.1 * h)
			end
		end
	end

	--    local i = 0
	--    for k, v in pairs(convs) do
	--        local out = math.evalStr(v.."*"..inp)
	--        if out then
	--            gc:drawString(out.." "..k, 0.35*w+10, 0.1*h*(i+1))
	--        end
	--        i = i + 1
	--   end
end
