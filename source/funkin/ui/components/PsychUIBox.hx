package funkin.ui.components;

typedef UIStyleData = {
	var bgColor:FlxColor;
	var textColor:FlxColor;
	var bgAlpha:Float;
	@:optional var strokeColor:FlxColor;
	@:optional var radius:Float;
}

class PsychUIBox extends FlxSpriteGroup
{
	public static final CLICK_EVENT = "uibox_click";
	public static final MINIMIZE_EVENT = "uibox_minimize"; //called on both minimizing and maximizing
	public static final DRAG_EVENT = "uibox_drag";
	public static final DROP_EVENT = "uibox_drop";
	public var tabs(default, null):Array<PsychUITab> = [];
	
	public var selectedTab(default, set):PsychUITab = null;
	public var selectedIndex(default, set):Int = -1;
	public var selectedName(default, set):String = null;

	public var bg:FlxSprite;

	public var selectedStyle:UIStyleData = {
		bgColor: FlxColor.WHITE,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};
	public var hoverStyle:UIStyleData = {
		bgColor: FlxColor.WHITE,
		textColor: FlxColor.BLACK,
		bgAlpha: 0.6
	};
	public var unselectedStyle:UIStyleData = {
		bgColor: FlxColor.BLACK,
		textColor: FlxColor.WHITE,
		bgAlpha: 0.6
	};

	public var canMove:Bool = true;
	public var canMinimize(default, set):Bool = true;
	public var isMinimized(default, set):Bool = false;
	public var minimizeOnFocusLost:Bool = false;
	public var useDynamicTheme:Bool = true;

	var _themeSignature:String = null;

	public function new(x:Float, y:Float, width:Int, height:Int, tabs:Array<String> = null)
	{
		super(x, y);
		
		bg = new FlxSprite();
		add(bg);
		applyThemeDefaults();

		if(tabs != null)
		{
			for (tab in tabs)
			{
				var createdTab:PsychUITab = new PsychUITab(tab);
				this.tabs.push(createdTab);
				add(createdTab);
			}
		}

		resize(width, height);
		selectedIndex = 0;
		forceCheckNext = true;
	}

	var _draggingPos:FlxPoint;
	var _draggingPoint:FlxPoint;
	var _pressedBox:Bool = false;
	var _draggingBox:Bool = false;
	var _lastTab:PsychUITab;
	var _lastClick:Float = 0;

	public var forceCheckNext:Bool = false;
	public var broadcastBoxEvents:Bool = true;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		refreshTheme();

		_lastClick += elapsed;
		if(!FlxG.mouse.released && _draggingBox && canMove)
		{
			var newPoint:FlxPoint = FlxG.mouse.getPositionInCameraView(camera);
			setPosition(_draggingPos.x - (_draggingPoint.x - newPoint.x), _draggingPos.y - (_draggingPoint.y - newPoint.y));
		}
		else
		{
			var wasDragging:Bool = _draggingBox;
			_draggingPos = null;
			_draggingPoint = null;
			_draggingBox = false;
			if(FlxG.mouse.released)
			{
				if(_pressedBox) forceCheckNext = true;
				_pressedBox = false;
			}
			if(wasDragging && broadcastBoxEvents) PsychUIEventHandler.event(DROP_EVENT, this);
		}

		for (tab in tabs)
		{
			tab.scrollFactor.set(scrollFactor.x, scrollFactor.y);
			tab.text.scrollFactor.set(scrollFactor.x, scrollFactor.y);
		}

		var _ignoreTabUpdate:Bool = false;
		if(forceCheckNext || FlxG.mouse.justMoved || FlxG.mouse.justPressed || FlxG.mouse.justReleased)
		{
			forceCheckNext = false;
			for (tab in tabs)
			{
				if(FlxG.mouse.overlaps(tab, camera))
				{
					tab.applyStyle(hoverStyle);
	
					if(FlxG.mouse.justPressed)
						_pressedBox = true;

					if(!_draggingBox && canMove && _pressedBox && FlxG.mouse.pressed && (Math.abs(FlxG.mouse.deltaScreenX) > 1 || Math.abs(FlxG.mouse.deltaScreenY) > 1))
					{
						_draggingPos = FlxPoint.weak(x, y);
						_draggingPoint = FlxG.mouse.getPositionInCameraView(camera);
						_draggingBox = true;
						if(broadcastBoxEvents) PsychUIEventHandler.event(DRAG_EVENT, this);
					}
					
					if(FlxG.mouse.justReleased && canMinimize && _lastClick < 0.15 && selectedTab == tab && _lastTab == selectedTab)
					{
						_ignoreTabUpdate = true;
						isMinimized = !isMinimized;
						_lastClick = 0;
						//trace('do minimize: $isMinimized');
					}
					
					if(FlxG.mouse.justPressed)
					{
						if(selectedTab != tab)
						{
							isMinimized = false;
							_ignoreTabUpdate = true;
						}
						_lastTab = selectedTab;
						selectedTab = tab;
						_lastClick = 0;
						if(broadcastBoxEvents) PsychUIEventHandler.event(CLICK_EVENT, this);
					}
					else if(selectedTab != tab) continue;
				}
				
				var style:UIStyleData = (selectedTab == tab) ? selectedStyle : unselectedStyle;
				tab.applyStyle(style);
			}
		}

		if(_ignoreTabUpdate)
		{
			if(broadcastBoxEvents)
				PsychUIEventHandler.event(MINIMIZE_EVENT, this);
		}
		else if(selectedTab != null && !isMinimized)
			selectedTab.updateMenu(this, elapsed);

		if(minimizeOnFocusLost && FlxG.mouse.justPressed && !isMinimized && !FlxG.mouse.overlaps(bg, camera))
		{
			isMinimized = true;
			if(broadcastBoxEvents)
				PsychUIEventHandler.event(MINIMIZE_EVENT, this);
		}
	}

	override function set_cameras(v:Array<FlxCamera>)
	{
		for (tab in tabs) tab.cameras = v;
		return super.set_cameras(v);
	}

	override function set_camera(v:FlxCamera)
	{
		for (tab in tabs) tab.camera = v;
		return super.set_camera(v);
	}
			
	override function draw()
	{
		super.draw();

		if(selectedTab != null && !isMinimized)
			selectedTab.drawMenu(this);
	}

	override function destroy()
	{
		tabs = null;
		selectedTab = null;
		super.destroy();
	}

	public function addTab(name:String)
	{
		var createdTab:PsychUITab = new PsychUITab(name);
		tabs.push(createdTab);
		add(createdTab);
		updateTabs();

		if(selectedTab == null)
			selectedTab = createdTab;
	}

	public var tabHeight:Int = 20;
	public var minTabHeight:Int = 20;
	public var minTabWidth:Int = 72;
	var _originalWidth:Int = 0;
	public function updateTabs()
	{
		if (tabs.length < 1)
			return;

		var targetWidth:Int = getResolvedWidth(_originalWidth);
		if (Std.int(bg.width) != targetWidth)
		{
			_originalWidth = targetWidth;
			redrawBackground(_originalWidth, Std.int(Math.max(1, bg.height)));
		}

		var wid:Int = Std.int(bg.width / tabs.length);
		var computedHeight:Int = minTabHeight;
		for (tab in tabs)
			computedHeight = Std.int(Math.max(computedHeight, tab.recommendedHeight(wid, minTabHeight)));

		tabHeight = computedHeight;
		for (num => tab in tabs)
		{
			tab.x = x + wid * num;
			tab.resize(wid, tabHeight);
			tab.cameras = cameras;
		}
	}

	var _originalHeight:Int = 0;
	public function resize(width:Int, height:Int)
	{
		_originalWidth = getResolvedWidth(width);
		_originalHeight = height;
		redrawBackground(_originalWidth, height);
		updateTabs();
	}

	public function resizeBackground(width:Int, height:Int):Void
	{
		redrawBackground(width, height);
	}

	function applyThemeDefaults():Void
	{
		if (!useDynamicTheme)
			return;

		selectedStyle = PsychUISkin.tabSelectedStyle();
		hoverStyle = PsychUISkin.tabHoverStyle();
		unselectedStyle = PsychUISkin.tabIdleStyle();
		_themeSignature = PsychUISkin.signature();
	}

	function refreshTheme(force:Bool = false):Void
	{
		if (!useDynamicTheme)
			return;

		var signature:String = PsychUISkin.signature();
		if (force || _themeSignature != signature)
		{
			applyThemeDefaults();
			redrawBackground(Std.int(bg.width), _originalHeight);
			for (tab in tabs)
			{
				var style:UIStyleData = (selectedTab == tab) ? selectedStyle : unselectedStyle;
				tab.applyStyle(style);
			}
			forceCheckNext = true;
		}
	}

	function redrawBackground(width:Int, height:Int):Void
	{
		PsychUISkin.drawStyledRect(bg, width, height, PsychUISkin.panelStyle());
	}

	inline function getResolvedWidth(width:Int):Int
	{
		if (tabs == null || tabs.length < 1)
			return width;

		return Std.int(Math.max(width, tabs.length * minTabWidth));
	}

	private function set_selectedTab(v:PsychUITab)
	{
		if(v != null)
		{
			@:bypassAccessor selectedName = v.name;
			@:bypassAccessor selectedIndex = tabs.indexOf(v);
		}
		else
		{
			@:bypassAccessor selectedName = null;
			@:bypassAccessor selectedIndex = -1;
		}
		return (selectedTab = v);
	}

	private function set_selectedName(v:String)
	{
		if(v == null || v.trim().length < 1) selectedTab = null;

		for (tab in tabs)
		{
			if(tab.name == v)
			{
				selectedTab = tab;
				return v;
			}
		}
		return null;
	}

	private function set_selectedIndex(v:Int)
	{
		v = Std.int(Math.max(Math.min(v, tabs.length-1), -1));
		if(v > -1) selectedTab = tabs[v];
		else selectedTab = null;
		return v;
	}

	public function getTab(name:String)
	{
		for (tab in tabs)
			if(tab.name == name)
				return tab;

		return null;
	}

	function set_canMinimize(v:Bool)
	{
		isMinimized = false;
		return (canMinimize = v);
	}

	function set_isMinimized(v:Bool)
	{
		var targetHeight:Int = v ? Std.int(Math.max(tabHeight + 4, minTabHeight + 4)) : _originalHeight;
		redrawBackground(_originalWidth, targetHeight);
		forceCheckNext = true;
		return (isMinimized = v);
	}
}