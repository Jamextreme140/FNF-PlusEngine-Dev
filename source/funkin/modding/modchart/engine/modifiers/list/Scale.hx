package funkin.modding.modchart.engine.modifiers.list;

import funkin.modding.modchart.backend.core.ModifierParameters;
import funkin.modding.modchart.backend.core.VisualParameters;

class Scale extends Modifier {
	public function new(pf) {
		super(pf);

		setPercent('scale', 1, -1);
		setPercent('scaleX', 1, -1);
		setPercent('scaleY', 1, -1);
		setPercent('stretch', 0, -1);
	}

	private inline function applyScale(vis:VisualParameters, params:ModifierParameters, axis:String, realAxis:String) {
		var receptorName = Std.string(params.lane);
		var player = params.player;

		var scale = 1.;
		// Scale
		scale *= getPercent('scale' + axis, player) + getPercent('scale' + axis + receptorName, player);
		scale *= 1 - (getPercent('tiny' + axis, player) + getPercent('tiny' + axis + receptorName, player)) * 0.5;
		// Mini: uniform sub-percent scale reduction, same formula as tiny
		scale *= 1 - (getPercent('mini', player) + getPercent('mini' + receptorName, player)) * 0.5;

		switch (realAxis) {
			case 'x':
				vis.scaleX *= scale;
			case 'y':
				vis.scaleY *= scale;
			default:
				vis.scaleX *= scale;
				vis.scaleY *= scale;
		}
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		var player = params.player;
		var receptorName = Std.string(params.lane);

		applyScale(data, params, '', '');
		applyScale(data, params, 'x', 'x');
		applyScale(data, params, 'y', 'y');

		// stretch sub-mod: compress X and elongate Y (same formula as Troll Engine)
		var stretchV = getPercent('stretch', player) + getPercent('stretch' + receptorName, player);
		if (stretchV != 0) {
			data.scaleX *= 1.0 - 0.5 * stretchV;
			data.scaleY *= 1.0 + stretchV;
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
