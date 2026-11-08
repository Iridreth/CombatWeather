
local ADDON_NAME = "CombatWeather"

local DEFAULTS = {
    inCombat = 0,
    outOfCombat = 3,
    chatMessages = true,
}

local settings
local panel
local combatDropdown
local outOfCombatDropdown
local chatMessagesCheckbox

local pendingInCombat = DEFAULTS.inCombat
local pendingOutOfCombat = DEFAULTS.outOfCombat
local pendingChatMessages = DEFAULTS.chatMessages

-- Print normal addon messages (always enabled).
local function PrintMessage(message)

    print("|cff00ff00CombatWeather:|r " .. message)

end

-- Print weather density messages only when enabled.
local function PrintWeatherMessage(message)

    if settings and settings.chatMessages then

        print("|cff00ff00CombatWeather:|r " .. message)

    end

end

-- Apply weather density.
local function ApplyWeatherDensity()

    if not settings then
        return
    end

    local density

    if UnitAffectingCombat("player") then
        density = settings.inCombat
    else
        density = settings.outOfCombat
    end

    local currentDensity = GetCVar("weatherDensity")

    if tonumber(currentDensity) ~= density then

        SetCVar("weatherDensity", density)

        PrintWeatherMessage(
            "Weather Density set to: " .. density
        )

    end

end

-- Initialize saved settings.
local function InitializeSettings()

    if type(CombatWeatherDB) ~= "table" then
        CombatWeatherDB = {}
    end

    settings = CombatWeatherDB

    if type(settings.inCombat) ~= "number"
        or settings.inCombat < 0
        or settings.inCombat > 3
        or settings.inCombat ~= math.floor(settings.inCombat) then

        settings.inCombat = DEFAULTS.inCombat

    end

    if type(settings.outOfCombat) ~= "number"
        or settings.outOfCombat < 0
        or settings.outOfCombat > 3
        or settings.outOfCombat ~= math.floor(settings.outOfCombat) then

        settings.outOfCombat = DEFAULTS.outOfCombat

    end

    if type(settings.chatMessages) ~= "boolean" then
        settings.chatMessages = DEFAULTS.chatMessages
    end

end

-- Refresh dropdown selections.
local function RefreshDropdowns()

    if combatDropdown then

        UIDropDownMenu_SetSelectedValue(
            combatDropdown,
            pendingInCombat
        )

        UIDropDownMenu_SetText(
            combatDropdown,
            tostring(pendingInCombat)
        )

    end

    if outOfCombatDropdown then

        UIDropDownMenu_SetSelectedValue(
            outOfCombatDropdown,
            pendingOutOfCombat
        )

        UIDropDownMenu_SetText(
            outOfCombatDropdown,
            tostring(pendingOutOfCombat)
        )

    end

    if chatMessagesCheckbox then
        chatMessagesCheckbox:SetChecked(pendingChatMessages)
    end

end

-- Create a weather density dropdown.
local function CreateDensityDropdown(
    name,
    parent,
    label,
    yOffset,
    getter,
    setter
)

    local text = parent:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontNormal"
    )

    text:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        20,
        yOffset
    )

    text:SetText(label)

    local dropdown = CreateFrame(
        "Frame",
        name,
        parent,
        "UIDropDownMenuTemplate"
    )

    dropdown:SetPoint(
        "TOPLEFT",
        text,
        "BOTTOMLEFT",
        -16,
        -5
    )

    UIDropDownMenu_SetWidth(dropdown, 100)

    UIDropDownMenu_Initialize(dropdown, function(self, level)

        for value = 0, 3 do

            local info = UIDropDownMenu_CreateInfo()

            info.text = tostring(value)
            info.value = value

            info.func = function()

                setter(value)

                UIDropDownMenu_SetSelectedValue(
                    dropdown,
                    value
                )

                UIDropDownMenu_SetText(
                    dropdown,
                    tostring(value)
                )

            end

            info.checked = getter() == value

            UIDropDownMenu_AddButton(info, level)

        end

    end)

    UIDropDownMenu_SetSelectedValue(
        dropdown,
        getter()
    )

    UIDropDownMenu_SetText(
        dropdown,
        tostring(getter())
    )

    return dropdown

end

-- Create the standalone options window.
local function CreateOptionsPanel()

    panel = CreateFrame(
        "Frame",
        "CombatWeatherOptionsPanel",
        UIParent,
        "BackdropTemplate"
    )

    panel:SetSize(360, 360)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)

    -- Background and border.
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {
            left = 11,
            right = 12,
            top = 12,
            bottom = 11,
        },
    })

    panel:SetBackdropColor(1, 1, 1, 1)

    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")

    panel:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Title.
    local title = panel:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontNormalLarge"
    )

    title:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        20,
        -20
    )

    title:SetText("CombatWeather")

    -- Description.
    local description = panel:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontHighlight"
    )

    description:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -12
    )

    description:SetText(
        "Configure weather density depending on combat status."
    )

    -- Close button.
    local closeButton = CreateFrame(
        "Button",
        nil,
        panel,
        "UIPanelCloseButton"
    )

    closeButton:SetPoint(
        "TOPRIGHT",
        panel,
        "TOPRIGHT",
        -2,
        -2
    )

    -- In-combat dropdown.
    combatDropdown = CreateDensityDropdown(
        "CombatWeatherCombatDropdown",
        panel,
        "In Combat Weather Density",
        -85,
        function()
            return pendingInCombat
        end,
        function(value)
            pendingInCombat = value
        end
    )

    -- Out-of-combat dropdown.
    outOfCombatDropdown = CreateDensityDropdown(
        "CombatWeatherOutOfCombatDropdown",
        panel,
        "Out of Combat Weather Density",
        -165,
        function()
            return pendingOutOfCombat
        end,
        function(value)
            pendingOutOfCombat = value
        end
    )

    -- Chat messages checkbox.
    chatMessagesCheckbox = CreateFrame(
        "CheckButton",
        "CombatWeatherChatMessagesCheckbox",
        panel,
        "UICheckButtonTemplate"
    )

    chatMessagesCheckbox:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        18,
        -235
    )

    chatMessagesCheckbox:SetChecked(pendingChatMessages)

    local checkboxText = chatMessagesCheckbox:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontNormal"
    )

    checkboxText:SetPoint(
        "LEFT",
        chatMessagesCheckbox,
        "RIGHT",
        0,
        0
    )

    checkboxText:SetText("Enable Chat Messages")

    chatMessagesCheckbox:SetScript("OnClick", function(self)

        pendingChatMessages = self:GetChecked() and true or false

        -- Save preference immediately.
        settings.chatMessages = pendingChatMessages

    end)

    -- Defaults button.
    local defaultsButton = CreateFrame(
        "Button",
        nil,
        panel,
        "UIPanelButtonTemplate"
    )

    defaultsButton:SetSize(140, 28)

    defaultsButton:SetPoint(
        "BOTTOMLEFT",
        panel,
        "BOTTOMLEFT",
        20,
        25
    )

    defaultsButton:SetText("Defaults")

    defaultsButton:SetScript("OnClick", function()

        pendingInCombat = DEFAULTS.inCombat
        pendingOutOfCombat = DEFAULTS.outOfCombat
        pendingChatMessages = DEFAULTS.chatMessages

        RefreshDropdowns()

        -- Apply checkbox preference immediately.
        settings.chatMessages = pendingChatMessages

        PrintMessage(
            "Default values restored. Click Save to apply."
        )

    end)

    -- Save button.
    local saveButton = CreateFrame(
        "Button",
        nil,
        panel,
        "UIPanelButtonTemplate"
    )

    saveButton:SetSize(140, 28)

    saveButton:SetPoint(
        "LEFT",
        defaultsButton,
        "RIGHT",
        15,
        0
    )

    saveButton:SetText("Save")

    saveButton:SetScript("OnClick", function()

        settings.inCombat = pendingInCombat
        settings.outOfCombat = pendingOutOfCombat
        settings.chatMessages = pendingChatMessages

        PrintMessage("Settings saved.")

        ApplyWeatherDensity()

    end)

    -- Refresh settings whenever the window opens.
    panel:SetScript("OnShow", function()

        pendingInCombat = settings.inCombat
        pendingOutOfCombat = settings.outOfCombat
        pendingChatMessages = settings.chatMessages

        RefreshDropdowns()

    end)

    panel:Hide()

end

-- Register CombatWeather in WoW Interface Options.
local function RegisterOptionsCategory()

    local categoryPanel = CreateFrame(
        "Frame",
        "CombatWeatherCategoryPanel",
        UIParent
    )

    categoryPanel.name = "CombatWeather"

    local title = categoryPanel:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontNormalLarge"
    )

    title:SetPoint(
        "TOPLEFT",
        categoryPanel,
        "TOPLEFT",
        16,
        -16
    )

    title:SetText("CombatWeather")

    local description = categoryPanel:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontHighlight"
    )

    description:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -15
    )

    description:SetText(
        "CombatWeather automatically adjusts weather density based on combat status.\n\n"
        .. "Type /cw to open the CombatWeather settings window."
    )

    local openButton = CreateFrame(
        "Button",
        nil,
        categoryPanel,
        "UIPanelButtonTemplate"
    )

    openButton:SetSize(180, 30)

    openButton:SetPoint(
        "TOPLEFT",
        description,
        "BOTTOMLEFT",
        0,
        -20
    )

    openButton:SetText("Open CombatWeather Options")

    openButton:SetScript("OnClick", function()

        if panel then
            panel:Show()
        end

    end)

    -- Register options category.
    if InterfaceOptions_AddCategory then

        InterfaceOptions_AddCategory(categoryPanel)

    elseif Settings
        and Settings.RegisterCanvasLayoutCategory then

        local category = Settings.RegisterCanvasLayoutCategory(
            categoryPanel,
            "CombatWeather"
        )

        Settings.RegisterAddOnCategory(category)

    end

end

-- Main event handler.
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg1)

    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then

        InitializeSettings()
        CreateOptionsPanel()
        RegisterOptionsCategory()

        PrintMessage(
            "Loaded successfully. Type /cw to open settings."
        )

    elseif event == "PLAYER_ENTERING_WORLD" then

        ApplyWeatherDensity()

    elseif event == "PLAYER_REGEN_DISABLED" then

        ApplyWeatherDensity()

    elseif event == "PLAYER_REGEN_ENABLED" then

        ApplyWeatherDensity()

    end

end)

-- Slash commands.
SLASH_COMBATWEATHER1 = "/combatweather"
SLASH_COMBATWEATHER2 = "/cw"

SlashCmdList["COMBATWEATHER"] = function()

    if not panel then

        PrintMessage("Options are not initialized yet.")

        return

    end

    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end

end
