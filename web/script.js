// Google StreetView
var panorama;
var currentYaw = 180;
var currentPitch = 0;
var currentZoom = 0;
var zoomingIn = true;

// websockets
var ws = null;
var host = "localhost"
var port = 8080
var socket = "p5websocket"

function ready()
{
    panorama = new GStreetviewPanorama(document.getElementById("pano"));
    panorama.setLocationAndPOV(new GLatLng(45.511889, -122.675578), {yaw: currentYaw, pitch: currentPitch, zoom: currentZoom});
    
    console.log("trying to open a websocket")
    var _socket = (undefined==socket)?"":"/"+socket
    
    _url = "ws://"+host+":"+port+_socket
    
    if ('MozWebSocket' in window) {
        ws = new MozWebSocket (_url);
    } else {
        ws = new WebSocket (_url);
    }
    
    // When the connection is open, send some data to the server
    ws.onopen = function () {
        console.log("opened");
        ws.send('Ping'); // Send the message 'Ping' to the server
    };

    // oh, it did close
    ws.onerror = function (e) {
        console.log('WebSocket did close ',e);
    };
    
    // Log errors
    ws.onerror = function (error) {
        console.log('WebSocket Error ' + error);
    };

    // Log messages from the server
    ws.onmessage = function (e) {
        switch (e.data) {
            case "left":
                currentYaw -= 2;
                break;
            case "right":
                currentYaw += 2;
                break;
            case "up":
                currentPitch -= 2;
                break;
            case "down":
                currentPitch += 2;
                break;
        }
        panorama.panTo({yaw:currentYaw, pitch:currentPitch});
        console.log('Server: ' + e.data);
    };
}
            
document.addEventListener("DOMContentLoaded", ready, false);
document.addEventListener("unload", GUnload, false);