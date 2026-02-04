package backend;

#if sys
import sys.net.Socket;
import haxe.io.Bytes;
#end

import haxe.Json;

/**
 * NetworkManager - Handles WebSocket connection for online multiplayer
 * Manages player matchmaking and real-time stats synchronization
 */
class NetworkManager
{
	#if sys
	private static var ws:Dynamic = null; // WebSocket instance
	#end
	
	public static var isConnected:Bool = false;
	public static var isInMatch:Bool = false;
	public static var playerID:String = null;
	public static var roomID:String = null;
	
	// Opponent data received from server
	public static var opponentData:OpponentStats = {
		score: 0,
		accuracy: 0,
		misses: 0,
		combo: 0,
		sicks: 0,
		goods: 0,
		bads: 0,
		shits: 0,
		rating: "N/A",
		playerName: "Waiting..."
	};
	
	// Callbacks
	public static var onConnected:Void->Void = null;
	public static var onDisconnected:Void->Void = null;
	public static var onMatchFound:Void->Void = null;
	public static var onOpponentUpdate:OpponentStats->Void = null;
	public static var onMatchEnd:MatchResult->Void = null;
	
	// Server configuration
	public static var serverURL:String = "ws://localhost:8080";
	
	/**
	 * Connect to the multiplayer server
	 */
	public static function connect(?url:String):Void
	{
		#if sys
		if (url != null) serverURL = url;
		
		try
		{
			trace('Connecting to server: $serverURL');
			
			// Note: This is a placeholder - you'll need to use hxWebSockets library
			// ws = new WebSocket(serverURL);
			// ws.onopen = onOpen;
			// ws.onmessage = onMessage;
			// ws.onclose = onClose;
			// ws.onerror = onError;
			
			// For now, simulate connection
			isConnected = true;
			trace('Connected to server!');
			if (onConnected != null) onConnected();
		}
		catch (e:Dynamic)
		{
			trace('Connection failed: $e');
			isConnected = false;
		}
		#else
		trace('WebSocket not supported on this platform');
		#end
	}
	
	/**
	 * Disconnect from server
	 */
	public static function disconnect():Void
	{
		#if sys
		if (ws != null)
		{
			// ws.close();
			ws = null;
		}
		#end
		
		isConnected = false;
		isInMatch = false;
		roomID = null;
		
		if (onDisconnected != null) onDisconnected();
		trace('Disconnected from server');
	}
	
	/**
	 * Search for a match with specified song and difficulty
	 */
	public static function searchMatch(song:String, difficulty:String):Void
	{
		if (!isConnected)
		{
			trace('Not connected to server!');
			return;
		}
		
		var data = {
			type: "search_match",
			song: song,
			difficulty: difficulty,
			playerName: ClientPrefs.data.playerName != null ? ClientPrefs.data.playerName : "Player"
		};
		
		sendMessage(data);
		trace('Searching for match: $song - $difficulty');
	}
	
	/**
	 * Cancel matchmaking search
	 */
	public static function cancelSearch():Void
	{
		if (!isConnected) return;
		
		var data = {
			type: "cancel_search"
		};
		
		sendMessage(data);
		trace('Cancelled matchmaking search');
	}
	
	/**
	 * Send player stats update to opponent
	 */
	public static function sendStatsUpdate(stats:PlayerStats):Void
	{
		if (!isConnected || !isInMatch) return;
		
		var data = {
			type: "stats_update",
			roomID: roomID,
			stats: stats
		};
		
		sendMessage(data);
	}
	
	/**
	 * Notify server that song has ended
	 */
	public static function sendSongEnd(finalStats:PlayerStats):Void
	{
		if (!isConnected || !isInMatch) return;
		
		var data = {
			type: "song_end",
			roomID: roomID,
			finalStats: finalStats
		};
		
		sendMessage(data);
		trace('Song ended - sent final stats');
	}
	
	/**
	 * Send message to server
	 */
	private static function sendMessage(data:Dynamic):Void
	{
		#if sys
		if (ws == null) return;
		
		try
		{
			var json = Json.stringify(data);
			// ws.send(json);
			trace('Sent: $json');
		}
		catch (e:Dynamic)
		{
			trace('Failed to send message: $e');
		}
		#end
	}
	
	/**
	 * Handle incoming messages from server
	 */
	private static function handleMessage(message:String):Void
	{
		try
		{
			var data:Dynamic = Json.parse(message);
			
			switch (data.type)
			{
				case "connected":
					playerID = data.playerID;
					trace('Received player ID: $playerID');
				
				case "match_found":
					isInMatch = true;
					roomID = data.roomID;
					opponentData.playerName = data.opponentName;
					trace('Match found! Room: $roomID, Opponent: ${data.opponentName}');
					if (onMatchFound != null) onMatchFound();
				
				case "opponent_stats":
					// Update opponent data
					opponentData.score = data.stats.score;
					opponentData.accuracy = data.stats.accuracy;
					opponentData.misses = data.stats.misses;
					opponentData.combo = data.stats.combo;
					opponentData.sicks = data.stats.sicks;
					opponentData.goods = data.stats.goods;
					opponentData.bads = data.stats.bads;
					opponentData.shits = data.stats.shits;
					opponentData.rating = data.stats.rating;
					
					if (onOpponentUpdate != null) onOpponentUpdate(opponentData);
				
				case "match_result":
					var result:MatchResult = {
						winner: data.winner,
						yourScore: data.yourScore,
						opponentScore: data.opponentScore,
						yourAccuracy: data.yourAccuracy,
						opponentAccuracy: data.opponentAccuracy
					};
					
					if (onMatchEnd != null) onMatchEnd(result);
					isInMatch = false;
					trace('Match ended - Winner: ${data.winner}');
				
				case "opponent_disconnected":
					trace('Opponent disconnected!');
					isInMatch = false;
					if (onDisconnected != null) onDisconnected();
				
				default:
					trace('Unknown message type: ${data.type}');
			}
		}
		catch (e:Dynamic)
		{
			trace('Failed to parse message: $e');
		}
	}
	
	/**
	 * Update - call this in PlayState update loop
	 */
	public static function update():Void
	{
		#if sys
		if (ws != null)
		{
			// Process incoming messages
			// This would be handled by WebSocket events
		}
		#end
	}
}

// Type definitions
typedef PlayerStats = {
	var score:Int;
	var accuracy:Float;
	var misses:Int;
	var combo:Int;
	var sicks:Int;
	var goods:Int;
	var bads:Int;
	var shits:Int;
	var rating:String;
}

typedef OpponentStats = {
	var score:Int;
	var accuracy:Float;
	var misses:Int;
	var combo:Int;
	var sicks:Int;
	var goods:Int;
	var bads:Int;
	var shits:Int;
	var rating:String;
	var playerName:String;
}

typedef MatchResult = {
	var winner:String; // "you", "opponent", or "tie"
	var yourScore:Int;
	var opponentScore:Int;
	var yourAccuracy:Float;
	var opponentAccuracy:Float;
}
