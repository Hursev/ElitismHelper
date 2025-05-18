-- Frame creation.
local addonName, addonTable = ...;
local EH_configFrame = CreateFrame("Frame", "ElitismHelperGUI");
EH_configFrame.name = "Elitism Helper";
-- Local variables.
local dx_loc = 10;
local dy_loc = -30;

-- Register events.
EH_configFrame:RegisterEvent("PLAYER_LOGIN");

-- Label factory
function createLabel(paramStruct)
    local parent = paramStruct["parent"];
    local x_loc = paramStruct["x_loc"];
    local y_loc = paramStruct["y_loc"];
    local x_size = paramStruct["x_size"];
    local y_size = paramStruct["y_size"];
    local id = paramStruct["id"];
    local labelText = paramStruct["labelText"];
    local style = paramStruct["style"];
    local title = parent:CreateFontString(nil, "ARTWORK", style);
    title:SetPoint("TOPLEFT", x_loc, y_loc);
    title:SetText(labelText);

    return title;
end

-- CheckButton factory.
function createCheckbutton(paramStruct)
    local parent = paramStruct["parent"];
    local x_loc = paramStruct["x_loc"];
    local y_loc = paramStruct["y_loc"];
    local id = paramStruct["id"];
    local displayName = paramStruct.displayName;
	local checkButton = CreateFrame("CheckButton", "$parent_CheckButton_" .. id, parent, "ChatConfigCheckButtonTemplate");
	checkButton:SetPoint("TOPLEFT", x_loc, y_loc);
    _G[checkButton:GetName() .. 'Text']:SetText(displayName);

	return checkButton;
end

-- Dropdown menu factory.
function createDropDownMenu(parent, x_loc, y_loc, id, options, width, default_value, displayName, on_select_func)
    local dropDown = CreateFrame("Frame", '$parent_DropDown_' .. id, parent, 'UIDropDownMenuTemplate');
    local dropDownTitle = dropDown:CreateFontString(nil, 'OVERLAY', 'GameFontNormal');
    local infoTable = {};
    dropDown:SetPoint("TOPLEFT", x_loc, y_loc);

    -- 1. Create a table (array) to hold the keys
    local sortedKeys = {}
    for key, val in pairs(options) do
        table.insert(sortedKeys, key)
    end
    table.sort(sortedKeys)

    local paramsLabel = {
        ["parent"] = dropDown,
        ["x_loc"] = 18,
        ["y_loc"] = 15,
        ["x_size"] = 100,
        ["y_size"] = 50,
        ["id"] = "dropDrownTitle_" .. id,
        ["labelText"] = displayName,
        ["style"] = "GameTooltipText"
    }
    createLabel(paramsLabel);

    for _, option in pairs(options) do
        dropDownTitle:SetText(item);
        local text_width = dropDownTitle:GetStringWidth() + 20;
        if text_width > width then
            width = text_width;
        end
    end

    UIDropDownMenu_SetText(dropDown, default_value:gsub("^%l", string.upper));
    UIDropDownMenu_SetWidth(dropDown, width);
    UIDropDownMenu_Initialize(dropDown, function(self, level, _)
        local info = UIDropDownMenu_CreateInfo();
        --for key, val in pairs (options) do
        for i, key in ipairs(sortedKeys) do
            local val = options[key]

            info.text = val;--key;
            info.value = val;
            --info.tooltipTitle = 'Test';
            info.checked = false;
            info.hasArrow = false;
            info.tooltipOnButton = 'Test ' .. key;
            info.func = function(inf)
                UIDropDownMenu_SetSelectedValue(dropDown, inf.value, inf.key);
                inf.checked = true;
                on_select_func(dropDown, inf.value);
            end
            infoTable[key] = info;
            UIDropDownMenu_AddButton(info);
        end
    end);

    return infoTable, dropDown;
end


-- UI component variables.
local EH_CheckButton_EnableAnnouncer;
local EH_CheckButton_EnableEndOfDungeon;
local EH_DropDown_OutputChannel;
local infoTable;
local EH_Slider_Threshold;
local sliderValueLabel;

EH_configFrame.refreshValues = function()
    EH_CheckButton_EnableAnnouncer:SetChecked(ElitismHelperDB.Loud);
    EH_CheckButton_EnableEndOfDungeon:SetChecked(ElitismHelperDB.EndOfDungeonMessage);
    UIDropDownMenu_SetSelectedValue(EH_DropDown_OutputChannel, ElitismHelperDB.OutputMode, ElitismHelperDB.OutputMode:gsub("^%l", string.upper));
    UIDropDownMenu_SetText(EH_DropDown_OutputChannel, ElitismHelperDB.OutputMode:gsub("^%l", string.upper));
    EH_Slider_Threshold:SetValue(ElitismHelperDB.Threshold);
    sliderValueLabel:SetText(tostring(ElitismHelperDB.Threshold) .. "%");
end


function buildGUI()
    -- GUI building
    -- Build Elitism Announcer check button.
    local parameterAnnouncerCheckButton = {
        ["parent"] = EH_configFrame,
        ["x_loc"] = dx_loc,
        ["y_loc"] = dy_loc - 10,
        ["id"] = "EnableAnnouncer",
        ["displayName"] = "Enable Elitism Helper damage notifications announcer"
    }
    EH_CheckButton_EnableAnnouncer = createCheckbutton(parameterAnnouncerCheckButton);
    EH_CheckButton_EnableAnnouncer.tooltip = "If this is checked, the Elitism Helper will announce each event.";
    EH_CheckButton_EnableAnnouncer:SetScript("OnClick", 
        function()
            ElitismHelperDB.Loud = EH_CheckButton_EnableAnnouncer:GetChecked();
        end
    )

    -- Build End of dungeon stats check button.
    local _, _, _, _, yOfs = EH_CheckButton_EnableAnnouncer:GetPoint();
    local parameterEoDCheckButton = {
        ["parent"] = EH_configFrame,
        ["x_loc"] = dx_loc,
        ["y_loc"] = yOfs + dy_loc,
        ["id"] = "EnableEndOfDungeonMessage",
        ["displayName"] = "Enable end of dungeon stats"
    }
    EH_CheckButton_EnableEndOfDungeon = createCheckbutton(parameterEoDCheckButton);
    EH_CheckButton_EnableEndOfDungeon.tooltip = "If this is checked, the overall stats will be shown at the end of the dungeon.";
    EH_CheckButton_EnableEndOfDungeon:SetScript("OnClick", 
        function()
            ElitismHelperDB.EndOfDungeonMessage = EH_CheckButton_EnableEndOfDungeon:GetChecked();
            --print("EndOfDungeonMessage: " .. tostring(ElitismHelperDB.EndOfDungeonMessage));
        end
    )

    -- Build output channel dropdown.
    _, _, _, _, yOfs = EH_CheckButton_EnableEndOfDungeon:GetPoint();
    -- Output channel options obj
    local output_channel_opts = {
        Default='default',
        Self='self',
        Party='party',
        Raid='raid',
        Yell='yell',
        Emote='emote',
        Channel1='channel 1',
        Channel2='channel 2',
        Channel3='channel 3',
        Channel4='channel 4',
        Channel5='channel 5',
        Channel6='channel 6',
        Channel7='channel 7',
        Channel8='channel 8',
        Channel9='channel 9',
        Channel10='channel 10',
    };

    -- onChange function for output channel dropdown.
    local onChange_outputChannelDropdown = function(dropDown_frame, dropDown_val)
        ElitismHelperDB.OutputMode = dropDown_val;
        print("Testing output for "..ElitismHelperDB.OutputMode);
        if addonTable.EH_maybeSendChatMessage then
            addonTable.EH_maybeSendChatMessage("This is a test message");
        end
    end

    -- Build output channel dropdown.
    infoTable, EH_DropDown_OutputChannel = createDropDownMenu(EH_configFrame,
                                                        dx_loc - 11, yOfs + dy_loc - 25,
                                                        'OutputChannel',
                                                        output_channel_opts,
                                                        100,
                                                        ElitismHelperDB.OutputMode,
                                                        'Output channel',
                                                        onChange_outputChannelDropdown);

    -- Slider factory
    function createSlider(paramStruct)
        local parent = paramStruct["parent"];
        local x_loc = paramStruct["x_loc"];
        local y_loc = paramStruct["y_loc"];
        local id = paramStruct["id"];
        local displayName = paramStruct["displayName"];
        local step = paramStruct["step"];
        local minValue = paramStruct["minValue"];
        local maxValue = paramStruct["maxValue"];
        local slider = CreateFrame("Slider", "$parent_Slider_" .. id, parent, "OptionsSliderTemplate");
        slider:SetMinMaxValues(minValue, maxValue);
        slider:SetOrientation('HORIZONTAL');
        slider:SetPoint("TOPLEFT", x_loc, y_loc);
        slider:SetObeyStepOnDrag(true);
        slider:SetValueStep(step);

        local parameterNameLabel = {
            ["parent"] = slider, -- TODO: revisar parent, debería ser el dropDown construido
            ["x_loc"] = 0,
            ["y_loc"] = 15,
            ["x_size"] = 100,
            ["y_size"] = 50,
            ["id"] = "sliderTitle_" .. id,
            ["labelText"] = displayName,
            ["style"] = "GameTooltipText"
        }
        createLabel(parameterNameLabel);

        return slider;
    end

    -- Build slider for the treshold damage.
    _, _, _, _, yOfs = EH_DropDown_OutputChannel:GetPoint();
    local parameterDamageThresholdSlider = {
        ["parent"] = EH_configFrame,
        ["x_loc"] = dx_loc + 7,
        ["y_loc"] = yOfs + dy_loc - 25,
        ["id"] = "damageThreshold",
        ["displayName"] = "Damage threshold",
        ["step"] = 1,
        ["minValue"] = 0,
        ["maxValue"] = 100
    }
    EH_Slider_Threshold = createSlider(parameterDamageThresholdSlider);
    --print("EH_Slider_Threshold is null: " .. tostring(EH_Slider_Threshold == nil));
    local EH_Slider_ThresholdName = EH_Slider_Threshold:GetName();
    _G[EH_Slider_ThresholdName  .. "Low"]:SetText("0%");
    _G[EH_Slider_ThresholdName  .. "High"]:SetText("100%");

    local parameterThresholdSliderValue = {
        ["parent"] = EH_Slider_Threshold,
        ["x_loc"] = dx_loc + 150,
        ["y_loc"] = -4,
        ["x_size"] = 100,
        ["y_size"] = 50,
        ["id"] = "thresholdLabel",
        ["labelText"] = "",
        ["style"] = "GameTooltipText"
    }
    sliderValueLabel = createLabel(parameterThresholdSliderValue);

    EH_Slider_Threshold:Show();
    EH_Slider_Threshold:SetScript("OnValueChanged",
        function(self)
            local value = self:GetValue();
            ElitismHelperDB.Threshold = value;
            sliderValueLabel:SetText(tostring(self:GetValue()) .. "%");
            --print("Click slider. Slider value: " .. value);
        end
    );

    local parameterConfigPanelTitle = {
        ["parent"] = EH_configFrame,
        ["x_loc"] = 10,
        ["y_loc"] = -20,
        ["x_size"] = 100,
        ["y_size"] = 100,
        ["id"] = "ehTitle",
        ["labelText"] = "Elitism Helper",
        ["style"] = "GameFontNormalLarge"
    }
    local EH_labelTest = createLabel(parameterConfigPanelTitle);

    -- Load configs from ElitismHelperDB in SavedVariables.
    EH_configFrame:refreshValues();
end

-- Event handler
EH_configFrame:SetScript("OnEvent", function(self)
    -- PLAYER_LOGIN event
    buildGUI();
    -- print("my addonName: " .. addonName);
    -- print("ElitismHelperDB.Loud: " .. tostring(ElitismHelperDB.Loud));
    -- print("ElitismHelperDB.EndOfDungeonMessage: " .. tostring(ElitismHelperDB.EndOfDungeonMessage));
    -- print("ElitismHelperDB.OutputMode: " .. ElitismHelperDB.OutputMode);
    -- print("ElitismHelperDB.Threshold: " .. tostring(ElitismHelperDB.Threshold));
    --InterfaceAddOnsList_Update();
    addonTable.UIPanel = EH_configFrame;
end)

-- old
--InterfaceOptions_AddCategory(EH_configFrame);
-- new:
--

-- 1. Register the frame as a canvas layout category
-- The first argument is the frame, the second is the category name (display string)
local category, layout = Settings.RegisterCanvasLayoutCategory(EH_configFrame, "Elitism Helper");

-- 2. Register the category as an AddOn category
-- This makes it appear under the AddOns section in the Interface Options
Settings.RegisterAddOnCategory(category);

addonTable.settingsCategory = category

-- Optional: If you had a function to open directly to this category,
-- you would now use Settings.OpenToCategory(category.ID) instead of
-- InterfaceOptionsFrame_OpenToCategory("ElitismHelperGUI");