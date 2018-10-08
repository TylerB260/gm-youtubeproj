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
ENT.RenderGroup = RENDERGROUP_OPAUQE


function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "URL", {KeyName = "url", Edit = {type = "String", min = 1, max = 90, order = 1}})
    self:NetworkVar("String", 1, "URI")
	self:NetworkVar("Float", 0, "FOV", {KeyName = "fov", Edit = {type = "Float", min = 1, max = 90, order = 2}})
    self:NetworkVar("Float", 1, "Brightness", {KeyName = "brightness", Edit = {type = "Float", min = 1, max = 10, order = 3}})
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
	ent:SetPos(tr.HitPos + tr.HitNormal)
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:Initialize()
	if SERVER then
        self:SetModel("models/dav0r/camera.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:PhysWake()
        
        self:SetFOV(45)
        self:SetBrightness(5)
    end
end

function ENT:OnSettingsChanged(varname, oldvalue, newvalue)
	if oldvalue == newvalue then return end
    if varname == "URL" then
        local _, ustart = string.find(newvalue, "[?&]v=")
        if not ustart then _, ustart = string.find(newvalue, "/embed/") end
        local uend = string.find(newvalue, "[?&]", ustart)
        self:SetURI(string.sub(newvalue, ustart + 1, uend))
        self:SetStartTime(CurTime())
        if SERVER then
            net.Start("youtube_proj_update")
                net.WriteEntity(self)
            net.Send(player.GetAll())
        end
    end
end

if not CLIENT then return end

function ENT:Draw()
    self:DrawModel()
    if IsValid(self.html) then
        local hmat = self.html:GetHTMLMaterial()
        if hmat and IsValid(self.proj) then
            self.proj:SetPos(self:LocalToWorld(Vector(8, 0, 0)))
            self.proj:SetAngles(self:GetAngles())
            self.proj:SetTexture(hmat:GetTexture("$basetexture"))
            self.proj:SetFOV(self:GetFOV())
            self.proj:SetBrightness(self:GetBrightness())
            local col = self:GetColor()
            self.proj:SetColor(Color(col.r * 255, col.g * 255, col.b * 255))
            self.proj:Update()
        end
    end
end

function ENT:Load()
    if self.html then self.html:Remove() end
    self.html = vgui.Create("DHTML")
    
    function self.html.OnDocumentReady(panel, url)
        self:Seek()
    end
    
    self.html:SetSize(1024, 768)
    self.html:OpenURL("https://www.youtube.com/embed/" .. self:GetURI() .. "?rel=0&controls=0&showinfo=0&autoplay=1")
    self.html:SetAlpha(0)
    self.html:SetMouseInputEnabled(false)
    
    if self.proj then self.proj:Remove() end
    self.proj = ProjectedTexture()
    self.proj:SetFarZ(1024)
    self.proj:SetEnableShadows(true)
    self.proj:SetTexture("effects/flashlight001")
end

function ENT:Unload()
    if IsValid(self.html) then self.html:Remove() end
    if IsValid(self.proj) then self.proj:Remove() end
end

function ENT:Seek()
    if not self.html then return end
    local seek = CurTime() - self:GetStartTime()
    if self:GetStartTime() == 0 then seek = 0 end
    self.html:Call([[document.getElementsByTagName("video")[0].currentTime = ]] .. seek .. [[]])
end

function ENT:OnRemove()
   self:Unload() 
end

function ENT:Think()
    local thresh = 512
    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    if dist > 512 then
        if not self.outofrange then
            self.outofrange = true 
            self:Unload()
        end
    else
        if self.outofrange then
            self.outofrange = false
            self:Load()
        end
        if IsValid(self.html) and CurTime() - self.lastvolupdate > 0.1 then
            self.html:Call([[document.getElementsByTagName("video")[0].volume = ]] .. math.max(0, 1 - LocalPlayer():GetPos():Distance(cam:GetPos()) / thresh))
            self.lastvolupdate = CurTime()
        end
    end
end

net.Receive("youtube_proj_update", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "youtube_proj" then return end
    ent:Unload()
    ent:Load()
end)
