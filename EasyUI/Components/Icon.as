interface Icon : Stack
{
    void SetTexture(string texture);
    string getTexture();

    void SetFrameIndex(uint index);
    uint getFrameIndex();

    void SetFrameDim(uint width, uint height);
    Vec2f getFrameDim();

    void SetTeam(uint team);
    uint getTeam();

    void SetColor(SColor color);
    SColor getColor();

    void SetCrop(float top, float right, float bottom, float left);

    void SetFixedAspectRatio(bool fixed);
    bool isFixedAspectRatio();

    void SetClickable(bool clickable);
}

class StandardIcon : Icon, StandardStack
{
    private string texture = "";
    private uint frameIndex = 0;
    private Vec2f frameDim = Vec2f_zero;
    private uint team = 0;
    private SColor color = color_white;
    private float cropTop = 0.0f;
    private float cropRight = 0.0f;
    private float cropBottom = 0.0f;
    private float cropLeft = 0.0f;
    private bool fixedAspectRatio = true;
    private bool clickable = false;

    StandardIcon(string texture, uint frameIndex, Vec2f frameDim, uint team = 0, SColor color = color_white)
    {
        this.texture = texture;
        this.frameIndex = frameIndex;
        this.frameDim = frameDim;
        this.team = team;
        this.color = color;
    }

    void SetTexture(string texture)
    {
        if (this.texture == texture) return;

        this.texture = texture;

        DispatchEvent(Event::Texture);
    }

    string getTexture()
    {
        return texture;
    }

    void SetFrameIndex(uint index)
    {
        if (frameIndex == index) return;

        frameIndex = index;

        DispatchEvent(Event::FrameIndex);
    }

    uint getFrameIndex()
    {
        return frameIndex;
    }

    void SetFrameDim(uint width, uint height)
    {
        if (frameDim.x == width && frameDim.y == height) return;

        frameDim.x = width;
        frameDim.y = height;

        DispatchEvent(Event::FrameDim);
    }

    Vec2f getFrameDim()
    {
        return frameDim;
    }

    void SetTeam(uint team)
    {
        if (this.team == team) return;

        this.team = team;

        DispatchEvent(Event::Team);
    }

    uint getTeam()
    {
        return team;
    }

    void SetColor(SColor color)
    {
        if (this.color == color) return;

        this.color = color;

        DispatchEvent(Event::Color);
    }

    SColor getColor()
    {
        return color;
    }

    void SetCrop(float top, float right, float bottom, float left)
    {
        if (cropTop == top && cropRight == right && cropBottom == bottom && cropLeft == left) return;

        cropTop = top;
        cropRight = right;
        cropBottom = bottom;
        cropLeft = left;

        DispatchEvent(Event::Crop);
    }

    void SetFixedAspectRatio(bool fixed)
    {
        if (fixedAspectRatio == fixed) return;

        fixedAspectRatio = fixed;

        DispatchEvent(Event::FixedAspectRatio);
    }

    bool isFixedAspectRatio()
    {
        return fixedAspectRatio;
    }

    void SetClickable(bool clickable)
    {
        if (this.clickable == clickable) return;

        this.clickable = clickable;

        DispatchEvent(Event::Clickable);
    }

    bool canClick()
    {
        return clickable;
    }

    private Vec2f getCroppedFrameDim()
    {
        return Vec2f(
            frameDim.x - cropLeft - cropRight,
            frameDim.y - cropTop - cropBottom
        );
    }

    private Vec2f getScale()
    {
        Vec2f croppedFrameDim = getCroppedFrameDim();
        Vec2f trueBounds = getTrueBounds();

        Vec2f scale;
        scale.x = croppedFrameDim.x != 0.0f
            ? trueBounds.x / croppedFrameDim.x
            : 0.0f;
        scale.y = croppedFrameDim.y != 0.0f
            ? trueBounds.y / croppedFrameDim.y
            : 0.0f;

        if (fixedAspectRatio)
        {
            float minScale = Maths::Min(scale.x, scale.y);
            scale.Set(minScale, minScale);
        }

        return scale;
    }

    private Vec2f getOffset()
    {
        Vec2f trueBounds = getTrueBounds();
        Vec2f croppedFrameDim = getCroppedFrameDim();
        Vec2f scale = getScale();
        Vec2f scaledFrameDim = Vec2f(
            croppedFrameDim.x * scale.x,
            croppedFrameDim.y * scale.y
        );
        Vec2f scaledCropOffset = Vec2f(
            cropLeft * scale.x,
            cropTop * scale.y
        );

        return (trueBounds - scaledFrameDim) * 0.5f - scaledCropOffset;
    }

    private bool canRender()
    {
        return (
            isVisible() &&
            texture != "" &&
            frameDim.x != 0.0f &&
            frameDim.y != 0.0f
        );
    }

    void Render()
    {
        if (canRender())
        {
            Vec2f scale = getScale() * 0.5f;
            Vec2f offset = getOffset();

            GUI::DrawIcon(texture, frameIndex, frameDim, position + offset, scale.x, scale.y, team, color);
        }

        StandardStack::Render();
    }
}

class AnimatedIcon : StandardIcon
{
    private u8[] animation_frames;
    private u8 animation_speed = 5;

    AnimatedIcon(string texture, uint frameIndex, Vec2f frameDim, uint team = 0, SColor color = color_white)
    {
        super(texture, frameIndex, frameDim, team, color);
    }

    void SetFrames(u8[] animation_frames)
    {
        this.animation_frames = animation_frames;
    }

    void SetSpeed(u8 animation_speed)
    {
        this.animation_speed = animation_speed;
    }

    void Render()
    {
        const u32 time = getGameTime() / animation_speed;
        const u8 frame = time % animation_frames.length;
        frameIndex = animation_frames[frame];

        StandardIcon::Render();
    }
}
