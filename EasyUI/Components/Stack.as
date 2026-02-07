interface Stack : Component
{

}

class StandardStack : Stack
{
    private Component@ parent;
    private Component@[] components;

    private bool visible = true;
    private Vec2f margin = Vec2f_zero;
    private Vec2f padding = Vec2f_zero;
    private Vec2f alignment = Vec2f_zero;
    private Vec2f minSize = Vec2f_zero;
    private Vec2f maxSize = Vec2f_zero;
    private Vec2f stretchRatio = Vec2f_zero;
    private Vec2f position = Vec2f_zero;

    private Vec2f minBounds = Vec2f_zero;
    private Vec2f bounds = Vec2f_zero;

    private bool calculateMinBounds = true;
    private bool calculateBounds = true;

    private CachedMinBoundsHandler@ minBoundsHandler;
    private CachedBoundsHandler@ boundsHandler;

    private EventDispatcher@ events = StandardEventDispatcher();

    StandardStack()
    {
        @minBoundsHandler = CachedMinBoundsHandler(this);
        @boundsHandler = CachedBoundsHandler(this);
    }

    void AddComponent(Component@ component)
    {
        if (component is null) return;

        components.push_back(component);
        component.SetParent(this);

        // If child minimum bounds changes, update my minimum bounds
        component.AddEventListener(Event::MinBounds, minBoundsHandler);

        CalculateMinBounds();
        DispatchEvent(Event::Components);
    }

    void SetComponents(Component@[] components)
    {
        for (uint i = 0; i < components.size(); i++)
        {
            Component@ component = components[i];
            component.SetParent(null);
            component.RemoveEventListener(Event::MinBounds, minBoundsHandler);
        }

        this.components = components;

        for (uint i = 0; i < components.size(); i++)
        {
            Component@ component = components[i];
            component.SetParent(this);
            component.AddEventListener(Event::MinBounds, minBoundsHandler);
        }

        CalculateMinBounds();
        DispatchEvent(Event::Components);
    }

    void SetVisible(bool visible)
    {
        if (this.visible == visible) return;

        this.visible = visible;

        DispatchEvent(Event::Visibility);
    }

    bool isVisible()
    {
        return visible;
    }

    void SetParent(Component@ parent)
    {
        if (this.parent is parent) return;

        if (this.parent !is null)
        {
            parent.RemoveEventListener(Event::Bounds, boundsHandler);
        }

        @this.parent = parent;

        if (this.parent !is null)
        {
            // If parent bounds changes, update my bounds
            parent.AddEventListener(Event::Bounds, boundsHandler);
        }

        CalculateBounds();
        DispatchEvent(Event::Parent);
    }

    Component@ getParent()
    {
        return parent;
    }

    void SetMargin(float x, float y)
    {
        x = Maths::Max(0, x);
        y = Maths::Max(0, y);

        if (margin.x == x && margin.y == y) return;

        margin.x = x;
        margin.y = y;

        CalculateMinBounds();
        DispatchEvent(Event::Margin);
    }

    Vec2f getMargin()
    {
        return margin;
    }

    void SetPadding(float x, float y)
    {
        x = Maths::Max(0, x);
        y = Maths::Max(0, y);

        if (padding.x == x && padding.y == y) return;

        padding.x = x;
        padding.y = y;

        CalculateMinBounds();
        DispatchEvent(Event::Padding);
    }

    Vec2f getPadding()
    {
        return padding;
    }

    void SetAlignment(float x, float y)
    {
        x = Maths::Clamp01(x);
        y = Maths::Clamp01(y);

        if (alignment.x == x && alignment.y == y) return;

        alignment.x = x;
        alignment.y = y;

        DispatchEvent(Event::Alignment);
    }

    Vec2f getAlignment()
    {
        return alignment;
    }

    void SetMinSize(float width, float height)
    {
        width = Maths::Max(0, width);
        height = Maths::Max(0, height);

        if (minSize.x == width && minSize.y == height) return;

        minSize.x = width;
        minSize.y = height;

        CalculateMinBounds();
        DispatchEvent(Event::MinSize);
    }

    Vec2f getMinSize()
    {
        return minSize;
    }

    void SetMaxSize(float width, float height)
    {
        width = Maths::Max(0, width);
        height = Maths::Max(0, height);

        if (maxSize.x == width && maxSize.y == height) return;

        maxSize.x = width;
        maxSize.y = height;

        CalculateBounds();
        DispatchEvent(Event::MaxSize);
    }

    Vec2f getMaxSize()
    {
        return maxSize;
    }

    void SetStretchRatio(float x, float y)
    {
        x = Maths::Clamp01(x);
        y = Maths::Clamp01(y);

        if (stretchRatio.x == x && stretchRatio.y == y) return;

        stretchRatio.x = x;
        stretchRatio.y = y;

        CalculateBounds();
        DispatchEvent(Event::StretchRatio);
    }

    Vec2f getStretchRatio()
    {
        return stretchRatio;
    }

    void SetPosition(float x, float y)
    {
        if (position.x == x && position.y == y) return;

        position.x = x;
        position.y = y;

        // Position is only used when stretching to fill the screen
        if (parent is null)
        {
            CalculateBounds();
        }

        DispatchEvent(Event::Position);
    }

    Vec2f getPosition()
    {
        return position;
    }

    Vec2f getTruePosition()
    {
        return getPosition() + margin;
    }

    Vec2f getInnerPosition()
    {
        return getTruePosition() + padding;
    }

    Vec2f getMinBounds()
    {
        if (calculateMinBounds)
        {
            calculateMinBounds = false;

            // Get largest child bounds for each axis
            Vec2f maxChildBounds = Vec2f_zero;
            for (uint i = 0; i < components.size(); i++)
            {
                Vec2f childBounds = components[i].getMinBounds();
                if (childBounds.x > maxChildBounds.x)
                {
                    maxChildBounds.x = childBounds.x;
                }
                if (childBounds.y > maxChildBounds.y)
                {
                    maxChildBounds.y = childBounds.y;
                }
            }

            // Add padding and margin while enforcing minimum size
            minBounds.x = Maths::Max(maxChildBounds.x + padding.x * 2.0f, minSize.x) + margin.x * 2.0f;
            minBounds.y = Maths::Max(maxChildBounds.y + padding.y * 2.0f, minSize.y) + margin.y * 2.0f;
        }

        return minBounds;
    }

    Vec2f getBounds()
    {
        if (calculateBounds)
        {
            calculateBounds = false;

            // Use method to get mininmum bounds in case it needs to be recalculated
            Vec2f minBounds = getMinBounds();

            // Stretch to fill the parent or the screen
            Vec2f stretchBounds = parent !is null
                ? parent.getStretchBounds(this)
                : getDriver().getScreenDimensions();
            stretchBounds *= stretchRatio;

            // Constrain the stretch bounds within the maximum size if configured
            Vec2f maxBounds;
            maxBounds.x = maxSize.x != 0.0f
                ? Maths::Min(stretchBounds.x, maxSize.x + margin.x * 2.0f)
                : stretchBounds.x;
            maxBounds.y = maxSize.y != 0.0f
                ? Maths::Min(stretchBounds.y, maxSize.y + margin.y * 2.0f)
                : stretchBounds.y;

            // Pick the larger bounds
            bounds.x = Maths::Max(minBounds.x, maxBounds.x);
            bounds.y = Maths::Max(minBounds.y, maxBounds.y);
        }

        return bounds;
    }

    Vec2f getTrueBounds()
    {
        return getBounds() - margin * 2.0f;
    }

    Vec2f getInnerBounds()
    {
        return getTrueBounds() - padding * 2.0f;
    }

    Vec2f getStretchBounds(Component@ child)
    {
        return getInnerBounds();
    }

    void CalculateMinBounds()
    {
        if (calculateMinBounds) return;

        calculateMinBounds = true;

        CalculateBounds();
        DispatchEvent(Event::MinBounds);
    }

    void CalculateBounds()
    {
        if (calculateBounds) return;

        calculateBounds = true;

        DispatchEvent(Event::Bounds);
    }

    bool isHovering()
    {
        return ::isHovering(this);
    }

    bool canClick()
    {
        return false;
    }

    bool canScrollDown()
    {
        return false;
    }

    bool canScrollUp()
    {
        return false;
    }

    Component@[] getComponents()
    {
        return components;
    }

    void AddEventListener(Event type, EventHandler@ handler)
    {
        events.AddEventListener(type, handler);
    }

    void RemoveEventListener(Event type, EventHandler@ handler)
    {
        events.RemoveEventListener(type, handler);
    }

    void DispatchEvent(Event type)
    {
        events.DispatchEvent(type);
    }

    void Update()
    {
        if (!isVisible()) return;

        DispatchEvent(Event::Update);

        for (int i = components.size() - 1; i >= 0; i--)
        {
            components[i].Update();
        }
    }

    void Render()
    {
        if (!isVisible()) return;

        Vec2f innerPos = getInnerPosition();
        Vec2f innerBounds = getInnerBounds();

        for (uint i = 0; i < components.size(); i++)
        {
            Component@ component = components[i];

            Vec2f childBounds = component.getBounds();
            Vec2f childAlignment = component.getAlignment();
            Vec2f boundsDiff = innerBounds - childBounds;

            Vec2f childPos;
            childPos.x = innerPos.x + boundsDiff.x * childAlignment.x;
            childPos.y = innerPos.y + boundsDiff.y * childAlignment.y;

            component.SetPosition(childPos.x, childPos.y);
            component.Render();
        }
    }
}
