if SERVER then return end

local cam = Entity(2120)

if testhtml then testhtml:Remove() end

testhtml = vgui.Create("DHTML")
testhtml:SetSize(1024, 768)
testhtml:OpenURL("https://www.youtube.com/embed/Bey4XXJAqS8?rel=0&controls=0&showinfo=0&autoplay=1")
testhtml:SetAlpha(0)
testhtml:SetMouseInputEnabled(false)

if testlamp then testlamp:Remove() end

testlamp = ProjectedTexture()
testlamp:SetTexture("effects/flashlight001")
testlamp:SetFarZ(1024)
testlamp:SetFOV(45)
testlamp:SetBrightness(5)
testlamp:SetEnableShadows(true)
testlamp:Update()


hook.Add("PostDrawOpaqueRenderables", "testlamp", function()
    if not testhtml then return end
    
    local html = testhtml:GetHTMLMaterial()
    
    if not html then return end
    
    --testlamp:SetFOV((math.sin(CurTime() * 2) * 30) + 60)
    testlamp:SetPos(cam:LocalToWorld(Vector(8, 0, 0)))
    testlamp:SetAngles(cam:GetAngles())
    testlamp:SetTexture(html:GetTexture("$basetexture"))
    testlamp:Update()
end)
