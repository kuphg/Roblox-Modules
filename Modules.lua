local TweenService = game:GetService("TweenService");
local Promise = require(game:GetService("ReplicatedStorage").Promise);
local module = {};

module.string = {};
module.array = {};

function module.tween(instance, info, props)
	return Promise.new(function(resolve, reject, onCancel)
		local tween = TweenService:Create(instance, info, props);
		onCancel(function()
			tween:Cancel();
		end)

		tween.Completed:Connect(resolve);
		tween:Play();
	end)
end

local function getProperty(Object: Instance)
	if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
		return { "TextTransparency", "BackgroundTransparency" }
	elseif Object:IsA("ViewportFrame") or Object:IsA("ImageButton") or Object:IsA("ImageLabel") then
		return { "ImageTransparency" }
	elseif Object:IsA("Frame") then
		return { "BackgroundTransparency" }
	elseif Object:IsA("ScrollingFrame") then
		return { "ScrollBarImageTransparency" }
	elseif Object:IsA("UIStroke") then 
		return { "Transparency" }
	end
	return nil;
end

function module.fade(ui: Instance, duration: number, direction: string, recursive: boolean)
	if (recursive) then
		for _,v in ipairs(ui:GetDescendants()) do
			if (getProperty(v)) then module.fade(v, duration, direction) end;
		end
	end
	
	local props = getProperty(ui);
	local goal = {};
	
	if (typeof(direction) == "string") then
		if (direction == "in") then
			for _,v in ipairs(props) do
				local default = ui:GetAttribute("Default" .. v);
				if (not default) then continue end;
				
				local key = module.string.split(v, "Default")[1];
				if (ui[key] == default) then continue end;
				goal[key] = default;
			end
		else
			for _, v in ipairs(props) do
				local transparency = ui:GetAttribute("Default" .. v);
				if (not transparency) then transparency = ui[v]; ui:SetAttribute("Default" .. v, transparency) end;
				goal[v] = 1;
			end
		end
	end
	
	return module.tween(ui, TweenInfo.new(duration), goal);
end

function module.ternary(cond: boolean, t: any, f: any)
	if (cond) then
		if (type(t) == "function") then return t()
		else return t end;
	else
		if (type(f) == "function") then return f()
		else return f end;
	end
end

function module.toggleUI(ui, value, recursive)
	if (recursive) then
		for _,v in ipairs(ui:GetDescendants()) do
			if (getProperty(v)) then module.toggleUI(v, value) end;
		end
	end
	
	local props = getProperty(ui);
	if (ui:IsA("GuiButton")) then ui.AutoButtonColor = value end;
	
	for _,v in ipairs(props) do
		if (ui:GetAttribute("Ignore" .. v)) then continue end;
		ui[v] = module.ternary(value, 0, 0.5);
	end
end

function module.tweenModel(model, tweenInfo, cframe)
	if (model:GetAttribute("InAction"))  then return end

	local CFrameValue = Instance.new("CFrameValue");
	CFrameValue.Value = model:GetPrimaryPartCFrame();

	model:SetAttribute("InAction", true);
	CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:SetPrimaryPartCFrame(CFrameValue.Value);
	end)

	local tween = TweenService:Create(CFrameValue, tweenInfo, { Value = cframe });
	tween:Play();

	tween.Completed:Connect(function()
		CFrameValue:Destroy();
		model:SetAttribute("InAction", false);
	end)

	return tween;
end

function module.string.startsWith(str, start)
	return str:sub(1, #start) == start;
end

function module.string.endsWith(str, ending)
	return str:sub(-#ending) == ending;
end

function module.string.split(s, delimiter)
	local result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end

function module.array.map(tbl, f)
	local t = {};
	for k,v in ipairs(tbl) do
		t[k] = f(v);
	end
	return t;
end

return module;
