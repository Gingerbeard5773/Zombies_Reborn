#include "Avatar.as"
#include "Button.as"
#include "Component.as"
#include "EventDispatcher.as"
#include "EventHandlers.as"
#include "Events.as"
#include "Icon.as"
#include "Label.as"
#include "List.as"
#include "Pane.as"
#include "Progress.as"
#include "Slider.as"
#include "Stack.as"
#include "ToggleButton.as"
#include "Utilities.as"

class EasyUI
{
    private Component@[] components;

    private Component@ hovering;
    private Component@ clickable;
    private Component@ scrollableDown;
    private Component@ scrollableUp;
    private Component@ interacting;
    private Component@ prevInteracting;

    private CControls@ controls;

    private u8 debugOutlineThickness = 2;

    EasyUI()
    {
        if (!isClient()) return;

        @controls = getControls();
    }

    void AddComponent(Component@ component)
    {
        if (component is null || !isClient()) return;

        components.push_back(component);
    }

    void RemoveComponent(Component@ component)
    {
        if (component is null || !isClient()) return;

        for (int i = components.size() - 1; i >= 0; i--)
        {
            Component@ other = components[i];
            if (other !is component) continue;

            components.removeAt(i);

            break;
        }
    }

    void SetComponents(Component@[] components)
    {
        if (!isClient()) return;

        this.components = components;
    }

    Component@[]@ GetComponents()
    {
        return components;
    }

    bool isHovering()
    {
        return hovering !is null;
    }

    bool isInteracting()
    {
        return interacting !is null;
    }

    bool hasControl()
    {
        return isHovering() || isInteracting();
    }

    bool canClick(Component@ component)
    {
        return component !is null && component is clickable;
    }

    bool canScrollDown(Component@ component)
    {
        return component !is null && component is scrollableDown;
    }

    bool canScrollUp(Component@ component)
    {
        return component !is null && component is scrollableUp;
    }

    bool isHovering(Component@ component)
    {
        return component !is null && component is hovering;
    }

    bool isInteractingWith(Component@ component)
    {
        return component !is null && component is interacting;
    }

    bool startedInteractingWith(Component@ component)
    {
        return component !is null && component is interacting && component !is prevInteracting;
    }

    private void CacheComponents()
    {
        @hovering = null;
        @clickable = null;
        @scrollableDown = null;
        @scrollableUp = null;

        if (Menu::getMainMenu() !is null || g_videorecording) return;

        for (int i = components.size() - 1; i >= 0; i--)
        {
            TraverseComponentTree(components[i]);
        }
    }

    private void TraverseComponentTree(Component@ component)
    {
        // Component is nonexistent or not being hovered
        if (component is null || !component.isVisible() || !component.isHovering())
        {
            return;
        }

        // Remember scrollable component and if hovering
        Component@ scrollDown = scrollableDown;
        Component@ scrollUp = scrollableUp;
        bool hover = isHovering();

        // Traverse child components
        Component@[] children = component.getComponents();
        for (int i = children.size() - 1; i >= 0; i--)
        {
            TraverseComponentTree(children[i]);
        }

        // Reapply scrollable component if hovering
        if (hover)
        {
            @scrollableDown = scrollDown;
            @scrollableUp = scrollUp;
        }

        if (hovering is null)
        {
            @hovering = component;
        }

        if (clickable is null && component.canClick())
        {
            @clickable = component;
        }

        if (scrollableDown is null && component.canScrollDown())
        {
            @scrollableDown = component;
        }

        if (scrollableUp is null && component.canScrollUp())
        {
            @scrollableUp = component;
        }
    }

    void Update()
    {
        if (!isClient()) return;

        @prevInteracting = interacting;

        if (interacting !is null && !controls.isKeyPressed(KEY_LBUTTON) && !controls.isKeyPressed(KEY_RBUTTON))
        {
            if (canClick(interacting))
            {
                interacting.DispatchEvent(Event::Click);
            }

            interacting.DispatchEvent(Event::Release);

            @interacting = null;
        }

        CacheComponents();

        // These boolean checks are outside the if statement on purpose
        // It fixes an obscure bug with isKeyJustPressed() for right mouse
        // Right mouse was always just pressed when checked directly in if statement
        bool leftPressed = controls.isKeyJustPressed(KEY_LBUTTON);
        bool rightPressed = controls.isKeyJustPressed(KEY_RBUTTON);

        if (interacting is null && clickable !is null && (leftPressed || rightPressed))
        {
            @interacting = clickable;

            interacting.DispatchEvent(Event::Press);
        }

        for (int i = components.size() - 1; i >= 0; i--)
        {
            components[i].Update();
        }
    }

    void Render()
    {
        if (!isClient()) return;

        CacheComponents();

        if (g_videorecording) return;

        Vec2f screenDim = getDriver().getScreenDimensions();

        for (uint i = 0; i < components.size(); i++)
        {
            Component@ component = components[i];

            Vec2f bounds = component.getBounds();
            Vec2f alignment = component.getAlignment();
            Vec2f boundsDiff = screenDim - bounds;

            Vec2f position;
            position.x = boundsDiff.x * alignment.x;
            position.y = boundsDiff.y * alignment.y;

            component.SetPosition(position.x, position.y);
            component.Render();
        }
    }

    void Debug(bool detailed = false)
    {
        if (!isClient() || g_videorecording) return;

        if (hovering !is null)
        {
            if (hovering.getBounds() != hovering.getTrueBounds())
            {
                Vec2f min = hovering.getPosition();
                Vec2f max = min + hovering.getBounds();
                GUI::DrawOutlinedRectangle(min, max, debugOutlineThickness, SColor(255, 100, 100, 100));
            }

            if (hovering.getInnerBounds() != hovering.getTrueBounds())
            {
                Vec2f min = hovering.getInnerPosition();
                Vec2f max = min + hovering.getInnerBounds();
                GUI::DrawOutlinedRectangle(min, max, debugOutlineThickness, SColor(255, 100, 100, 100));
            }
        }

        DrawDebug(scrollableDown, "scrollable", SColor(255, 0, 0, 255), detailed);
        DrawDebug(scrollableUp, "scrollable", SColor(255, 0, 0, 255), detailed);
        DrawDebug(clickable, "clickable", SColor(255, 255, 0, 0), detailed);
        DrawDebug(hovering, "hovering", SColor(255, 255, 165, 0), detailed);
        DrawDebug(interacting, "interacting", SColor(255, 0, 128, 0), detailed);

        if (hovering !is null && detailed)
        {
            if (hovering.getBounds() != hovering.getTrueBounds())
            {
                string[] lines = {
                    "pos: " + hovering.getPosition().toString(),
                    "size: " + hovering.getBounds().toString()
                };
                Vec2f pos = hovering.getPosition() + Vec2f(0, hovering.getBounds().y - debugOutlineThickness);
                DrawDebugLabel(lines, pos, SColor(255, 100, 100, 100));
            }

            if (hovering.getInnerBounds() != hovering.getTrueBounds())
            {
                string[] lines = {
                    "pos: " + hovering.getInnerPosition().toString(),
                    "size: " + hovering.getInnerBounds().toString()
                };
                Vec2f pos = hovering.getInnerPosition() + Vec2f(0, hovering.getInnerBounds().y - debugOutlineThickness);
                DrawDebugLabel(lines, pos, SColor(255, 100, 100, 100));
            }
        }

        if (detailed)
        {
            DrawDebugCursor();
        }
    }

    private void DrawDebug(Component@ component, string text, SColor color, bool detailed = false)
    {
        if (component is null) return;

        DrawDebugOutline(component, color);

        string[] lines = { text };
        if (detailed)
        {
            lines.push_back("pos: " + component.getTruePosition().toString());
            lines.push_back("size: " + component.getTrueBounds().toString());
        }
        DrawDebugLabel(lines, component.getTruePosition(), color);
    }

    private void DrawDebugOutline(Component@ component, SColor color)
    {
        Vec2f min = component.getTruePosition();
        Vec2f max = min + component.getTrueBounds();
        GUI::DrawOutlinedRectangle(min, max, debugOutlineThickness, color);
    }

    private void DrawDebugLabel(string[] lines, Vec2f position, SColor color)
    {
        GUI::SetFont("");

        float dimX = 0.0f;

        for (uint i = 0; i < lines.size(); i++)
        {
            Vec2f dim;
            GUI::GetTextDimensions(lines[i], dim);

            if (dim.x > dimX)
            {
                dimX = dim.x;
            }
        }

        Vec2f padding = Vec2f(2.0f, 0.0f);

        Vec2f min = position - Vec2f(0, 12.0f * lines.size() + padding.y * (lines.size() + 1));
        Vec2f max = position + Vec2f(dimX + padding.x * 2.0f, debugOutlineThickness);

        GUI::DrawRectangle(min, max, color);

        for (uint i = 0; i < lines.size(); i++)
        {
            GUI::DrawText(lines[i], min + padding - Vec2f(3, 1) + Vec2f(0, 12 * i), color_white);
        }
    }

    private void DrawDebugCursor()
    {
        Vec2f mousePos = controls.getInterpMouseScreenPos();
        GUI::DrawRectangle(mousePos - Vec2f(1, 1), mousePos + Vec2f(1, 1), SColor(255, 255, 0, 255));
    }
}
