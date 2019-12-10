--[[
	Functions for time interception equality between pursuers in pure pursuit
	d_ix: initial horizontal distance between pursuer i and evader
	d_iy: initial vertical distance between pursuer i and evader
	m_i: speed of pursuer i
	m: speed of evader
]]

local ti = {}

local function a_ij(d_ix,d_jx,m_i,m_j,m)
	return d_ix/(m_i*m_i-m*m) - d_jx/(m_j*m_j-m*m)
end

local function b_ij(d_iy,d_jy,m_i,m_j,m)
	return d_iy/(m_i*m_i-m*m) - d_jy/(m_j*m_j-m*m)
end

local function r_ij(d_ix,d_iy,d_jx,d_jy,m_i,m_j,m)
	return (math.sqrt(d_jx*d_jx+d_jy*d_jy)*m_j/(m_j*m_j-m*m) - math.sqrt(d_ix*d_ix+d_iy*d_iy)*m_i/(m_i*m_i-m*m))/m
end

local function clamp_angle(x)
	local pi2 = 2*math.pi
	return x - pi2*math.floor(x/pi2)
end

local function sin_cos(a,b,r)
	local c,t = math.acos(r/math.sqrt(a*a+b*b)), math.atan2(b,a)
	if c~=c then return nil end --no interceptions
	return clamp_angle(t + c), clamp_angle(t - c)
end

--evaluate time taken
--(assumes mi > m)
function ti.evaluate(dix,diy,mi,m,alpha)
	return ((dix*math.cos(alpha)+diy*math.sin(alpha))*m + math.sqrt(dix*dix+diy*diy)*mi)/(mi*mi-m*m)
end

--calculate interception between i-esim and j-esim characters
function ti.calculate(d_ix,d_iy,d_jx,d_jy,m_i,m_j,m)
	local a = a_ij(d_ix,d_jx,m_i,m_j,m)
	local b = b_ij(d_iy,d_jy,m_i,m_j,m)
	local r = r_ij(d_ix,d_iy,d_jx,d_jy,m_i,m_j,m)
	local ans,ans2 = sin_cos(a,b,r)
	return ans,ans2
end

return ti