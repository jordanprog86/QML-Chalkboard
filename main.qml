import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.0

Window {
    id: root
    width: 1024
    height: 768
    visible: true
    title: "Realistic QML Chalkboard"
    color: "#2c3e50"

    // Outer Wooden Frame Border
    Rectangle {
        id: boardFrame
        anchors.centerIn: parent
        width: parent.width * 0.92
        height: parent.height * 0.88
        color: "#5c4033" // Wood color
        border.color: "#3d2b22"
        //border.width: 4
        radius: 8

        // Outer shadows for depth
        border.width: 6

        // Actual Blackboard Surface
        Rectangle {
            id: chalkboardSurface
            anchors.fill: parent
            anchors.margins: 24 // Thickness of the frame
            color: "#1e352f" // Classic slate dark green
            clip: true

            // Subtle Background Chalk Dust Texture Overlay
            ShaderEffect {
                anchors.fill: parent
                opacity: 0.04
                // Adds a soft grainy matte look over the solid color
                fragmentShader: "
                    uniform lowp float qt_Opacity;
                    varying highp vec2 qt_TexCoord0;
                    highp float rand(vec2 co) {
                        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
                    }
                    void main() {
                        gl_FragColor = vec4(1.0, 1.0, 1.0, rand(qt_TexCoord0)) * qt_Opacity;
                    }"
            }

            // The Writing Slate Canvas
            Canvas {
                id: paintCanvas
                anchors.fill: parent

                property real lastX: 0
                property real lastY: 0
                property color chalkColor: "#f7f9fa" // Soft off-white
                property real baseBrushSize: 12

                onAvailableChanged: {
                    if (available) {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                    }
                }

                // Custom JavaScript helper to draw textured chalk points
                function drawChalkLine(x1, y1, x2, y2) {
                    var ctx = getContext("2d");

                    // Calculate distance and angle between current mouse positions
                    var dx = x2 - x1;
                    var dy = y2 - y1;
                    var distance = Math.sqrt(dx * dx + dy * dy);
                    var angle = Math.atan2(dy, dx);

                    // Interpolate points across the stroke path to prevent gaps
                    // Chalk leaves uneven markings depending on pressure/speed
                    var steps = Math.max(Math.floor(distance / 2), 1);

                    for (var i = 0; i <= steps; i++) {
                        var t = i / steps;
                        var currX = x1 + (dx * t);
                        var currY = y1 + (dy * t);

                        // Vary size slightly dynamically to simulate chalk wearing down/slipping
                        var brushRadius = baseBrushSize + (Math.random() * 3 - 1.5);
                        if (brushRadius < 2) brushRadius = 2;

                        // Create a soft radial gradient for a powdery falloff edge
                        var grad = ctx.createRadialGradient(currX, currY, brushRadius * 0.1, currX, currY, brushRadius);

                        // Chalk core opacity mixes with powdery edges
                        var opacityCore = (0.2 + Math.random() * 0.15).toFixed(3);
                        grad.addColorStop(0, "rgba(247, 249, 250, " + opacityCore + ")");
                        grad.addColorStop(0.4, "rgba(247, 249, 250, 0.08)");
                        grad.addColorStop(1, "rgba(247, 249, 250, 0)");

                        ctx.fillStyle = grad;

                        // Draw multiple tiny offset splatters per step to act as powdery residue
                        ctx.beginPath();
                        ctx.arc(currX, currY, brushRadius, 0, 2 * Math.PI);
                        ctx.fill();

                        // Falloff stray speckles around the central stroke path
                        if (Math.random() > 0.4) {
                            var scatterX = currX + (Math.random() * brushRadius * 1.4 - brushRadius * 0.7);
                            var scatterY = currY + (Math.random() * brushRadius * 1.4 - brushRadius * 0.7);
                            ctx.fillStyle = "rgba(247, 249, 250, 0.12)";
                            ctx.fillRect(scatterX, scatterY, 1.5, 1.5);
                        }
                    }
                    requestPaint();
                }

                function clearBoard() {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    requestPaint();
                }
            }

            // User Interactivity Surface
            MouseArea {
                anchors.fill: parent
                preventStealing: true

                onPressed: (mouse) => {
                    paintCanvas.lastX = mouse.x;
                    paintCanvas.lastY = mouse.y;
                    paintCanvas.drawChalkLine(mouse.x, mouse.y, mouse.x, mouse.y);
                }

                onPositionChanged: (mouse) => {
                    if (pressed) {
                        paintCanvas.drawChalkLine(paintCanvas.lastX, paintCanvas.lastY, mouse.x, mouse.y);
                        paintCanvas.lastX = mouse.x;
                        paintCanvas.lastY = mouse.y;
                    }
                }
            }
        }
    }

    // Action Controls (Clear Button Container)
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        spacing: 20

        Button {
            text: "Wipe Board Clean"
            onClicked: paintCanvas.clearBoard()
            contentItem: Text {
                text: parent.text
                color: "#f7f9fa"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitWidth: 160
                implicitHeight: 40
                color: parent.down ? "#7f8c8d" : (parent.hovered ? "#95a5a6" : "#7f8c8d")
                radius: 4
                border.color: "#bdc3c7"
                border.width: 1
            }
        }
    }
}
