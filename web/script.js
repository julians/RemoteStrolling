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
    openWebSocket();
}

function handleWebSocketMessage (e)
{
    console.log('Server: ' + e.data);

    var command = e.data.split(":")[0];

    if (command == "forward") {
        panorama.followLink(currentYaw);
    } else {
        var value = e.data.split(":")[1]*1;
        console.log(value);
        switch (command) {
            case "left":
                currentYaw -= value;
                break;
            case "right":
                currentYaw += value;
                break;
            case "up":
                currentPitch -= value;
                break;
            case "down":
                currentPitch += value;
                break;
        }
        panorama.panTo({yaw:currentYaw, pitch:currentPitch});
    }
}

function openWebSocket()
{
    console.log("trying to open a websocket")
    var _socket = (undefined==socket)?"":"/"+socket

    _url = "ws://"+host+":"+port+_socket

    if ('MozWebSocket' in window) {
        ws = new MozWebSocket (_url);
    } else {
        ws = new WebSocket (_url);
    }

    ws.onopen = function () {
        console.log("websocket opened");
        ws.send('ping'); // Send the message 'Ping' to the server
    };
    // oh, it did close
    ws.onclose = function (e) {
        console.log('WebSocket did close ',e);
        window.setTimeout(openWebSocket, 5000);
    };
    // Log errors
    ws.onerror = function (error) {
        console.log('WebSocket Error ' + error);
    };
    ws.onmessage = handleWebSocketMessage;
}

document.addEventListener("DOMContentLoaded", ready, false);
document.addEventListener("unload", GUnload, false);