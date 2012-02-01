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

var panoLeftOffset = -100;
var panoRightOffset = 0;

var places = {
    "standard": {
        title: "Remote Strolling",
        coords: new GLatLng(45.511889, -122.675578),
        yaw: 180
    },
    "berkeley": {
        title: "University of California, Berkeley",
        coords: new GLatLng(37.872678, -122.261733),
        yaw: 285
    },
    "oxford": {
        title: "University of Oxford, England",
        coords: new GLatLng(51.756179,-1.255295),
        yaw: 160
    }
};

function setPosition (place)
{
    var pos = places[place];
    panorama.setLocationAndPOV(pos.coords, {yaw: pos.yaw, pitch: currentPitch, zoom: currentZoom});
    setTitle(pos.title);
}

function ready ()
{
    panorama = new GStreetviewPanorama(document.getElementById("pano"));
    setPosition("oxford");
    openWebSocket();
    drawCurtains();
    $(window).resize(function() {
        drawCurtains();
    });
}

function drawCurtains ()
{
    console.log($(window).width());
    var desiredWidth = $(window).height()/16*12;
    console.log(desiredWidth);
    var curtainWidth = ($(window).width()-desiredWidth)/2;
    console.log(curtainWidth);
    $("#pano").css({
        "left": (curtainWidth+panoLeftOffset) + "px",
        "right": (curtainWidth+panoRightOffset) + "px"
    });
    $("#text").css({
        "left": (curtainWidth+10) + "px",
        "right": (curtainWidth+10) + "px"
    });
    $("#leftCurtain").css({
        "right": ($(window).width()-curtainWidth) + "px"
    });
    $("#rightCurtain").css({
        "left": ($(window).width()-curtainWidth) + "px"
    });
    panorama.checkResize();
}

function handleWebSocketMessage (e)
{
    console.log('Server: ' + e.data);

    var command = e.data.split(":")[0];

    if (command == "step") {
        panorama.followLink(currentYaw);
    } else if (command == "info") {
        sendInfo();
    } else if (command == "view") {
        var values = e.data.split(":");
        currentYaw = values[1]*1;
        currentPitch = values[2]*1;
        panorama.panTo({yaw:currentYaw, pitch:currentPitch});
    }
}

function openWebSocket()
{
    console.log("trying to open a websocket")
    ws = null;
    var _socket = (undefined==socket)?"":"/"+socket

    _url = "ws://"+host+":"+port+_socket

    if ('MozWebSocket' in window) {
        ws = new MozWebSocket (_url);
    } else {
        ws = new WebSocket (_url);
    }

    ws.onopen = function () {
        console.log("websocket opened");
        window.setTimeout(sendInfo, 100);
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

function sendInfo()
{
    ws.send(["info", currentYaw, currentPitch].join(":"));
}

function setTitle(text)
{
    $("#text").html(text);
    $("#text").fitText(3.5);
}

document.addEventListener("DOMContentLoaded", ready, false);
document.addEventListener("unload", GUnload, false);