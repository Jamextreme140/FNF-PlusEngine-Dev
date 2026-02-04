package funkin.modding.modchart.backend.graphics;

import funkin.modding.modchart.backend.graphics.renderers.*;
import funkin.modding.modchart.backend.math.View3D;
import funkin.modding.modchart.engine.PlayField;

class Context {
	public var parent:PlayField;
	public var view:View3D;

	public var arrowRenderer:ArrowRenderer;
	public var holdRenderer:HoldRenderer;
	public var pathRenderer:PathRenderer;

	public function new(parent:PlayField) {
		this.parent = parent;

		arrowRenderer = new ArrowRenderer(parent);
		holdRenderer = new HoldRenderer(parent);
		pathRenderer = new PathRenderer(parent);

		view = new View3D();
	}
}