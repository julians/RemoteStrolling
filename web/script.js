var panorama;
var currentYaw = 180;
var currentPitch = 0;
var currentZoom = 0;
var zoomingIn = true;

function load()
{
    panorama = new GStreetviewPanorama(document.getElementById("pano"));
    panorama.setLocationAndPOV(new GLatLng(45.511889, -122.675578), {yaw: currentYaw, pitch: currentPitch, zoom: currentZoom});
}

function spiral()
{
    currentYaw += 2;
    panorama.panTo({yaw:currentYaw, pitch:currentPitch});
}

var ws = null;
var host = "localhost"
var port = 8080
var socket = "p5websocket"

function ready()
{
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
        console.log("opened")
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
        if (e.data == "left") {
            currentYaw -= 2;
        } else if (e.data == "right") {
            currentYaw += 2;
        }
        panorama.panTo({yaw:currentYaw, pitch:currentPitch});
        console.log('Server: ' + e.data);
    };
}
            
document.addEventListener("DOMContentLoaded", ready, false);