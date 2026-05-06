// Scroll Handler
// For making a scrollable list 

bool isScrollLock = false;

class ScrollHandler : EventHandler
{
	Slider@ slider;
	StandardList@ list;
	bool isSlider;
	ScrollHandler(Slider@ slider_, StandardList@ list_, const bool&in isSlider)
	{
		@slider = slider_;
		@list = list_;
		this.isSlider = isSlider;
	}

	void Handle()
	{
		if (isScrollLock) return;

		isScrollLock = true;

		// couple a slider to a list and vice versa
		const int max_scroll_index = Maths::Max(0, list.getAllComponents().length - list.getMaxLines());
		if (isSlider)
		{
			const int closest_index = Maths::Clamp(int(f32(max_scroll_index) * slider.getPercentage()),0, max_scroll_index);

			if (closest_index != list.getScrollIndex())
			{
				list.SetScrollIndex(closest_index);
			}
		}
		else if (max_scroll_index > 0)
		{
			const f32 percent = f32(list.getScrollIndex()) / f32(max_scroll_index);

			if (Maths::Abs(slider.getPercentage() - percent) > 0.001f)
			{
				slider.SetPercentage(percent);
			}
		}

		isScrollLock = false;
	}
}
