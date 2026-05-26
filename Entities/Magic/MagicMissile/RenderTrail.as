// Render Trail for magic missile
// kind of looks like sperm

#define CLIENT_ONLY

const string TEXTURE_NAME = "trail_texture";
const u32 TRAIL_LIFETIME = 60; // ticks before a point disappears
const f32 X_SIZE = 2.0f;

void Setup(SColor ImageColor)
{
	if (Texture::exists(TEXTURE_NAME)) return;

	if (!Texture::createBySize(TEXTURE_NAME, 8, 8))
	{
		error("Failed to create trail texture [RenderTrail]");
		return;
	}

	ImageData@ edit = Texture::data(TEXTURE_NAME);

	for (int i = 0; i < edit.size(); i++)
	{
		edit[i] = ImageColor;

		if (i / edit.width() == 0) //Top 
			edit[i].setAlpha(100);
		else if(i % edit.height() == 0) // Left 
			edit[i].setAlpha(100);
		else if(i % edit.width() == 0)//Right 
			edit[i].setAlpha(100);
		else if(i >= edit.width() * edit.height() - edit.width())//Bottom 
			edit[i].setAlpha(100);
		
		else if(i / edit.width() == 1)//Top
			edit[i].setAlpha(160);
		else if(i % edit.height() == 1)//???? 
			edit[i].setAlpha(160);
		else if(i % edit.width() == 1)//Right?
			edit[i].setAlpha(160);
		else if(i >= edit.width() * edit.height() - edit.width() - edit.width())//Bottom 
			edit[i].setAlpha(160);
	}

	if (!Texture::update(TEXTURE_NAME, edit))
	{
		error("Failed to update trail texture [RenderTrail]");
	}
}

shared class TrailPoint
{
	Vec2f pos;
	u32 time;
};

void onInit(CBlob@ this)
{
	Setup(SColor(220, 255, 255, 255));

	TrailPoint[] trails;
	this.set("trails", trails);

	Render::addBlobScript(Render::layer_objects, this, "RenderTrail.as", "RenderTrailFunction");
}

void onTick(CBlob@ this)
{
	TrailPoint[]@ trails;
	if (!this.get("trails", @trails)) return;

	const u32 now = getGameTime();

	TrailPoint p;
	p.pos = getInterpolatedPosition(this);
	p.time = now;
	trails.push_back(p);

	for (int i = trails.length - 1; i >= 0; i--)
	{
		if (now - trails[i].time > TRAIL_LIFETIME)
		{
			trails.erase(i);
		}
	}
}

Vec2f getInterpolatedPosition(CBlob@ this)
{
	//engine interpolation is not smooth enough to fix the 'jaggedness' caused by server sync
	if (!this.exists("interpolation"))
	{
		this.set_Vec2f("interpolation", this.getPosition());
	}

	const f32 speed = Maths::Min(0.06f + this.getShape().vellen * 0.1f, 0.9f);

	Vec2f old_pos = this.get_Vec2f("interpolation");
	Vec2f pos = Vec2f_lerp(old_pos, this.getInterpolatedPosition(), speed);
	this.set_Vec2f("interpolation", pos);

	return pos;
}

void RenderTrailFunction(CBlob@ this, int id)
{
	TrailPoint[]@ trails;
	if (!this.get("trails", @trails)) return;

	if (trails.length < 2) return;

	const f32 z = this.getSprite().getZ() - 0.1f;
	const u32 now = getGameTime();

	Render::SetAlphaBlend(true);

	Vec2f prevLeft, prevRight;
	bool hasPrev = false;

	for (int i = 0; i < trails.length; i++)
	{
		Vec2f p = trails[i].pos;

		Vec2f dir;
		if (i == 0)
			dir = trails[i+1].pos - p;
		else if (i == trails.length - 1)
			dir = p - trails[i-1].pos;
		else
			dir = trails[i+1].pos - trails[i-1].pos;

		if (dir.LengthSquared() == 0) continue;
		dir.Normalize();

		Vec2f normal(-dir.y, dir.x);

		const f32 t = i / f32(trails.length - 1);

		f32 age = f32(now - trails[i].time) / f32(TRAIL_LIFETIME);
		age = Maths::Clamp(age, 0.0f, 1.0f);

		const f32 lifeFade = 1.0f - age;

		const f32 life = Maths::Min(this.getTickSinceCreated() / 30.0f, 1.0f);
		const f32 exponent = Maths::Lerp(3.0f, 1.0f, life);

		const f32 spatialFade = Maths::Pow(t, exponent);

		const f32 width = X_SIZE * spatialFade * lifeFade;

		Vec2f left  = p - normal * width;
		Vec2f right = p + normal * width;

		if (hasPrev)
		{
			Vec2f[] v_pos;
			Vec2f[] v_uv;

			const f32 prevT = (i - 1) / f32(trails.length - 1);

			v_pos.push_back(prevLeft);
			v_pos.push_back(prevRight);
			v_pos.push_back(right);
			v_pos.push_back(left);

			v_uv.push_back(Vec2f(prevT, 0));
			v_uv.push_back(Vec2f(prevT, 1));
			v_uv.push_back(Vec2f(t, 1));
			v_uv.push_back(Vec2f(t, 0));

			const u8 alpha = u8(255 * lifeFade);
			SColor col(alpha, 255, 255, 255);

			SColor[] v_col(4, col);
			Render::QuadsColored(TEXTURE_NAME, z, v_pos, v_uv, v_col);
		}

		prevLeft = left;
		prevRight = right;
		hasPrev = true;
	}
}
