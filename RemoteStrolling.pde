import muthesius.net.*;
import org.webbitserver.*;
import SimpleOpenNI.*;

WebSocketP5 socket;

SimpleOpenNI context;
float zoomF = 0.5f;
float rotX = radians(180);
float rotY = radians(0);
float bodyHeight = 0;
float[] footAverageY;
float[] neckAverageY;

boolean horizontalMovement = true;
boolean mirrorHorizontalMovement = false;
boolean verticalMovement = true;
boolean useStep = true;
boolean useTurn = true;

float previousYaw = 0;
float previousPitch = 0;
float yaw = 0;
float pitch = 0;

boolean kinect = false;

boolean jumpInProgress = false;
boolean step = false;

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
    footAverageY = new float[30];
    neckAverageY = new float[30];
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

void checkForJumping (PVector neck, PVector feet)
{
    float footAverage = 0;
    float neckAverage = 0;
    int neckL = 1;
    int feetL = 1;
    
    for (int i = 0; i < footAverageY.length; i++) {
        if (i + 1 < footAverageY.length) {
            footAverageY[i+1] = footAverageY[i];
            neckAverageY[i+1] = neckAverageY[i];
            footAverage += footAverageY[i+1];
            neckAverage += neckAverageY[i+1];
            if (neckAverageY[i+1] > 0) neckL++;
            if (footAverageY[i+1] > 0) feetL++;
        }
    }
    footAverageY[0] = feet.y;
    neckAverageY[0] = neck.y;
    
    footAverage += feet.y;
    neckAverage += neck.y;
    footAverage /= feetL;
    neckAverage /= neckL;
    
    float bodyHeight = neck.y - feet.y;
    
    if (jumpInProgress) {
        if (neck.y - neckAverage < bodyHeight/25) {
            jumpInProgress = false;
        }
    } else {
        if (neck.y - neckAverage > bodyHeight/25) {
            jumpInProgress = true;
            sendStep();
        }
    }
}

void checkForStep(int userId) {
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
    PVector leftKnee = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_KNEE, leftKnee);
    PVector rightKnee = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, rightKnee);
    PVector leftHip = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HIP, rightKnee);
    PVector rightHip = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HIP, rightKnee);
    PVector torso = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_TORSO, torso);
    PVector waist = new PVector();
    context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_WAIST, torso);
    int stepDist= floor(norm(abs(rightFoot.y-leftFoot.y), 0, (rightHip.dist(rightFoot)+leftHip.dist(leftFoot))/2)*100);
 
    if (step) {
        step = (stepDist == 0) ? false: step;
    } else if (stepDist > 1) {
        step = true;
        sendStep();
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
    
    if (useStep) {
        checkForStep(userId);
    } else {
        checkForJumping(neck, blah);
    }

    PMatrix3D  orientation = new PMatrix3D();
    float confidence = context.getJointOrientationSkeleton(userId,SimpleOpenNI.SKEL_HEAD,orientation);

    if (horizontalMovement) {
        if (useTurn) {
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

            float linksrechtsToleranz = 15;
            if (abs(linksrechtsGrad) > linksrechtsToleranz) {
                float grad = sqrt(sqrt(abs(linksrechtsGrad - linksrechtsToleranz)));
                if (linksrechtsGrad < 0) grad *= -1;
                if (mirrorHorizontalMovement) grad *= -1;
                yaw += round(grad);
            }
        } else {
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
            
            if (abs(seitlicheNeigungDegrees) > seitlicheNeigungToleranz) {
                float grad = sqrt(sqrt(abs(seitlicheNeigungDegrees - seitlicheNeigungToleranz)));
                if (seitlicheNeigungDegrees < 0) grad *= -1;
                if (mirrorHorizontalMovement) grad *= -1;
                yaw += round(grad);
            }
        }
    }
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
                if (mirrorHorizontalMovement) {
                    println("mirror movement ON");
                } else {
                    println("mirror movement OFF");
                }
                break;
            case 'h':
                horizontalMovement = !horizontalMovement;
                if (horizontalMovement) {
                    println("horizontal movement ON");
                } else {
                    println("horizontal movement OFF");
                }
                break;
            case 'v':
                verticalMovement = !verticalMovement;
                if (verticalMovement) {
                    println("vertical movement ON");
                } else {
                    println("vertical movement OFF");
                }
                break;
            case 'r':
                useTurn = !useTurn;
                if (useTurn) {
                    println("using TURNING");
                } else {
                    println("using LEANING");
                }
                break;
            case 't':
                useStep = !useStep;
                if (useStep) {
                    println("using STEPPING");
                } else {
                    println("using JUMPING");
                }
                break;
        }
    }
}

void sendViewUpdate ()
{
    if (yaw != previousYaw || pitch != previousPitch) {
        //println("yaw: " + yaw + ", pitch: " + pitch);
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