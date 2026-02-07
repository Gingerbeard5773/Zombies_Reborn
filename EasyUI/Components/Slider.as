interface Slider : List
{
    void SetPercentage(float percentage);
    float getPercentage();

    void SetHandleRatio(float ratio);
    float getHandleRatio();
}

class StandardVerticalSlider : Slider, StandardList
{
    private float percentage = 0.0f;
    private float handleRatio = 0.2f;
    private bool pressed = false;
    private float clickOffsetY;

    StandardVerticalSlider()
    {
        error("Initialized StandardVerticalSlider using the default constructor. Use StandardVerticalSlider(EasyUI@ ui) instead.");
        printTrace();

        super(EasyUI());
    }

    StandardVerticalSlider(EasyUI@ ui)
    {
        super(ui);
    }

    void SetPercentage(float percentage)
    {
        percentage = Maths::Clamp01(percentage);

        if (this.percentage == percentage) return;

        this.percentage = percentage;

        DispatchEvent(Event::Percentage);
    }

    float getPercentage()
    {
        return percentage;
    }

    void SetHandleRatio(float ratio)
    {
        ratio = Maths::Clamp01(ratio);

        if (handleRatio == ratio) return;

        handleRatio = ratio;

        DispatchEvent(Event::HandleRatio);
    }

    float getHandleRatio()
    {
        return handleRatio;
    }

    bool canClick()
    {
        return true;
    }

    private bool isHandleHovered()
    {
        Vec2f min = getHandlePosition();
        Vec2f max = min + getHandleSize();
        return isMouseInBounds(min, max);
    }

    private Vec2f getHandlePosition()
    {
        float handleY = (getTrueBounds().y - getHandleSize().y) * percentage;
        return getTruePosition() + Vec2f(0.0f, handleY);
    }

    private Vec2f getHandleSize()
    {
        Vec2f trueBounds = getTrueBounds();
        return Vec2f(trueBounds.x, trueBounds.y * handleRatio);
    }

    private void MoveHandleIfDragging()
    {
        if (!pressed) return;

        Vec2f sliderPos = getTruePosition();
        Vec2f sliderSize = getTrueBounds();
        Vec2f handleSize = getHandleSize();
        Vec2f mousePos = getControls().getInterpMouseScreenPos();

        float handleY = mousePos.y - handleSize.y * clickOffsetY;
        float percentage = (handleY - sliderPos.y) / Maths::Max(sliderSize.y - handleSize.y, 1.0f);

        SetPercentage(percentage);
    }

    void Update()
    {
        if (!isVisible()) return;

        StandardList::Update();

        CControls@ controls = getControls();

        if (!pressed && ui.startedInteractingWith(this) && isHandleHovered())
        {
            // Drag handle relative to cursor if clicking on handle
            pressed = true;
            clickOffsetY = (controls.getInterpMouseScreenPos().y - getHandlePosition().y) / Maths::Max(getHandleSize().y, 1.0f);
            DispatchEvent(Event::StartDrag);
        }

        // Call this here to override any external code updating the percentage
        MoveHandleIfDragging();

        if (pressed && !ui.isInteractingWith(this))
        {
            pressed = false;
            DispatchEvent(Event::EndDrag);
        }
    }

    void Render()
    {
        if (!isVisible()) return;

        // Call this here to make dragging look smooth
        MoveHandleIfDragging();

        Vec2f sliderMin = getTruePosition();
        Vec2f sliderMax = sliderMin + getTrueBounds();
        Vec2f handleMin = getHandlePosition();
        Vec2f handleMax = handleMin + getHandleSize();

        GUI::DrawSunkenPane(sliderMin, sliderMax);

        if (pressed || (isHandleHovered() && ui.canClick(this)))
        {
            GUI::DrawButtonHover(handleMin, handleMax);
        }
        else
        {
            GUI::DrawButton(handleMin, handleMax);
        }

        StandardList::Render();
    }
}

class StandardHorizontalSlider : Slider, StandardList
{
    private float percentage = 0.0f;
    private float handleRatio = 0.2f;
    private bool pressed = false;
    private float clickOffsetX;

    StandardHorizontalSlider()
    {
        error("Initialized StandardHorizontalSlider using the default constructor. Use StandardHorizontalSlider(EasyUI@ ui) instead.");
        printTrace();

        super(EasyUI());
    }

    StandardHorizontalSlider(EasyUI@ ui)
    {
        super(ui);
    }

    void SetPercentage(float percentage)
    {
        percentage = Maths::Clamp01(percentage);

        if (this.percentage == percentage) return;

        this.percentage = percentage;

        DispatchEvent(Event::Percentage);
    }

    float getPercentage()
    {
        return percentage;
    }

    void SetHandleRatio(float ratio)
    {
        handleRatio = Maths::Clamp01(ratio);
    }

    float getHandleRatio()
    {
        return handleRatio;
    }

    bool canClick()
    {
        return true;
    }

    private bool isHandleHovered()
    {
        Vec2f min = getHandlePosition();
        Vec2f max = min + getHandleSize();
        return isMouseInBounds(min, max);
    }

    private Vec2f getHandlePosition()
    {
        float handleX = (getTrueBounds().x - getHandleSize().x) * percentage;
        return getTruePosition() + Vec2f(handleX, 0.0f);
    }

    private Vec2f getHandleSize()
    {
        Vec2f trueBounds = getTrueBounds();
        return Vec2f(trueBounds.x * handleRatio, trueBounds.y);
    }

    private void MoveHandleIfDragging()
    {
        if (!pressed) return;

        Vec2f sliderPos = getTruePosition();
        Vec2f sliderSize = getTrueBounds();
        Vec2f handleSize = getHandleSize();
        Vec2f mousePos = getControls().getInterpMouseScreenPos();

        float handleX = mousePos.x - handleSize.x * clickOffsetX;
        float percentage = (handleX - sliderPos.x) / Maths::Max(sliderSize.x - handleSize.x, 1.0f);

        SetPercentage(percentage);
    }

    void Update()
    {
        if (!isVisible()) return;

        StandardList::Update();

        CControls@ controls = getControls();

        if (!pressed && ui.startedInteractingWith(this) && isHandleHovered())
        {
            // Drag handle relative to cursor if clicking on handle
            pressed = true;
            clickOffsetX = (controls.getInterpMouseScreenPos().x - getHandlePosition().x) / Maths::Max(getHandleSize().x, 1.0f);
            DispatchEvent(Event::StartDrag);
        }

        // Call this here to override any external code updating the percentage
        MoveHandleIfDragging();

        if (pressed && !ui.isInteractingWith(this))
        {
            pressed = false;
            DispatchEvent(Event::EndDrag);
        }
    }

    void Render()
    {
        if (!isVisible()) return;

        // Call this here to make dragging look smooth
        MoveHandleIfDragging();

        Vec2f sliderMin = getTruePosition();
        Vec2f sliderMax = sliderMin + getTrueBounds();
        Vec2f handleMin = getHandlePosition();
        Vec2f handleMax = handleMin + getHandleSize();

        GUI::DrawSunkenPane(sliderMin, sliderMax);

        if (pressed || (isHandleHovered() && ui.canClick(this)))
        {
            GUI::DrawButtonHover(handleMin, handleMax);
        }
        else
        {
            GUI::DrawButton(handleMin, handleMax);
        }

        StandardList::Render();
    }
}
