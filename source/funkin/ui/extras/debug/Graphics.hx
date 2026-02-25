package extras.debug;

class FPSBG extends Bitmap
{
    public function new(Width:Int = 140, Height:Int = 50, Alpha:Float = 0.3){

        super();             				
		
		var color:FlxColor = FlxColor.fromRGB(124, 118, 146, 255);
		
		var shape:Shape = new Shape();
        shape.graphics.beginFill(color);
        shape.graphics.drawRoundRect(0, 0, Width, Height, 10, 10);     
        shape.graphics.endFill();
        
        var BitmapData:BitmapData = new BitmapData(Width, Height, 0x00FFFFFF);
        BitmapData.draw(shape);   
                
        this.bitmapData = BitmapData;
        this.alpha = Alpha;
    }  //说真的，haxe怎么写个贴图在flxgame层这么麻烦
}