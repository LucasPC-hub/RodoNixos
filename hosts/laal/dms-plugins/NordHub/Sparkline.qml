import QtQuick
import qs.Common

// Area chart over a numeric history array. DgopService appends to its history
// arrays in place, so callers bump `revision` after each sample.
Canvas {
    id: root

    property var values: []
    // <= 0 scales to the largest sample in the window.
    property real maxValue: 100
    property color lineColor: Theme.primary
    property int revision: 0

    renderStrategy: Canvas.Cooperative

    onRevisionChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onLineColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const data = values || [];
        if (data.length < 2 || width <= 0 || height <= 0)
            return;

        let max = maxValue;
        if (max <= 0) {
            max = 0;
            for (let i = 0; i < data.length; i++)
                max = Math.max(max, data[i]);
            max = Math.max(max * 1.15, 1);
        }

        const step = width / (data.length - 1);
        const yFor = v => height - Math.max(0, Math.min(1, v / max)) * (height - 2) - 1;

        ctx.beginPath();
        ctx.moveTo(0, yFor(data[0]));
        for (let i = 1; i < data.length; i++)
            ctx.lineTo(i * step, yFor(data[i]));

        ctx.lineWidth = 1.5;
        ctx.strokeStyle = lineColor;
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        ctx.fillStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.16);
        ctx.fill();
    }
}
