interface Button : List
{
    bool isPressed();
    bool isDisabled();
}

class StandardButton : Button, StandardList
{
    StandardButton()
    {
        error("Initialized StandardButton using the default constructor. Use StandardButton(EasyUI@ ui) instead.");
        printTrace();

        super(EasyUI());
    }

    StandardButton(EasyUI@ ui)
    {
        super(ui);

        AddEventListener(Event::Click, PlaySoundHandler("menuclick.ogg"));
    }

    bool isPressed()
    {
        return ui.isInteractingWith(this);
    }

    bool isDisabled()
    {
        return false;
    }

    bool canClick()
    {
        return !isDisabled();
    }

    void Render()
    {
        if (!isVisible()) return;

        Vec2f min = getTruePosition();
        Vec2f max = min + getTrueBounds();

        if (ui.canClick(this) || isDisabled())
        {
            if (isPressed() || isDisabled())
            {
                GUI::DrawButtonPressed(min, max);
            }
            else
            {
                GUI::DrawButtonHover(min, max);
            }
        }
        else
        {
            if (isPressed())
            {
                GUI::DrawButtonHover(min, max);
            }
            else
            {
                GUI::DrawButton(min, max);
            }
        }

        StandardList::Render();
    }
}
