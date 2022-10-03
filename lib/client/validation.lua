local validation = {}
local metricPattern = "^[%a_:][%w_:]*$";
local labelPattern = "^[%a_][%w_]*$";


function validation.validateMetricName(name)
	return string.find(name, metricPattern) ~= nil
end

function validation.validateLabelName(names)
	names = names or {}
	for _, name in ipairs(names) do
		if string.find(name, labelPattern) == nil then
			return false
		end
	end
end

function validation.validateLabel(savedLabels, labels)
	for _, label in ipairs(labels) do
		local saved = false
		for _, savedLabel in ipairs(savedLabels) do
			if label == savedLabel then
				saved = true
				break
			end
		end
		if not saved then
			error(string.format('Added label "%s" is not included in initial labelset: %s', label, table.concat(savedLabels, ', ')))
		end
	end
end

return validation
