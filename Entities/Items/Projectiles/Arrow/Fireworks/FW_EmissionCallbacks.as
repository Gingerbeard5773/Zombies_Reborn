#include "FW_Explosion.as"

void EmitGreenFire(CParticle@ p) 	{Fireworks::MakeFireTrail(p.oldposition, "particle_trail_green.png");}
void EmitBlueFire(CParticle@ p) 	{Fireworks::MakeFireTrail(p.oldposition, "particle_trail_blue.png");}
void EmitPurpleFire(CParticle@ p) 	{Fireworks::MakeFireTrail(p.oldposition, "particle_trail_purple.png");}
void EmitDarkBFire(CParticle@ p) 	{Fireworks::MakeFireTrail(p.oldposition, "particle_trail_darkblue.png");}
void EmitRedFire(CParticle@ p) 		{Fireworks::MakeFireTrail(p.oldposition, "particle_trail_red.png");}
void EmitTealFire(CParticle@ p) 	{Fireworks::MakeFireTrail(p.oldposition, "particle_trail_teal.png");}
void EmitOrangeFire(CParticle@ p) 	{Fireworks::MakeFireTrail(p.oldposition, "particle_trail_orange.png");}
void EmitGreyFire(CParticle@ p) 	{Fireworks::MakeFireTrail(p.oldposition, "particle_trail_grey.png");}

void Explosion(CParticle@ p)
{
	string explodesound;	
	switch (XORRandom(4))
	{
		case 0: explodesound = "FW_Deep1.ogg"; break;
		case 1: explodesound = "FW_Deep2.ogg"; break;
		case 2: explodesound = "FW_Deep3.ogg"; break;
		case 3: explodesound = "FW_PopAndCrackle.ogg"; break;
	}
	Sound::Play2D(explodesound, 1.0, 0.5); // its everywhere 
	//Sound::Play(Sound::getFileVariation("FW_Deep?", 1, 3), p.position );
	Fireworks::Explode(p.oldposition, p.velocity);
}