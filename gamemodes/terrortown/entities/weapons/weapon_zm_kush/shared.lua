if SERVER then
	AddCSLuaFile( "shared.lua" )
end

SWEP.HoldType = "pistol"

if CLIENT then
	SWEP.PrintName = "Kush Sniper"
	SWEP.Slot = 6
	SWEP.Icon = "VGUI/ttt/icon_scout"
    SWEP.EquipMenuData = {
		type = "Weapon",
		desc = "Injekten them 420 double blunts\nFrom a Distance!"
    };
end

if CLIENT then
	local SobelMaterial = Material( "pp/sobel" )
	SobelMaterial:SetTexture( "$fbtexture", render.GetScreenEffectTexture() );
	
	local mat_MotionBlur	= Material( "pp/motionblur" )
	local mat_Screen		= Material( "pp/fb" )
	local tex_MotionBlur	= render.GetMoBlurTex0()

	local NextDraw = 0
	local LastDraw = 0
	
	KushMode = false

	function DrawMotionBlur( addalpha, drawalpha, delay )

		if ( drawalpha == 0 ) then return end
		
		-- Copy the backbuffer to the screen effect texture
		render.UpdateScreenEffectTexture()
		
		-- If it's been a long time then the buffer is probably dirty, update it
		if ( CurTime() - LastDraw > 0.5 ) then
		
			mat_Screen:SetFloat( "$alpha", 1 )
			
			local OldRT = render.GetRenderTarget();
			render.SetRenderTarget( tex_MotionBlur )
				render.SetMaterial( mat_Screen )
				render.DrawScreenQuad()
			render.SetRenderTarget( OldRT )	
		
		end

		-- Set up out materials
		mat_MotionBlur:SetFloat( "$alpha", drawalpha )
		mat_MotionBlur:SetTexture( "$basetexture", tex_MotionBlur )
		
		if ( NextDraw < CurTime() && addalpha > 0 ) then

			NextDraw = CurTime() + delay

			mat_Screen:SetFloat( "$alpha", addalpha )
			local OldRT = render.GetRenderTarget();
			render.SetRenderTarget( tex_MotionBlur )

			render.SetMaterial( mat_Screen )
			render.DrawScreenQuad()

			render.SetRenderTarget( OldRT )

		end


		render.SetMaterial( mat_MotionBlur )
		render.DrawScreenQuad()
		
		LastDraw = CurTime()
		
	end
	
	function DrawSobel( threshold )

		render.UpdateScreenEffectTexture();

		-- update threshold value
		SobelMaterial:SetFloat( "$threshold", threshold );

		render.SetMaterial( SobelMaterial );
		render.DrawScreenQuad();
	
	end


	function DrawMaterialOverlay( texture, refractamount )

		if (texture ~= lastTexture or mat_Overlay == nil) then
			mat_Overlay = Material( texture )
			lastTexture = texture
		end
		
		if (mat_Overlay == nil) then return end

		render.UpdateScreenEffectTexture()

		mat_Overlay:SetFloat("$envmap",			0)
		mat_Overlay:SetFloat("$envmaptint",		0)
		mat_Overlay:SetFloat("$refractamount",	refractamount)
		mat_Overlay:SetInt("$ignorez",		1)

		render.SetMaterial( mat_Overlay )
		render.DrawScreenQuad()
		
	end

	function KushEffects()
		
		if KushMode then
			DrawMotionBlur( 0.2, 0.99, 0.03);
			DrawMaterialOverlay("Effects/tp_eyefx/tp_eyefx", 0.1);
			DrawSobel( 0.2 );
		end
		
	end
	
	function KreateKush()
		if KushMode == false then
			surface.PlaySound( "kush/kush.mp3" ) 
		end
		KushMode = true
		KushEffects()
 
		timer.Create( "ResetKush", 20, 1, function()
			KushMode = false
		end)
	end

	hook.Add( "RenderScreenspaceEffects", "RenderKushEffects", KushEffects )
end

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP1
SWEP.WeaponID = AMMO_STUN
SWEP.Spawnable	= true
SWEP.AdminSpawnable = true

SWEP.Primary.Cone        = 0.0005
SWEP.Primary.Sound = Sound("weapons/usp/usp1.wav")
SWEP.Secondary.Sound = Sound("Default.Zoom")
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 20
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 60
SWEP.Primary.Recoil = .01
SWEP.Primary.Damage = 1
SWEP.Primary.Delay = 1
SWEP.Primary.Ammo = "CombineCannon"
SWEP.AutoSpawnable      = false

SWEP.CanBuy = { ROLE_TRAITOR }

SWEP.HeadshotMultiplier = 10

SWEP.ViewModel = "models/weapons/v_snip_sg550.mdl"
SWEP.WorldModel = "models/weapons/w_snip_sg550.mdl"

SWEP.IronSightsPos = Vector( 5, -15, -2 )
SWEP.IronSightsAng = Vector( -4, 1.37, 3.5 )


function SWEP:ShootBullet( dmg, recoil, numbul, cone )
   local sights = self:GetIronsights()

   numbul = numbul or 1
   cone   = cone   or 0.00005

   -- 10% accuracy bonus when sighting
   cone = sights and (cone * 0.5) or cone

   local bullet = {}
   bullet.Num    = numbul
   bullet.Src    = self.Owner:GetShootPos()
   bullet.Dir    = self.Owner:GetAimVector()
   bullet.Spread = Vector( cone, cone, 0 )
   bullet.Tracer = 4
   bullet.Force  = 5
   bullet.Damage = dmg

   bullet.Callback = function(att, tr, dmginfo)
                        if SERVER or (CLIENT and IsFirstTimePredicted()) then
                           local ent = tr.Entity
                           if (not tr.HitWorld) and IsValid(ent) then
                              local edata = EffectData()

                              edata:SetEntity(ent)
                              edata:SetMagnitude(3)
                              edata:SetScale(2)


                              if SERVER and ent:IsPlayer() then
								
								 ent:SendLua("KreateKush()")
								 
								 
								 PrintMessage( HUD_PRINTTALK, ent:Nick() .. " 420 Blazes it." )
								 
								 ent:SetRenderMode( RENDERMODE_GLOW )
								 ent:AddEffects( EF_ITEM_BLINK );
								 ent:AddEffects( EF_BRIGHTLIGHT );
                              end
                           end
                        end
                     end


   self.Owner:FireBullets( bullet )
   self.Weapon:SendWeaponAnim(self.PrimaryAnim)

   -- Owner can die after firebullets, giving an error at muzzleflash
   if not IsValid(self.Owner) or not self.Owner:Alive() or self.Owner:IsNPC() then return end

   self.Owner:MuzzleFlash()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   if self.Owner:IsNPC() then return end

   if ((game.SinglePlayer() and SERVER) or
       ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted() )) then

      -- reduce recoil if ironsighting
      recoil = sights and (recoil * 0.75) or recoil

      local eyeang = self.Owner:EyeAngles()
      eyeang.pitch = eyeang.pitch - recoil
      self.Owner:SetEyeAngles( eyeang )

   end
end


function SWEP:SetZoom(state)
    if CLIENT then 
       return
    else
       if state then
          self.Owner:SetFOV(20, 0.3)
       else
          self.Owner:SetFOV(0, 0.2)
       end
    end
end

function SWEP:SecondaryAttack()
    if not self.IronSightsPos then return end
    if self.Weapon:GetNextSecondaryFire() > CurTime() then return end
    
    bIronsights = not self:GetIronsights()
    
    self:SetIronsights( bIronsights )
    
    if SERVER then
        self:SetZoom(bIronsights)
     else
        self:EmitSound(self.Secondary.Sound)
    end
    
    self.Weapon:SetNextSecondaryFire( CurTime() + 0.3)
end

function SWEP:PreDrop()
    self:SetZoom(false)
    self:SetIronsights(false)
    return self.BaseClass.PreDrop(self)
end

function SWEP:Reload()
    self.Weapon:DefaultReload( ACT_VM_RELOAD );
    self:SetIronsights( false )
    self:SetZoom(false)
end


function SWEP:Holster()
    self:SetIronsights(false)
    self:SetZoom(false)
    return true
end

if CLIENT then
   local scope = surface.GetTextureID("sprites/scope")
   function SWEP:DrawHUD()
      if self:GetIronsights() then
         surface.SetDrawColor( 0, 0, 0, 255 )
         
         local x = ScrW() / 2.0
         local y = ScrH() / 2.0
         local scope_size = ScrH()

         local gap = 80
         local length = scope_size
         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )

         gap = 0
         length = 50
         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )

         local sh = scope_size / 2
         local w = (x - sh) + 2
         surface.DrawRect(0, 0, w, scope_size)
         surface.DrawRect(x + sh - 2, 0, w, scope_size)

         surface.SetDrawColor(255, 0, 0, 255)
         surface.DrawLine(x, y, x + 1, y + 1)

         surface.SetTexture(scope)
         surface.SetDrawColor(255, 255, 255, 255)

         surface.DrawTexturedRectRotated(x, y, scope_size, scope_size, 0)

      else
         return self.BaseClass.DrawHUD(self)
      end
   end

   function SWEP:AdjustMouseSensitivity()
      return (self:GetIronsights() and 0.2) or nil
   end
end