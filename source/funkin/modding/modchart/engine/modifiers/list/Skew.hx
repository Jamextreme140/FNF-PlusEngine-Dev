package funkin.modding.modchart.engine.modifiers.list;

import funkin.modding.modchart.backend.core.ModifierParameters;
import funkin.modding.modchart.backend.core.VisualParameters;

class Skew extends Modifier {
	var xID = 0;
	var yID = 0;

	// Per-lane IDs to avoid Std.string(lane) allocations in hot path
	var xLaneIDs:Array<Int>;
	var yLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		xID = findID('skewX');
		yID = findID('skewY');

		final maxKeys = 16;
		xLaneIDs = [for (i in 0...maxKeys) findID('skewX' + i)];
		yLaneIDs = [for (i in 0...maxKeys) findID('skewY' + i)];
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final lane = params.lane;
		final player = params.player;

		data.skewX += getUnsafe(xID, player) + getUnsafe(xLaneIDs[lane], player);
		data.skewY += getUnsafe(yID, player) + getUnsafe(yLaneIDs[lane], player);

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
