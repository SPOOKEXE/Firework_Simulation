
local FireworksData = require(script.Parent.Parent.Data.Fireworks)

-- // Module // --
local Module = {}

function Module:BuildVariantData( fireworkType, variants )
	local builtVariants = {}
	for _, variantData in ipairs( variants ) do
		-- TODO:
		local builtVariant = variantData

		table.insert(builtVariants, builtVariant)
	end
	return builtVariants
end

function Module:BuildHandHeldVariant( variants )
	local typee = FireworksData.FireworkTypes.Handheld
	return { Type = typee, Variant = Module:BuildVariantData( typee, variants ), }
end

function Module:BuildGroundVariant( variants )
	local typee = FireworksData.FireworkTypes.Ground
	return { Type = typee, Variant = Module:BuildVariantData( typee, variants ), }
end

function Module:BuildMortarVariants( trailVariant, shellVariant )
	local typee = FireworksData.FireworkTypes.Mortar
	return { Type = typee, Trail = Module:BuildVariantData( typee, trailVariant ), Shell = Module:BuildVariantData( typee, shellVariant ), }
end

return Module
