AddCSLuaFile()

if SERVER then
    util.AddNetworkString("youtube_proj_update")
end

local BaseClass = baseclass.Get("base_anim")

ENT.PrintName = "YouTube Projector"
ENT.Author = "TylerB and Ott"
ENT.Information = "A projector for playing YouTube videos."
ENT.Category = "Fun + Games"

ENT.Editable = true
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "URL", {KeyName = "url", Edit = {type = "String", min = 1, max = 90, order = 1}})
    self:NetworkVar("String", 1, "URI")
	self:NetworkVar("Float", 0, "FOV", {KeyName = "fov", Edit = {type = "Float", min = 1, max = 90, order = 2}})
    self:NetworkVar("Float", 1, "Brightness", {KeyName = "brightness", Edit = {type = "Float", order = 3}})
	self:NetworkVar("Vector", 0, "Color", {KeyName = "color", Edit = {type = "VectorColor", order = 4}})
    self:NetworkVar("Float", 3, "StartTime")

    self:NetworkVarNotify("URL", self.OnSettingsChanged)
	self:NetworkVarNotify("FOV", self.OnSettingsChanged)
    self:NetworkVarNotify("Brightness", self.OnSettingsChanged)
    self:NetworkVarNotify("Color", self.OnSettingsChanged)
end

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end
	local ent = ents.Create(ClassName)
	ent:SetPos(tr.HitPos + tr.HitNormal * size)
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:Initialize()
	if SERVER then
        self:SetModel("models/dav0r/camera.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:PhysWake()
    end
end

function ENT:OnSettingsChanged(varname, oldvalue, newvalue)
	if oldvalue == newvalue then return end
    if varname == "URL" then
        local _, ustart = string.find(newvalue, "[?&]v=")
        if not ustart then _, ustart = string.find(newvalue, "/embed/") end
        local uend = string.find(newvalue, "[?&]", ustart)
        print(string.sub(newvalue, ustart, uend))
        self:SetURI(string.sub(newvalue, ustart, uend))
    end
    if CLIENT then return end
    net.Start("youtube_proj_update")
        net.WriteEntity(self)
    net.Send(player.GetAll())
end

if not CLIENT then return end

function ENT:Draw()
    BaseClass:Draw()
    if self.html then
        local hmat = self.html:GetHTMLMaterial()
        if hmat and self.proj then
            self.proj:SetPos(self:LocalToWorld(Vector(8, 0, 0)))
            self.proj:SetAngles(self:GetAngles())
            self.proj:SetTexture(hmat:GetTexture("$basetexture"))
            self.proj:SetFOV(self:GetFOV())
            self.proj:SetBrightness(self:GetBrightness())
            self.proj:SetColor(self:GetColor() * 255)
            self.prok:Update()
        end
    end
end

function ENT:Load()
    if self.html then self.html:Remove() end
    self.html = vgui.Create("DHTML")
    self.html:SetSize(1024, 768)
    self.html:OpenURL("https://www.youtube.com/embed/" .. self:GetURI() .. "?rel=0&controls=0&showinfo=0&autoplay=1")
    self.html:SetAlpha(0)
    self.html:SetMouseInputEnabled(false)
    
    if self.proj then self.proj:Remove() end
    self.proj = ProjectedTexture()
    self.proj:SetFarZ(1024)
    self.proj:SetEnableShadows(true)
    self.proj:SetTexture("effects/flashlight001")
    
    function self.html.OnDocumentReady(panel, url)
        self:Seek()
    end
end

function ENT:Unload()
    if self.html then self.html:Remove()
    if self.proj then self.proj:Remove()
end

function ENT:Seek()
    ent.html:Call([[document.getElementsByTagName("video")[0].fastSeek(]] .. CurTime() - self:GetStartTime() .. [[)]])
end

net.Receive("youtube_proj_update", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "youtube_proj" then return end
    if ent.html then
        ent.html:OpenURL(self:GetURL())
    end
end)
