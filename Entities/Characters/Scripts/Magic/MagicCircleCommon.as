// Magic Circle Common
// Gingerbeard @ April 25, 2026

shared class MagicCircleLayer
{
	string file_name = "MagicCircle0.png";
	int frame_width = 204;
	int frame_height = 204;
	f32 scale = 1.0f;
	f32 rotation_speed = 2.0f;
	f32 z = -30.0f;
	SColor col;

	MagicCircleLayer(const string&in file_name, const int&in frame_width, const int&in frame_height, const f32&in scale = 1.0f, const f32&in rotation_speed = 0.0f, SColor&in col = color_white)
	{
		this.file_name = file_name;
		this.frame_width = frame_width;
		this.frame_height = frame_height;
		this.scale = scale;
		this.rotation_speed = rotation_speed;
		this.col = col;
	}
}

shared class MagicCircle
{
	Vec2f position;
	f32 scale_speed = 0.05f;
	f32 current_scale = 0.0f;
	f32 target_scale = 1.0f;
	bool isHUD = false;

	MagicCircleLayer@[] layers;

	MagicCircle(const f32&in scale_speed = 0.05f, const f32&in target_scale = 1.0f, const bool&in isHUD = false)
	{
		this.scale_speed = scale_speed;
		this.target_scale = target_scale;
		this.isHUD = isHUD;
	}

	void AddLayer(MagicCircleLayer@ layer)
	{
		layers.push_back(layer);
	}

	void Setup(CBlob@ caster)
	{
		CSprite@ sprite = caster.getSprite();

		for (int i = 0; i < layers.length; i++)
		{
			MagicCircleLayer@ layer = layers[i];

			CSpriteLayer@ spritelayer = sprite.addSpriteLayer("magic_circle_"+i, layer.file_name, layer.frame_width, layer.frame_height);
			if (spritelayer is null) continue;

			spritelayer.SetIgnoreParentFacing(true);
			spritelayer.SetLighting(false);
			spritelayer.SetRelativeZ(layer.z);
			spritelayer.SetColor(layer.col);
			spritelayer.SetHUD(isHUD);
		}
	}

	void Tick(CBlob@ caster)
	{
		//current_scale = Maths::Min(current_scale + scale_speed, target_scale);

		CSprite@ sprite = caster.getSprite();

		for (int i = 0; i < layers.length; i++)
		{
			MagicCircleLayer@ layer = layers[i];

			CSpriteLayer@ spritelayer = sprite.getSpriteLayer("magic_circle_"+i);
			if (spritelayer is null) continue;

			const f32 scale = layer.scale * current_scale;
			const f32 rotation = f32(getGameTime() % 360) * layer.rotation_speed;

			spritelayer.ResetTransform();
			spritelayer.ScaleBy(scale, scale);
			spritelayer.RotateBy(rotation, Vec2f_zero);

			if (position != Vec2f_zero)
			{
				Vec2f offset = position - caster.getPosition();
				spritelayer.TranslateBy(offset);
			}
		}
	}

	void Remove(CBlob@ caster)
	{
		CSprite@ sprite = caster.getSprite();

		for (int i = 0; i < layers.length; i++)
		{
			sprite.RemoveSpriteLayer("magic_circle_"+i);
		}

		current_scale = 0.0f;
	}
}
