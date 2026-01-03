package modchart.backend.graphics.renderers;

#if cpp
import modchart.backend.native.ModchartNative;
#end

typedef HoldSegmentOutput = {
	origin:Vector3,
	left:Vector3,
	right:Vector3,
	visuals:VisualParameters,
	depth:Float,
	clipped:Bool
}

@:publicFields
@:structInit
private final class HoldSegment {
	var origin:Vector3;
	var left:Vector3;
	var right:Vector3;
}

final __matrix:Matrix = new Matrix();

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class ModchartHoldRenderer extends ModchartRenderer<FlxSprite> {
	private var __lastHoldSubs:Int = -1;

	var _indices:Null<Vector<Int>> = new Vector<Int>();

	public function new(instance:PlayField) {
		super(instance);

		instance.setPercent('dizzyHolds', 1, -1);
	}

	inline private function __rotateTail(pos:Vector3) {
		if (__parentOutput == null || (__rotateX == 0 && __rotateY == 0 && __rotateZ == 0))
			return pos;

		var tailFactor = pos.subtract(__parentOutput.pos);
		tailFactor = ModchartUtil.rotate3DVector(tailFactor, __rotateX, __rotateY, __rotateZ);
		var output = __parentOutput.pos.add(tailFactor);
		output.z *= 0.001 * Config.Z_SCALE;
		return projection.transformVector(output, __parentOutput.pos);
	}

	/**
	 * Returns the normal points along the hold path at specific hitTime using.
	 *
	 * Based on schmovin' hold system
	 * @param basePos The hold position per default
	 * @see https://en.wikipedia.org/wiki/Unit_circle
	 */
	@:noCompletion
	inline private function getHoldSegment(hold:FlxSprite, basePos:Vector3, params:ArrowData, doClip:Bool = true):HoldSegmentOutput {
		@:privateAccess
		var holdTime = params.hitTime;
		var parentTime = Adapter.instance.getHoldParentTime(hold);
		var clipped = false;

		var holdDistance = params.distance;
		var parentDistance = Math.max(0, parentTime - Adapter.instance.getSongPosition());

		params.hitTime = FlxMath.lerp(parentTime, holdTime, __long);
		params.distance = FlxMath.lerp(parentDistance, holdDistance, __long);

		// not this
		if (doClip && params.hitten && params.distance < 0) {
			params.distance = 0;
			clipped = true;
		}

		final size = hold.frame.frame.width * hold.scale.x * .5;

		var origin:ModifierOutput = instance.modifiers.getPath(basePos.clone(), params);
		var curPoint = origin.pos;
		final depth = (origin.pos.z - 1) * 1000;
		final zScale:Float = curPoint.z != 0 ? (1 / curPoint.z) : 1;
		curPoint.z = 0;

		// before this, bc it fails with optimiz eholds too
		var unit:Vector3;

		if (Config.OPTIMIZE_HOLDS) {
			unit = new Vector3(0, 1, 0);
		} else {
			var next = instance.modifiers.getPath(basePos.clone(), params, 1, false, true);
			next.pos.z = 0;

			// normalized points difference (from 0-1)
			unit = next.pos.subtract(curPoint);
			unit.normalize();
		}

		var quad0 = new Vector3(-unit.y * size, unit.x * size);
		var quad1 = new Vector3(unit.y * size, -unit.x * size);

		final visuals = origin.visuals;
		@:privateAccess
		for (i in 0...2) {
			var quad = i == 0 ? quad0 : quad1;
			var rotation = quad;
			var rotate = __dizzy != 0;

			if (rotate)
				rotation = ModchartUtil.rotate3DVector(quad, 0, visuals.angleY * __dizzy, 0);

			if (visuals.skewX != 0 || visuals.skewY != 0) {
				__matrix.identity();

				__matrix.b = ModchartUtil.tan(visuals.skewY * FlxAngle.TO_RAD);
				__matrix.c = ModchartUtil.tan(visuals.skewX * FlxAngle.TO_RAD);

				rotation.x = __matrix.__transformX(rotation.x, rotation.y);
				rotation.y = __matrix.__transformY(rotation.x, rotation.y);
			}
			rotation.x = rotation.x * zScale * visuals.scaleX;
			rotation.y = rotation.y * zScale * visuals.scaleY;

			var view = new Vector3(rotation.x + curPoint.x, rotation.y + curPoint.y, rotation.z);
			view = __rotateTail(view);
			if (Config.CAMERA3D_ENABLED)
				view = instance.camera3D.applyViewTo(view);
			view.z *= 0.001;

			// The result of the perspective projection of rotation
			var projection = view;

			if (view.z != 0)
				projection = this.projection.transformVector(view);

			quad.x = projection.x;
			quad.y = projection.y;
			quad.z = projection.z;
		}

		return {
			origin: curPoint,
			left: quad0,
			right: quad1,
			visuals: origin.visuals,
			depth: depth,
			clipped: clipped
		};
	}

	private var __long:Float = 0.0;
	private var __rotateX:Float = 0;
	private var __rotateY:Float = 0;
	private var __rotateZ:Float = 0;
	private var __dizzy:Float = 0;
	private var __parentOutput:ModifierOutput;
	private var __centered2:Float = 0;
	private var basePos:Vector3;

	@:noCompletion
	inline private function updateIndices(subdivisionCount:Int) {
		_indices.length = (subdivisionCount * 6);

		for (subdivision in 0...subdivisionCount) {
			var vertexPosition = subdivision * 4;
			var indexCount = subdivision * 6;

			_indices[indexCount] = vertexPosition;
			_indices[indexCount + 1] = vertexPosition + 1;
			_indices[indexCount + 2] = vertexPosition + 3;
			_indices[indexCount + 3] = vertexPosition;
			_indices[indexCount + 4] = vertexPosition + 2;
			_indices[indexCount + 5] = vertexPosition + 3;
		}
	}

	var __lastLong:Float = 0;
	var __lastC2:Float = 0;
	var __lastDizzy:Float = 0;

	var __lastRX:Float = 0;
	var __lastRY:Float = 0;
	var __lastRZ:Float = 0;

	// YOU MOTHERFUCKER
	var __lastPlayer:Int = -1;

	// NotITG/StepMania-style caching
	var __cachedSegments:Map<String, HoldSegmentOutput> = new Map();
	var __segmentPool:Array<HoldSegmentOutput> = [];
	var __needsZBuffer:Bool = false;
	
	// StepMania vertex buffer pooling (reduces GC pressure)
	static var __vertexPool:Array<openfl.Vector<Float>> = [];
	static var __transformPool:Array<Array<ColorTransform>> = [];
	static final MAX_POOL_SIZE:Int = 32;
	
	// Cache optimization
	inline function getPooledSegment():HoldSegmentOutput {
		if (__segmentPool.length > 0) {
			return __segmentPool.pop();
		}
		return {
			origin: new Vector3(),
			left: new Vector3(),
			right: new Vector3(),
			visuals: {
				angleX: 0, angleY: 0, angleZ: 0,
				skewX: 0, skewY: 0, scaleX: 1, scaleY: 1
			},
			depth: 0,
			clipped: false
		};
	}
	
	// StepMania buffer pooling
	inline function getPooledVertexBuffer(size:Int):openfl.Vector<Float> {
		var result:openfl.Vector<Float> = null;
		if (__vertexPool.length > 0) {
			var buf = __vertexPool.pop();
			if (buf.length >= size) {
				// Clear buffer reusing memory
				for (i in 0...size) buf[i] = 0;
				result = buf;
			}
		}
		return result != null ? result : new openfl.Vector<Float>(size, true);
	}
	
	inline function returnVertexBuffer(buf:openfl.Vector<Float>):Void {
		if (__vertexPool.length < MAX_POOL_SIZE) {
			__vertexPool.push(buf);
		}
	}
	
	inline function getPooledTransforms(size:Int):Array<ColorTransform> {
		var result:Array<ColorTransform> = null;
		if (__transformPool.length > 0) {
			var arr = __transformPool.pop();
			if (arr.length >= size) {
				arr.resize(size);
				result = arr;
			}
		}
		if (result == null) {
			result = [];
			result.resize(size);
		}
		return result;
	}
	
	inline function returnTransforms(arr:Array<ColorTransform>):Void {
		if (__transformPool.length < MAX_POOL_SIZE) {
			__transformPool.push(arr);
		}
	}

	override public function prepare(item:FlxSprite):Void {
		if (item.alpha <= 0) {
			return;
		}

		// Early culling check (like StepMania's IsOnScreen)
		if (Config.EARLY_CULLING_ENABLED) {
			@:privateAccess
			var holdTime = Adapter.instance.getTimeFromArrow(item);
			var parentTime = Adapter.instance.getHoldParentTime(item);
			var songPos = Adapter.instance.getSongPosition();
			
			if (holdTime < songPos - 500 && parentTime < songPos - 500) {
				return; // Hold completely off-screen
			}
		}

		Manager.HOLD_SIZE = item.width;
		Manager.HOLD_SIZEDIV2 = item.width * .5;

		// Dynamic subdivisions with LOD based on hold length (StepMania approach)
		var calculatedSubdivisions = Adapter.instance.getHoldSubdivisions(item);
		
		if (Config.DYNAMIC_HOLD_SUBDIVISIONS) {
			@:privateAccess
			var holdLength = Adapter.instance.getHoldLength(item);
			var pixelLength = Math.abs(holdLength * 0.45); // Approximate pixel length
			
			// LOD (Level of Detail) system: reduce quality for very long holds
			var maxSubs:Int = 64;
			if (pixelLength > 3000) maxSubs = 16;       // Extremely long: 16 max
			else if (pixelLength > 2000) maxSubs = 24;  // Very long: 24 max
			else if (pixelLength > 1000) maxSubs = 32;  // Long: 32 max
			else if (pixelLength > 500) maxSubs = 48;   // Medium: 48 max
			
			// Check if we need Z-buffer (wavy/circular effects detected)
			__needsZBuffer = instance.getPercent('drunk', __lastPlayer) != 0 ||
							 instance.getPercent('tipsy', __lastPlayer) != 0 ||
							 instance.getPercent('tornado', __lastPlayer) != 0 ||
							 instance.getPercent('dizzy', __lastPlayer) != 0 ||
							 instance.getPercent('beat', __lastPlayer) != 0 ||
							 instance.getPercent('wave', __lastPlayer) != 0;
			
			if (Config.ADAPTIVE_STEP_SIZE) {
				#if cpp
				// Use native C++ calculation if available (10x faster)
				if (ModchartNative.isNativeAvailable()) {
					calculatedSubdivisions = ModchartNative.calculateSubdivisions(pixelLength, __needsZBuffer, 2, maxSubs);
				} else {
				#end
					// Fallback: StepMania algorithm - 4px with Z-buffer, 16px without
					var stepSize:Float = __needsZBuffer ? 4.0 : 16.0;
					calculatedSubdivisions = Std.int(Math.max(2, Math.min(maxSubs, Math.ceil(pixelLength / stepSize))));
				#if cpp
				}
				#end
			} else {
				// Just clamp to LOD max
				calculatedSubdivisions = Std.int(Math.min(maxSubs, calculatedSubdivisions));
			}
		}
		
		final HOLD_SUBDIVISIONS = calculatedSubdivisions;

		if (__lastHoldSubs != HOLD_SUBDIVISIONS)
			updateIndices(HOLD_SUBDIVISIONS);

		if (__lastHoldSubs == -1)
			__lastHoldSubs = HOLD_SUBDIVISIONS;

		final newInstruction:FMDrawInstruction = {};

		final player = Adapter.instance.getPlayerFromArrow(item);
		final lane = Adapter.instance.getLaneFromArrow(item);

		basePos = ModchartUtil.getHalfPos();
		basePos.x += Adapter.instance.getDefaultReceptorX(lane, player);
		basePos.y += Adapter.instance.getDefaultReceptorY(lane, player);

		// StepMania buffer pooling: reuse allocated buffers
		var vertices:openfl.Vector<Float> = null;
		var transfTotal:Array<ColorTransform> = null;
		
		// Early skip for very long holds if fully off-screen (StepMania technique)
		if (Config.EARLY_CULLING_ENABLED && HOLD_SUBDIVISIONS > 48) {
			var parentY = Adapter.instance.getDefaultReceptorY(lane, player);
			var holdLen = Adapter.instance.getHoldLength(item) * 0.45;
			if (parentY + holdLen < -200 || parentY > FlxG.height + 200) {
				// Entire hold is off-screen, skip expensive calculations
				return;
			}
		}
		
		vertices = getPooledVertexBuffer(8 * HOLD_SUBDIVISIONS);
		transfTotal = getPooledTransforms(HOLD_SUBDIVISIONS);
		var tID = 0;

		var lastData:ArrowData = null;
		var lastSegment:Null<HoldSegmentOutput> = null;

		var alphaTotal:Float = 0.;

		final canUseLast = __lastPlayer == player;

		// refresh global mods percents
		__long = canUseLast ? __lastLong : (__lastLong = instance.getPercent('longHolds', player) - instance.getPercent('shortHolds', player) + 1);
		__centered2 = canUseLast ? __lastC2 : (__lastC2 = instance.getPercent('centered2', player));
		__dizzy = canUseLast ? __lastDizzy : (__lastDizzy = instance.getPercent('dizzyHolds', player));

		__rotateX = canUseLast ? __lastRX : (__lastRX = instance.getPercent('holdRotateX', player));
		__rotateY = canUseLast ? __lastRY : (__lastRY = instance.getPercent('holdRotateY', player));
		__rotateZ = canUseLast ? __lastRZ : (__lastRZ = instance.getPercent('holdRotateZ', player));

		var parentTime = Adapter.instance.getHoldParentTime(item);
		var parentData:ArrowData = {
			hitTime: parentTime,
			// this fixed the clipping gaps
			distance: Math.max(0, parentTime - Adapter.instance.getSongPosition()),
			lane: lane,
			player: player,
			hitten: Adapter.instance.arrowHit(item),
			isTapArrow: true
		};
		if (__rotateX != 0 || __rotateY != 0 || __rotateZ != 0) {
			__parentOutput = instance.modifiers.getPath(basePos.clone(), parentData);
			__parentOutput.pos.z = (__parentOutput.pos.z - 1) * 1000;
		}

		var vertPointer = 0;

		final isHoldEnd:Bool = Adapter.instance.isHoldEnd(item);
		final holdHeight:Float = item.frame.frame.height * item.scale.y * Config.HOLD_END_SCALE;
		final holdTimeInterval:Float = (Adapter.instance.getHoldLength(item) * ((isHoldEnd ? (Config.PREVENT_SCALED_HOLD_END ? 1 : 0.5) * Config.HOLD_END_SCALE : 1))) / HOLD_SUBDIVISIONS;
		var timeScale:Float = 1;
		var firstIteration:Bool = true;
		
		// Batch processing optimization with smart caching
		var segmentCache:Array<HoldSegmentOutput> = [];
		var useCache = Config.HOLD_SEGMENT_CACHE && HOLD_SUBDIVISIONS <= 32;
		
		if (useCache) {
			// Pre-calculate segments for better cache performance
			for (subIndex in 0...HOLD_SUBDIVISIONS + 1) {
				var holdTimeProgress = holdTimeInterval * subIndex * timeScale;
				segmentCache.push(getHoldSegment(item, basePos, getArrowParams(item, holdTimeProgress)));
			}
		}

		for (subIndex in 0...HOLD_SUBDIVISIONS) {
			var holdTimeProgress = holdTimeInterval * subIndex * timeScale;

			var out1:HoldSegmentOutput;
			var out2:HoldSegmentOutput;
			
			// Use cached segments if available
			if (segmentCache.length > 0) {
				out1 = firstIteration ? segmentCache[subIndex] : lastSegment;
				out2 = segmentCache[subIndex + 1];
			} else {
				out1 = firstIteration ? getHoldSegment(item, basePos, lastData != null ? lastData : getArrowParams(item, holdTimeProgress)) : lastSegment;
				out2 = getHoldSegment(item, basePos, (lastData = getArrowParams(item, holdTimeProgress + (holdTimeInterval * timeScale))));
			}

			if (firstIteration) {
				item._z = out1.depth;

				if (isHoldEnd && Config.PREVENT_SCALED_HOLD_END) {
					if (out1.clipped) {
						final rawStart = getHoldSegment(item, basePos, getArrowParams(item, holdTimeProgress), false);
						final rawEnd = out2.clipped ? getHoldSegment(item, basePos, getArrowParams(item, holdTimeProgress + holdTimeInterval), false) : out2;

						final rawLength = (rawEnd.origin - rawStart.origin).length;
						if (rawLength > 0) {
							timeScale = (holdHeight / HOLD_SUBDIVISIONS) / rawLength;
							out2 = getHoldSegment(item, basePos, (lastData = getArrowParams(item, holdTimeInterval * timeScale)));
						}
					} else {
						timeScale = (holdHeight / HOLD_SUBDIVISIONS) / Math.max(0, (out2.origin - out1.origin).length);
						out2 = getHoldSegment(item, basePos, (lastData = getArrowParams(item, holdTimeInterval * timeScale)));
					}
				}
			}

			__lastPlayer = player;
			lastSegment = out2;

			alphaTotal = alphaTotal + out1.visuals.alpha;

			var vertPos = (vertPointer++) * 8;
			vertices[vertPos] = out1.left.x;
			vertices[vertPos + 1] = out1.left.y;
			vertices[vertPos + 2] = out1.right.x;
			vertices[vertPos + 3] = out1.right.y;
			vertices[vertPos + 4] = out2.left.x;
			vertices[vertPos + 5] = out2.left.y;
			vertices[vertPos + 6] = out2.right.x;
			vertices[vertPos + 7] = out2.right.y;

			final negGlow = 1 - out1.visuals.glow;
			final absGlow = out1.visuals.glow * 255;
			transfTotal[tID++] = new ColorTransform(negGlow, negGlow, negGlow, out1.visuals.alpha * item.alpha, Math.round(out1.visuals.glowR * absGlow),
				Math.round(out1.visuals.glowG * absGlow), Math.round(out1.visuals.glowB * absGlow));

			firstIteration = false;
		}

		newInstruction.item = item;
		newInstruction.vertices = vertices;
		newInstruction.indices = _indices;
		newInstruction.uvt = ModchartUtil.getHoldUVT(item, HOLD_SUBDIVISIONS);
		newInstruction.colorData = transfTotal;
		newInstruction.extra = [alphaTotal];

		queue[count++] = newInstruction;

		__lastHoldSubs = HOLD_SUBDIVISIONS;
	}

	override public function shift() {
		var inst = queue[postCount++];
		__drawInstruction(inst);
		
		// StepMania buffer pooling: return buffers to pool after rendering
		if (inst != null) {
			if (inst.vertices != null) returnVertexBuffer(inst.vertices);
			if (inst.colorData != null) returnTransforms(inst.colorData);
		}
	}

	private function __drawInstruction(instruction:FMDrawInstruction) {
		if (instruction == null)
			return;
		final item:FlxSprite = instruction.item;

		final cameras = ModchartUtil.resolveCameras(item);

		@:privateAccess for (camera in cameras) {
			var cTransforms = instruction.colorData.copy();

			if (camera.alpha != 1)
				for (t in cTransforms)
					t.alphaMultiplier *= camera.alpha;

			var item = camera.startTrianglesBatch(item.graphic, item.antialiasing, true, item.blend, true, item.shader);
			item.addGradientTriangles(instruction.vertices, instruction.indices, instruction.uvt, null, camera._bounds, cTransforms);
		}
	}

	inline private function getArrowParams(arrow:FlxSprite, posOff:Float = 0):ArrowData {
		final player = Adapter.instance.getPlayerFromArrow(arrow);
		final lane = Adapter.instance.getLaneFromArrow(arrow);

		final timeC2 = flixel.FlxG.height * 0.25 * __centered2;
		final hitTime = Adapter.instance.getTimeFromArrow(arrow);

		var pos = (hitTime - Adapter.instance.getSongPosition()) + posOff;

		pos += timeC2;

		return {
			__holdSubdivisionOffset: posOff,
			hitTime: hitTime + posOff + timeC2,
			distance: pos,
			lane: lane,
			player: player,
			hitten: Adapter.instance.arrowHit(arrow),
			isTapArrow: true
		};
	}
}
