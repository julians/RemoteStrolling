import muthesius.net.*;
import org.webbitserver.*;
import SimpleOpenNI.*;

WebSocketP5 socket;

SimpleOpenNI context;
float zoomF = 0.5f;
float rotX = radians(180);
float rotY = radians(0);
float bodyHeight = 0;
float headHeight = 0;

boolean horizontalMovement = true;
boolean mirrorHorizontalMovement = false;
boolean verticalMovement = true;

float previousYaw = 0;
float previousPitch = 0;
float yaw = 0;
float pitch = 0;

boolean kinect = false;

void setup()
{
    socket = new WebSocketP5(this,8080);
    context = new SimpleOpenNI(this);
    if (context.enableDepth() == true) {
        kinect = true;
        context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
        size(context.depthWidth(), context.depthHeight());
    } else {
        println("Can't open the depthMap, maybe the camera is not connected!");
        size(800, 600);
    }
    smooth();
}

void draw()
{
    if (kinect) {
        context.update();
        image(context.depthImage(),0,0);
        if(context.isTrackingSkeleton(1)) {
            drawSkeleton(1);
            calculateThings(1);
        }        
    }
}

void calculateThings(int userId)
{
    PVector head = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, head);
    PVector neck = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, neck);
    PVector leftFoot = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_FOOT, leftFoot);
    PVector rightFoot = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_FOOT, rightFoot);
    PVector blah = PVector.div(PVector.add(leftFoot, rightFoot), 2);
    bodyHeight = PVector.dist(blah, head);
    headHeight = PVector.dist(neck, head);

    PMatrix3D  orientation = new PMatrix3D();
    float confidence = context.getJointOrientationSkeleton(userId,SimpleOpenNI.SKEL_HEAD,orientation);

    /*
    if (horizontalMovement) {
        PVector seitlicheNeigung = new PVector(0, 0, 0);
        orientation.mult(new PVector(0, -100, 0), seitlicheNeigung);
        seitlicheNeigung = new PVector(seitlicheNeigung.x, seitlicheNeigung.y);
        seitlicheNeigung.normalize();
        seitlicheNeigung.mult(100);
        pushMatrix();
            translate(width/2, height/2);
            stroke(0, 0, 255, 128);
            strokeWeight(20);
            line(0, 0, seitlicheNeigung.x, seitlicheNeigung.y);
        popMatrix();
        float seitlicheNeigungDegrees = degrees(seitlicheNeigung.heading2D()) + 90;
        println("vertikal geneigt um " + seitlicheNeigungDegrees);
        float seitlicheNeigungToleranz = 4;
        if (floor(seitlicheNeigungDegrees) > seitlicheNeigungToleranz) {
            if (mirrorHorizontalMovement) {
                socket.broadcast("left:" + sqrt(abs(seitlicheNeigungDegrees - seitlicheNeigungToleranz)));
            } else {
                socket.broadcast("right:" + sqrt(abs(seitlicheNeigungDegrees - seitlicheNeigungToleranz)));
            }
        } else if (floor(seitlicheNeigungDegrees) < - seitlicheNeigungToleranz) {
            if (mirrorHorizontalMovement) {
                socket.broadcast("right:" + sqrt(abs(seitlicheNeigungDegrees + seitlicheNeigungToleranz)));
            } else {
                socket.broadcast("left:" + sqrt(abs(seitlicheNeigungDegrees + seitlicheNeigungToleranz)));
            }
        }
    }
    */
    if (verticalMovement) {
        PVector vornehintenNeigung = new PVector(0, 0, 0);
        orientation.mult(new PVector(0, 0, 100), vornehintenNeigung);
        vornehintenNeigung = new PVector(vornehintenNeigung.z, vornehintenNeigung.y);
        vornehintenNeigung.normalize();
        vornehintenNeigung.mult(100);
        pushMatrix();
            translate(width/2, height/2);
            stroke(0, 255, 0, 128);
            strokeWeight(20);
            line(0, 0, vornehintenNeigung.x, vornehintenNeigung.y);
        popMatrix();
        float vornehintenNeigungDegrees = degrees(vornehintenNeigung.heading2D());
        //println("vorne/hinten geneigt um " + vornehintenNeigungDegrees);
        float vorneToleranz = 20;
        float hintenToleranz = 0;
        if (floor(vornehintenNeigungDegrees) > vorneToleranz) {
            pitch = round(vornehintenNeigungDegrees - vorneToleranz);
        } else if (floor(vornehintenNeigungDegrees) < hintenToleranz) {
            pitch = round(vornehintenNeigungDegrees + hintenToleranz);
        }
    }
    if (horizontalMovement) {
        PVector linksrechts = new PVector(0, 0, 0);
        orientation.mult(new PVector(0, 0, -100), linksrechts);
        linksrechts = new PVector(-linksrechts.x, linksrechts.z);
        linksrechts.normalize();
        linksrechts.mult(100);
        pushMatrix();
            translate(width/2, height/2);
            stroke(255, 0, 0, 128);
            strokeWeight(20);
            line(0, 0, linksrechts.x, linksrechts.y);
        popMatrix();
        float linksrechtsGrad = degrees(linksrechts.heading2D()) + 90;
        //println("links/rechts gedreht um " + linksrechtsGrad);
        
        float linksrechtsToleranz = 10;
        if (abs(linksrechtsGrad) > linksrechtsToleranz) {
            float grad = sqrt(sqrt(abs(linksrechtsGrad - linksrechtsToleranz)));
            if (linksrechtsGrad < 0) grad *= -1;
            if (mirrorHorizontalMovement) grad *= -1;
            yaw += round(grad);
        }
    }
    sendViewUpdate();
}

void stop()
{
	socket.stop();
}

void keyPressed()
{
    if (key == CODED) {
        switch (keyCode) {
            case LEFT:
                yaw -= 1;
                break;
            case RIGHT:
                yaw += 1;
                break;
            case UP:
                pitch -= 1;
                break;
            case DOWN:
                pitch += 1;
                break;
        }
        sendViewUpdate();
    } else {
        switch (key) {
            case ' ':
                sendStep();
                break;
            case 'x':
                mirrorHorizontalMovement = !mirrorHorizontalMovement;
                println("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
                if (mirrorHorizontalMovement) {
                    println("mirror movement ON");
                } else {
                    println("mirror movement OFF");
                }
                println("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
                break;
            case 'h':
                horizontalMovement = !horizontalMovement;
                println("hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh");
                if (horizontalMovement) {
                    println("horizontal movement ON");
                } else {
                    println("horizontal movement OFF");
                }
                println("hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh");
                break;
            case 'v':
                verticalMovement = !verticalMovement;
                println("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
                if (verticalMovement) {
                    println("vertical movement ON");
                } else {
                    println("vertical movement OFF");
                }
                println("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
                break;
        }
    }
}

void sendViewUpdate ()
{
    if (yaw != previousYaw || pitch != previousPitch) {
        println("yaw: " + yaw + ", pitch: " + pitch);
        socket.broadcast("view:"+yaw+":"+pitch);
        previousYaw = yaw;
        previousPitch = pitch;
    }
}

void sendStep ()
{
    println("step");
    socket.broadcast("step");
}

// -----------------------------------------------------------------
// websocket events

void websocketOnMessage(WebSocketConnection con, String msg)
{
	println(msg);
	String[] message = split(msg, ":");
	if (message[0].equals("info")) {
	    yaw = float(message[1]);
	    previousYaw = yaw;
        pitch = float(message[2]);
        previousPitch = pitch;
	}
    println("yaw: " + yaw);
    println("pitch: " + pitch);
}

void websocketOnOpen(WebSocketConnection con)
{
    println("A client joined");
}

void websocketOnClosed(WebSocketConnection con)
{
    println("A client left");
}

// -----------------------------------------------------------------
// SimpleOpenNI user events etc.

void drawSkeleton(int userId)
{
    strokeWeight(2);
    stroke(255, 0, 0);

    context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

    context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
    context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
    context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

    context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
    context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
    context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

    context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
    context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

    context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
    context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
    context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

    context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
    context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
    context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);
}

void onNewUser(int userId)
{
    println("onNewUser - userId: " + userId);
    println("  start pose detection");
    context.startPoseDetection("Psi",userId);
}

void onLostUser(int userId)
{
    println("onLostUser - userId: " + userId);
}

void onStartCalibration(int userId)
{
    println("onStartCalibration - userId: " + userId);
}

void onEndCalibration(int userId, boolean successfull)
{
    println("onEndCalibration - userId: " + userId + ", successfull: " + successfull);

    if (successfull) {
        println("  User calibrated !!!");
        context.startTrackingSkeleton(userId);
    } else {
        println("  Failed to calibrate user !!!");
        println("  Start pose detection");
        context.startPoseDetection("Psi",userId);
    }
}

void onStartPose(String pose,int userId)
{
    println("onStartdPose - userId: " + userId + ", pose: " + pose);
    println(" stop pose detection");

    context.stopPoseDetection(userId);
    context.requestCalibrationSkeleton(userId, true);
}

void onEndPose(String pose,int userId)
{
    println("onEndPose - userId: " + userId + ", pose: " + pose);
}