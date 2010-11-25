var artist = {
    restart: function (target) {
        var jq = $j("#" + target);
        var canvas = document.getElementById(target);
        if (canvas.getContext) {
            var ctx = canvas.getContext("2d");
            ctx.clearRect(0, 0, jq.width(), jq.height());
        }
    },

    draw_line: function (target, x1, y1, x2, y2, style) {
        var canvas = document.getElementById(target);
        if (canvas.getContext) {
            var ctx = canvas.getContext("2d");
            if (style) {
                ctx.strokeStyle = style;
            } else {
                ctx.strokeStyle = "#000";
            }
            ctx.beginPath();
            ctx.moveTo(x1, y1);
            ctx.lineTo(x2, y2);
            ctx.closePath();
            ctx.stroke();
        }
    },

    draw_box: function (target, x1, y1, x2, y2, style_fill, style_stroke, show) {
        var canvas = document.getElementById(target);
        if (canvas.getContext) {
            var ctx = canvas.getContext("2d");
            if (style_stroke) {
                ctx.strokeStyle = style_stroke;
            } else {
                ctx.strokeStyle = "#000";
            }
            if (style_fill) {
                ctx.fillStyle = style_fill;
            } else {
                ctx.fillStyle = "#000";
            }
            if (!show) {
                show = "all";
            }
            if (show == "all" || show == "fill") {
                ctx.fillRect(x1, y1, x2 - x1, y2 - y1);
            }
            if (show == "all" || show == "stroke") {
                ctx.strokeRect(x1, y1, x2 - x1, y2 - y1);
            }
        }
    },

    draw_circle: function (target, x, y, radius, startAngle, endAngle, anticlockwise, style_fill, style_stroke, show) {
        var canvas = document.getElementById(target);
        if (canvas.getContext) {
            var ctx = canvas.getContext("2d");
            if (style_stroke) {
                ctx.strokeStyle = style_stroke;
            } else {
                ctx.strokeStyle = "#000";
            }
            if (style_fill) {
                ctx.fillStyle = style_fill;
            } else {
                ctx.fillStyle = "#000";
            }
            if (!show) {
                show = "all";
            }

            ctx.beginPath();
            ctx.arc(x,y,radius,startAngle,endAngle, anticlockwise);
            
            if (show == "all" || show == "fill") {
                ctx.fill();
            }
            if (show == "all" || show == "stroke") {
                ctx.stroke();
            }

            ctx.closePath();
        }
    },

    draw_text: function (target, text, x, y, style) {
        var canvas = document.getElementById(target);
        if (canvas.getContext) {
            var ctx = canvas.getContext("2d");
            if (style) {
                ctx.fillStyle = style;
            } else {
                ctx.fillStyle = "#000";
            }
            ctx.fillText(text, x, y);
        }
    }
}