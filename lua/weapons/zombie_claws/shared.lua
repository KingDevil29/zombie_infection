
-----------------------------------------------------
SWEP.PrintName		    = "Zombie Claws"

SWEP.Author		    = "Devil"

SWEP.Contact                = ""

SWEP.Purpose                = "Kill all those tasty humans!"

SWEP.Instructions           = "left-Click to attack.\nRight-Click to taunt."

SWEP.Category               = "Zombie Infection"



SWEP.Slot					= 0

SWEP.SlotPos				= 4



SWEP.AdminSpawnable         = true

SWEP.Spawnable 		        = true 



SWEP.Primary.ClipSize		= -1

SWEP.Primary.DefaultClip	= -1

SWEP.Primary.Automatic		= true

SWEP.Primary.Ammo			= "none"



SWEP.Secondary.ClipSize		= -1

SWEP.Secondary.DefaultClip	= -1

SWEP.Secondary.Automatic	= false

SWEP.Secondary.Ammo			= "none"



--SWEP.ViewModel            = ""

SWEP.WorldModel             = ""



SWEP.DrawAmmo				= false



function SWEP:PrimaryAttack()

	self:SetNextPrimaryFire(CurTime() +2)

	

	if SERVER then

	    net.Start("doZombieGesture")

	        net.WriteEntity(self.Owner)

			net.WriteInt(ACT_GMOD_GESTURE_RANGE_ZOMBIE, 32)

	    net.Broadcast()

		

		self.Owner:EmitSound("npc/zombie/zo_attack"..math.random(1, 2)..".wav")

		

		timer.Simple(0.5, function()

			if not self:IsValid() then return end

			

			self.Owner:LagCompensation(true)

		

		    local tr = util.TraceHull({ --I don't really know how to use this, but it should work fine...

	            start = self.Owner:GetShootPos(),

	            endpos = self.Owner:GetShootPos() +(self.Owner:GetAimVector() *85),

	            filter = self.Owner           

			})

			

		    self.Owner:LagCompensation(false)



			if tr.Entity ~= NULL then

		        local dmg = DamageInfo()

                

				dmg:SetDamage(math.random(10, 30))

                dmg:SetAttacker(self.Owner)

                dmg:SetInflictor(self)

                dmg:SetDamageForce(self.Owner:GetAimVector())

                dmg:SetDamagePosition(self.Owner:GetPos())

                dmg:SetDamageType(DMG_CLUB)

				

				tr.Entity:DispatchTraceAttack(dmg, tr) --do dmg

				

			    self.Owner:EmitSound("npc/zombie/claw_strike"..math.random(1, 3)..".wav")

		    else

		        self.Owner:EmitSound("npc/zombie/claw_miss"..math.random(1, 2)..".wav")

		    end

		end)

	end

end



function SWEP:SecondaryAttack()

    self:SetNextSecondaryFire(CurTime() +5)



    if SERVER then

		self.Owner:EmitSound("npc/zombie/zombie_voice_idle"..math.random(1, 14)..".wav")

	end

end



function SWEP:Deploy()

    self.Owner:DrawViewModel(false) --don't flood me pls ;-;

end



function SWEP:Initialize()

	self:SetWeaponHoldType("normal")

end
