//Render After Images
//GingerBeard @ May 12th, 2026

// A generic script to have a cool after-image effect on a blob.
// Not all spritelayers may be rendered and will require modification if necessary.
// To toggle this effect on a blob, use 'this.set_bool("after_images", true);' 

#define CLIENT_ONLY

const u8 MAX_AFTERIMAGES = 8;
const u8 ALPHA_DECAY = 28;
const u8 SPAWN_INTERVAL = 2;

shared class AfterImage
{
	Vec2f pos;
	f32 angle;
	u8 alpha;
	AfterImage(Vec2f pos, f32 angle)
	{
		this.pos = pos;
		this.angle = angle;
		this.alpha = 190;
	}
}

void onInit(CBlob@ this)
{
	AfterImage@[] images;
	this.set("afterimages", images);

	Render::addBlobScript(Render::layer_objects, this, "RenderAfterImages.as", "RenderAfterImagesFunction");
}

void onTick(CBlob@ this)
{
	if (!isClient()) return;

	AfterImage@[]@ images;
	if (!this.get("afterimages", @images)) return;

	if (getGameTime() % SPAWN_INTERVAL == 0)
	{
		if (this.get_bool("after_images"))
		{
			AfterImage image(this.getInterpolatedPosition(), this.getAngleDegrees());
			images.push_back(image);
		}

		while (images.length > MAX_AFTERIMAGES)
		{
			images.removeAt(0);
		}
	}

	// fade old images
	for (int i = images.length - 1; i >= 0; i--)
	{
		images[i].alpha = Maths::Max(0, images[i].alpha - ALPHA_DECAY);

		if (images[i].alpha == 0)
		{
			images.removeAt(i);
		}
	}
}

void RenderAfterImagesFunction(CBlob@ this, int id)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	AfterImage@[]@ images;
	if (!this.get("afterimages", @images)) return;

	RenderSprite(images, this, sprite);
	RenderHead(images, this, sprite);
}

void RenderSprite(AfterImage@[]@ images, CBlob@ this, CSprite@ sprite)
{
	if (!sprite.isVisible()) return;

	const bool original = Texture::exists(sprite.getTextureName());

	const string texture_name = original ? sprite.getTextureName() : getFilenameWithoutPath(sprite.getFilename());
	if (!Texture::exists(texture_name))
	{
		Texture::createFromFile(texture_name, sprite.getFilename());
		return;
	}

	RenderLayer(images, texture_name, sprite.getFrame(), sprite.getFrameWidth(), sprite.getFrameHeight(), sprite.getOffset(), sprite.isFacingLeft());
}

void RenderHead(AfterImage@[]@ images, CBlob@ this, CSprite@ sprite)
{
	CSpriteLayer@ head = sprite.getSpriteLayer("head");
	if (head is null) return;

	if (!head.isVisible()) return;

	const string texture_name = getFilenameWithoutPath(head.getFilename());
	if (!Texture::exists(texture_name))
	{
		Texture::createFromFile(texture_name, head.getFilename());
		return;
	}

	RenderLayer(images, texture_name, head.getFrame(), head.getFrameWidth(), head.getFrameHeight(), head.getOffset(), head.isFacingLeft());
}

void RenderLayer(AfterImage@[]@ images, const string&in texture, const int&in frame, const int&in frame_width, const int&in frame_height, Vec2f offset, const bool&in facing_left)
{
	Vec2f frame_size(frame_width, frame_height);

	const int texWidth = Texture::width(texture);
	const int texHeight = Texture::height(texture);

	const int columns = texWidth / frame_size.x;

	const int frameX = frame % columns;
	const int frameY = frame / columns;

	Vec2f uv0(
		(frameX * frame_size.x) / texWidth,
		(frameY * frame_size.y) / texHeight
	);

	Vec2f uv1(
		((frameX + 1) * frame_size.x) / texWidth,
		((frameY + 1) * frame_size.y) / texHeight
	);

	Render::SetAlphaBlend(true);
	Render::SetTransformWorldspace();

	for (u16 i = 0; i < images.length; i++)
	{
		AfterImage@ img = images[i];

		Vec2f half = frame_size * 0.5f;

		Vec2f tl(-half.x, -half.y);
		Vec2f tr( half.x, -half.y);
		Vec2f br( half.x,  half.y);
		Vec2f bl(-half.x,  half.y);

		tl.RotateBy(img.angle);
		tr.RotateBy(img.angle);
		br.RotateBy(img.angle);
		bl.RotateBy(img.angle);

		tl += img.pos + offset;
		tr += img.pos + offset;
		br += img.pos + offset;
		bl += img.pos + offset;

		if (facing_left)
		{
			const f32 left = tl.x;
			const f32 right = tr.x;
			tl.x = right;
			tr.x = left;
			br.x = left;
			bl.x = right;
		}

		Vec2f[] verts =
		{
			tl,
			tr,
			br,
			bl
		};

		Vec2f[] uvs =
		{
			uv0,
			Vec2f(uv1.x, uv0.y),
			uv1,
			Vec2f(uv0.x, uv1.y)
		};

		SColor col(img.alpha, 255, 255, 255);
		SColor[] v_col(4, col);
		Render::QuadsColored(texture, -1.0f, verts, uvs, v_col);
	}
}
