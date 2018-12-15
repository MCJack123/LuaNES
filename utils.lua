UTILS = {}
local UTILS = UTILS

function UTILS.isDefined(v)
    return v and v ~= CPU.UNDEFINED
end

function UTILS.bind(f, param)
    return function(...)
        f(param, unpack(...))
    end
end

function UTILS.tSetter(t)
    return function(i, v)
        t.ram[i] = v
    end
end
function UTILS.tGetter(t)
    return function(i)
        return t[i]
    end
end
function UTILS.map(t, f)
    local tt = {}
    for i = 1, #t do
        tt[i] = f(t[i])
    end
    return tt
end
function UTILS.fill(t, v, n, step)
    for i = 1, math.max(#t, n or 0), step or 1 do
        t[i] = v
    end
    return t
end
function UTILS.rotate(t, r)
    local rotated = {}
    local size = #t
    for i = 1, size do
        local idx = i + r
        idx = idx > size and idx - size or (idx < 1 and idx + size or idx)
        rotated[i] = t[idx]
    end
    return rotated
end
function UTILS.nthBitIsSet(n, nth)
    return bit.band(n, bit.lshift(0x1, nth)) ~= 0
end
function UTILS.range(a, b, step)
    local t = {}
    for i = 1, b - a, step or 1 do
        t[i] = a + i
    end
    return t
end
function UTILS.copy(t, n, offset, step)
    local tt = {}
    n = n or #t
    offset = offset or 0
    for i = 1, n, step or 1 do
        tt[i] = t[i + offset]
    end
    return tt
end
function UTILS.dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end
function UTILS.print(x)
    print(UTILS.dump(x))
end
