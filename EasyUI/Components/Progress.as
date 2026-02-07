interface Progress : List
{
    void SetPercentage(float percentage);
    float getPercentage();

    void SetColor(SColor color);
    SColor getColor();

    void SetFillDirection(FillDirection direction);
    FillDirection getFillDirection();
}

enum FillDirection
{
    Right,
    Left,
    Top,
    Bottom
}

class StandardProgress : Progress, StandardList
{
    private float percentage = 0.0f;
    private SColor color = color_white;
    private FillDirection direction = FillDirection::Right;

    StandardProgress(EasyUI@ ui, SColor color = color_white)
    {
        super(ui);

        this.color = color;
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

    void SetFillDirection(FillDirection direction)
    {
        if (this.direction == direction) return;

        this.direction = direction;

        DispatchEvent(Event::FillDirection);
    }

    FillDirection getFillDirection()
    {
        return direction;
    }

    bool canClick()
    {
        return true;
    }

    void Render()
    {
        if (!isVisible()) return;

        Vec2f min = getTruePosition();
        Vec2f max = min + getTrueBounds();

        GUI::DrawPane(min, max, SColor(0xffCCCCCC));

        if (percentage > 0)
        {
            Vec2f bar_min = min;
            Vec2f bar_max = max;

            switch (direction)
            {
                case FillDirection::Right:
                    bar_max.x = bar_min.x + Maths::Max((max.x - min.x) * percentage, 10.0f);
                    break;
                case FillDirection::Left:
                    bar_min.x = bar_max.x - Maths::Max((max.x - min.x) * percentage, 10.0f);
                    break;
                case FillDirection::Bottom:
                    bar_max.y = bar_min.y + Maths::Max((max.y - min.y) * percentage, 10.0f);
                    break;
                case FillDirection::Top:
                    bar_min.y = bar_max.y - Maths::Max((max.y - min.y) * percentage, 10.0f);
                    break;
            }

            GUI::DrawPane(bar_min, bar_max, color);
        }

        StandardList::Render();
    }
}
