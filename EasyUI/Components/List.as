interface List : Component
{
    void SetSpacing(float x, float y);
    Vec2f getSpacing();

    void SetCellWrap(uint cells);
    uint getCellWrap();

    void SetFlowDirection(FlowDirection direction);
    FlowDirection getFlowDirection();

    void SetMaxLines(uint lines);
    uint getMaxLines();

    void SetScrollIndex(uint index);
    uint getScrollIndex();

    void SetColumnSizes(float[] sizes);
    float[] getColumnSizes();

    void SetRowSizes(float[] sizes);
    float[] getRowSizes();
}

enum FlowDirection
{
    // Top left
    RightDown,
    DownRight,
    // Top right
    LeftDown,
    DownLeft,
    // Bottom left
    RightUp,
    UpRight,
    // Bottom right
    LeftUp,
    UpLeft
}

class StandardList : List, StandardStack
{
    private EasyUI@ ui;

    private Vec2f spacing = Vec2f_zero;
    private uint cellWrap = 1;
    private FlowDirection flowDirection = FlowDirection::RightDown;
    private uint maxLines = 0;
    private uint scrollIndex = 0;
    private float[] columnSizes;
    private float[] rowSizes;

    private float[] minWidths;
    private float[] minHeights;
    private float[] stretchWidths;
    private float[] stretchHeights;

    StandardList()
    {
        error("Initialized StandardList using the default constructor. Use StandardList(EasyUI@ ui) instead.");
        printTrace();
    }

    StandardList(EasyUI@ ui)
    {
        super();

        @this.ui = ui;
    }

    void AddComponent(Component@ component)
    {
        StandardStack::AddComponent(component);
        SetScrollIndex(scrollIndex);
    }

    void SetComponents(Component@[] components)
    {
        StandardStack::SetComponents(components);
        SetScrollIndex(scrollIndex);
    }

    void SetSpacing(float x, float y)
    {
        x = Maths::Max(0, x);
        y = Maths::Max(0, y);

        if (spacing.x == x && spacing.y == y) return;

        spacing.x = x;
        spacing.y = y;

        CalculateMinBounds();
        DispatchEvent(Event::Spacing);
    }

    Vec2f getSpacing()
    {
        return spacing;
    }

    void SetCellWrap(uint cellWrap)
    {
        cellWrap = Maths::Max(cellWrap, 1);

        if (this.cellWrap == cellWrap) return;

        this.cellWrap = cellWrap;

        CalculateMinBounds();
        SetScrollIndex(scrollIndex);
        DispatchEvent(Event::CellWrap);
    }

    uint getCellWrap()
    {
        return cellWrap;
    }

    void SetFlowDirection(FlowDirection direction)
    {
        if (flowDirection == direction) return;

        flowDirection = direction;

        CalculateMinBounds();
        DispatchEvent(Event::FlowDirection);
    }

    FlowDirection getFlowDirection()
    {
        return flowDirection;
    }

    void SetMaxLines(uint maxLines)
    {
        if (this.maxLines == maxLines) return;

        this.maxLines = maxLines;

        CalculateMinBounds();
        SetScrollIndex(scrollIndex);
        DispatchEvent(Event::MaxLines);
    }

    uint getMaxLines()
    {
        return maxLines;
    }

    void SetScrollIndex(uint index)
    {
        if (maxLines > 0 && cellWrap > 0)
        {
            int totalLines = Maths::Ceil(components.size() / float(cellWrap));
            uint hiddenLines = Maths::Max(totalLines - maxLines, 0);

            index = Maths::Min(index, hiddenLines);
        }
        else
        {
            index = 0;
        }

        if (scrollIndex == index) return;

        scrollIndex = index;

        CalculateMinBounds();
        DispatchEvent(Event::ScrollIndex);
    }

    uint getScrollIndex()
    {
        return scrollIndex;
    }

    void SetColumnSizes(float[] sizes)
    {
        columnSizes = sizes;
    }

    float[] getColumnSizes()
    {
        return columnSizes;
    }

    void SetRowSizes(float[] sizes)
    {
        rowSizes = sizes;
    }

    float[] getRowSizes()
    {
        return rowSizes;
    }

    private uint getCellIndex(uint x, uint y)
    {
        if (components.size() > 0)
        {
            switch (flowDirection)
            {
                case FlowDirection::RightDown:
                    return (scrollIndex + y) * cellWrap + x;
                case FlowDirection::RightUp:
                    return (scrollIndex + getVisibleRows() - 1 - y) * cellWrap + x;
                case FlowDirection::LeftDown:
                    return (scrollIndex + y) * cellWrap + (cellWrap - 1 - x);
                case FlowDirection::LeftUp:
                    return (scrollIndex + getVisibleRows() - 1 - y) * cellWrap + (cellWrap - 1 - x);
                case FlowDirection::DownRight:
                    return (scrollIndex + x) * cellWrap + y;
                case FlowDirection::UpRight:
                    return (scrollIndex + getVisibleColumns() - 1 - x) * cellWrap + y;
                case FlowDirection::DownLeft:
                    return (scrollIndex + x) * cellWrap + (cellWrap - 1 - y);
                case FlowDirection::UpLeft:
                    return (scrollIndex + getVisibleColumns() - 1 - x) * cellWrap + (cellWrap - 1 - y);
            }
        }
        return 0;
    }

    private Vec2f getCellOffset(uint x, uint y)
    {
        Vec2f offset;

        // Add spacing
        offset.x = spacing.x * x;
        offset.y = spacing.y * y;

        // Add cell widths
        for (uint xx = 0; xx < x; xx++)
        {
            offset.x += stretchWidths[xx];
        }

        // Add cell heights
        for (uint yy = 0; yy < y; yy++)
        {
            offset.y += stretchHeights[yy];
        }

        return offset;
    }

    private uint getVisibleRows()
    {
        switch (flowDirection)
        {
            case FlowDirection::RightDown:
            case FlowDirection::RightUp:
            case FlowDirection::LeftDown:
            case FlowDirection::LeftUp:
            {
                uint rows = Maths::Max(Maths::Ceil(components.size() / float(cellWrap)) - scrollIndex, 0);
                return maxLines > 0 ? Maths::Min(rows, maxLines) : rows;
            }
            case FlowDirection::DownRight:
            case FlowDirection::DownLeft:
            case FlowDirection::UpRight:
            case FlowDirection::UpLeft:
                return Maths::Min(components.size(), cellWrap);
        }
        return 0;
    }

    private uint getVisibleColumns()
    {
        switch (flowDirection)
        {
            case FlowDirection::RightDown:
            case FlowDirection::RightUp:
            case FlowDirection::LeftDown:
            case FlowDirection::LeftUp:
                return Maths::Min(components.size(), cellWrap);
            case FlowDirection::DownRight:
            case FlowDirection::DownLeft:
            case FlowDirection::UpRight:
            case FlowDirection::UpLeft:
            {
                uint columns = Maths::Max(Maths::Ceil(components.size() / float(cellWrap)) - scrollIndex, 0);
                return maxLines > 0 ? Maths::Min(columns, maxLines) : columns;
            }
        }
        return 0;
    }

    Vec2f getMinBounds()
    {
        if (calculateMinBounds)
        {
            calculateMinBounds = false;

            uint visibleRows = getVisibleRows();
            uint visibleColumns = getVisibleColumns();

            // Calculate min widths of columns and heights of rows
            minWidths = array<float>(visibleColumns, 0.0f);
            minHeights = array<float>(visibleRows, 0.0f);

            for (uint x = 0; x < visibleColumns; x++)
            for (uint y = 0; y < visibleRows; y++)
            {
                uint index = getCellIndex(x, y);
                if (index >= components.size()) continue;

                Vec2f childBounds = components[index].getMinBounds();

                if (childBounds.x > minWidths[x])
                {
                    minWidths[x] = childBounds.x;
                }
                if (childBounds.y > minHeights[y])
                {
                    minHeights[y] = childBounds.y;
                }
            }

            // Calculate min bounds
            minBounds.SetZero();

            // Sum column widths and row heights
            for (uint i = 0; i < visibleColumns; i++)
            {
                minBounds.x += minWidths[i];
            }
            for (uint i = 0; i < visibleRows; i++)
            {
                minBounds.y += minHeights[i];
            }

            // Spacing between components
            if (components.size() > 0)
            {
                minBounds.x += (visibleColumns - 1) * spacing.x;
                minBounds.y += (visibleRows - 1) * spacing.y;
            }

            // Add padding and margin while enforcing minimum size
            minBounds.x = Maths::Max(minBounds.x + padding.x * 2.0f, minSize.x) + margin.x * 2.0f;
            minBounds.y = Maths::Max(minBounds.y + padding.y * 2.0f, minSize.y) + margin.y * 2.0f;
        }

        return minBounds;
    }

    Vec2f getStretchBounds(Component@ child)
    {
        uint visibleRows = getVisibleRows();
        uint visibleColumns = getVisibleColumns();

        stretchWidths = array<float>(visibleColumns, 0.0f);
        stretchHeights = array<float>(visibleRows, 0.0f);

        if (components.size() > 0)
        {
            Vec2f availableStretchBounds = getInnerBounds();
            availableStretchBounds.x -= (visibleColumns - 1) * spacing.x;
            availableStretchBounds.y -= (visibleRows - 1) * spacing.y;

            float columnSizesSum = 0.0f;
            for (uint i = 0; i < columnSizes.size() && i < visibleColumns; i++)
            {
                columnSizesSum += columnSizes[i];
            }

            float rowSizesSum = 0.0f;
            for (uint i = 0; i < rowSizes.size() && i < visibleRows; i++)
            {
                rowSizesSum += rowSizes[i];
            }

            for (uint i = 0; i < visibleColumns; i++)
            {
                float size = i < columnSizes.size() ? columnSizes[i] : 0;
                stretchWidths[i] = columnSizesSum > 0.0f
                    ? availableStretchBounds.x * size / columnSizesSum
                    : availableStretchBounds.x / visibleColumns;
            }

            for (uint i = 0; i < visibleRows; i++)
            {
                float size = i < rowSizes.size() ? rowSizes[i] : 0;
                stretchHeights[i] = rowSizesSum > 0.0f
                    ? availableStretchBounds.y * size / rowSizesSum
                    : availableStretchBounds.y / visibleRows;
            }
        }

        stretchWidths = distributeExcess(stretchWidths, minWidths);
        stretchHeights = distributeExcess(stretchHeights, minHeights);

        for (uint x = 0; x < visibleColumns; x++)
        for (uint y = 0; y < visibleRows; y++)
        {
            uint index = getCellIndex(x, y);
            if (index >= components.size()) continue;

            Component@ component = components[index];
            if (child !is component) continue;

            return Vec2f(stretchWidths[x], stretchHeights[y]);
        }

        return Vec2f_zero;
    }

    // For a list of sizes, determine which sizes exceed their minimum
    // size and distribute the excess to the other sizes. If all
    // excess has been distributed or if the minimum sizes make it
    // impossible to distribute the excess, terminate the recursion.
    private float[] distributeExcess(float[] sizes, float[] minSizes)
    {
        uint count = sizes.size();
        float sizesSum = 0.0f;

        // Accumulate excess size that needs redistributing
        float excess = 0.0f;
        uint excessCount = 0;

        for (uint i = 0; i < count; i++)
        {
            float size = sizes[i];
            float minSize = minSizes[i];

            if (minSize >= size)
            {
                excess += minSize - size;
                excessCount++;
                sizes[i] = minSize;
            }
            else
            {
                sizesSum += size;
            }
        }

        // All excess has been distributed or all sizes have excess
        if (excess == 0.0f || excessCount == count)
        {
            return sizes;
        }

        // Redistribute excess size
        for (uint i = 0; i < count; i++)
        {
            float size = sizes[i];
            float minSize = minSizes[i];

            if (minSize < size)
            {
                sizes[i] -= excess * size / sizesSum;
            }
        }

        // Recurse
        return distributeExcess(sizes, minSizes);
    }

    private bool canScroll()
    {
        return maxLines > 0 && components.size() / float(cellWrap) > maxLines;
    }

    bool canScrollDown()
    {
        if (maxLines == 0) return false;

        int totalLines = Maths::Ceil(components.size() / float(cellWrap));
        uint hiddenLines = Maths::Max(totalLines - maxLines, 0);

        return hiddenLines > 0 && scrollIndex  < hiddenLines;
    }

    bool canScrollUp()
    {
        if (maxLines == 0) return false;

        int totalLines = Maths::Ceil(components.size() / float(cellWrap));
        uint hiddenLines = Maths::Max(totalLines - maxLines, 0);

        return hiddenLines > 0 && scrollIndex > 0;
    }

    Component@[] getAllComponents()
    {
        return components;
    }

    Component@[] getComponents()
    {
        if (canScroll())
        {
            uint visibleRows = getVisibleRows();
            uint visibleColumns = getVisibleColumns();

            Component@[] visibleComponents;

            for (uint x = 0; x < visibleColumns; x++)
            for (uint y = 0; y < visibleRows; y++)
            {
                uint index = getCellIndex(x, y);
                if (index >= components.size()) continue;

                visibleComponents.push_back(components[index]);
            }

            return visibleComponents;
        }

        return components;
    }

    void Update()
    {
        if (!isVisible()) return;

        DispatchEvent(Event::Update);

        CControls@ controls = getControls();

        if (canScrollDown() && ui.canScrollDown(this) && controls.mouseScrollDown)
        {
            SetScrollIndex(scrollIndex + 1);
        }

        if (canScrollUp() && ui.canScrollUp(this) && controls.mouseScrollUp && scrollIndex > 0)
        {
            SetScrollIndex(scrollIndex - 1);
        }

        uint visibleRows = getVisibleRows();
        uint visibleColumns = getVisibleColumns();

        for (uint x = 0; x < visibleColumns; x++)
        for (uint y = 0; y < visibleRows; y++)
        {
            uint index = getCellIndex(x, y);
            if (index >= components.size()) continue;

            components[index].Update();
        }
    }

    void Render()
    {
        if (!isVisible()) return;

        Vec2f innerPos = getInnerPosition();

        uint visibleRows = getVisibleRows();
        uint visibleColumns = getVisibleColumns();

        for (uint x = 0; x < visibleColumns; x++)
        for (uint y = 0; y < visibleRows; y++)
        {
            uint index = getCellIndex(x, y);
            if (index >= components.size()) continue;

            Component@ component = components[index];

            Vec2f childBounds = component.getBounds();
            Vec2f childAlignment = component.getAlignment();
            Vec2f cellBounds(stretchWidths[x], stretchHeights[y]);
            Vec2f boundsDiff = cellBounds - childBounds;
            Vec2f offset = getCellOffset(x, y);

            Vec2f childPos;
            childPos.x = innerPos.x + offset.x + boundsDiff.x * childAlignment.x;
            childPos.y = innerPos.y + offset.y + boundsDiff.y * childAlignment.y;

            component.SetPosition(childPos.x, childPos.y);
            component.Render();
        }
    }
}
