var $j = jQuery.noConflict();
var tz_offset = null;

function put_up_black_screen(message) {
    if ($j("#bscr").length == 0) {
        $j("body").append('<div id="bscr">' + message + '</div>');
    } else {
        $j("#bscr").html(message);
    }
}

function put_away_black_screen() {
    $j("#bscr").fadeOut(1000, function() {
        $j("#bscr").remove();
    });
}

function get_value_from_time_slot(slot) {
    var ret = '';
    ret = slot.find("[selected]").attr('value');
    if (ret.match(/^0/)) {
        ret = ret.replace(/^0+/, '');
        if (ret.length == 0) {
            ret = "0";
        }
    }
    try {
        ret = parseInt(ret);
    } catch (e) {
        // DO NOTHING
    }
    return ret;
}

function convert_time_selector_to_object(selector, offset) {
    var target = $j(selector);
    var di = null;
    var dt = {
        obj: null,
        original: {
            y:  get_value_from_time_slot(target.eq(0)),
            m:  get_value_from_time_slot(target.eq(1)),
            d:  get_value_from_time_slot(target.eq(2)),
            H:  get_value_from_time_slot(target.eq(3)),
            MM: get_value_from_time_slot(target.eq(4))
        },
        locale: {y:0, m:0, d:0, H:0, MM:0}
    };
    if (!offset) {
        offset = 0;
    }
    di = make_date_object_from_time_object(dt.original);
    
    di = new Date(di.getTime() - offset);

    dt.locale.y = di.getFullYear();
    dt.locale.m = di.getMonth() + 1;
    dt.locale.d = di.getDate();
    dt.locale.H = (di.getHours()<10?"0":"") + di.getHours();
    dt.locale.MM = (di.getMinutes()<10?"0":"") + di.getMinutes();
    
    return dt;
}

function make_date_object_from_time_object(obj_ref) {
    var returnee = new Date(parseInt(obj_ref.y), parseInt(obj_ref.m) - 1, parseInt(obj_ref.d), parseInt(obj_ref.H), parseInt(obj_ref.MM));
    return returnee;
}

function fix_timezone() {
    $j(".datetime:not(.tzfix)").each(function (index) {
        var d = new Date($j(this).html());
        if (tz_offset == null) {
            tz_offset = d.getTimezoneOffset();
            tz_offset /= 60;
        }
        $j(this).html(d.toLocaleDateString() + " " + d.toLocaleTimeString());
        $j(this).addClass("tzfix");
    });
    //var edit_anchor = $j(".extra").find("a:contains(Edit), a:contains(Create)");
    //edit_anchor.attr("href", edit_anchor.attr("href") + "?tz_offset=" + tz_offset);
    var forms = $j("form.new_meeting, form.edit_meeting");
    forms.trigger('reset');
    //if (forms.find("[name=tz_offset]").val() == "not set") return;
    forms.append('<input type="hidden" name="tz_offset" value="' + tz_offset + '"/>');
    //return;
    forms.find("label[for=meeting_start], label[for=meeting_finish]").each(function(index) {
        var target_label = $j(this);
        var target = $j(this).parent().find("select");
        var dt = convert_time_selector_to_object(target, tz_offset * 3600000);
        target.eq(0).val(dt.locale.y);
        target.eq(1).val(dt.locale.m);
        target.eq(2).val(dt.locale.d);
        target.eq(3).val(dt.locale.H);
        target.eq(4).val(dt.locale.MM);
        target_label.html(target_label.html().replace(/ \(UTC\)/, ''));
    });
}

function nudge_elements(selector) {
    var nudged_areas = $j(selector);
    nudged_areas.css("position", "relative")
        .animate({top: -5}, 100,
        function() {
            nudged_areas.animate({top: 4}, 100,
            function() {
                nudged_areas.animate({top: -2}, 100,
                function() {
                    nudged_areas.animate({top: 1}, 100,
                    function() {
                        nudged_areas.css("position", "static");
                    });
                });
            });
        });
}

function add_notifier(message) {
    $j("#notifier").append('<p>' + message + '</p>');
    ease_out_notifier();
}

function ease_out_notifier() {
    nudge_elements("#notifier > p:last");

    setTimeout(function() {
        $j("#notifier > p:last").fadeOut(100, function() {
            $(this).remove();
        });
    }, 5000);
}

function enhance_note() {
    var note = $j(".note");

    if (note.length == 0) return;

    note.each(function (index) {
        try {
            var note_html = $j(this).html();
            var urls = note_html.match(/(https?:\/\/[^ \r\n]+)/g);
            if (!urls) {
                return true;
            }

            for (var i = 0; i < urls.length; i++) {
                urls[i] = urls[i].replace(/[\.\)\(]+$/, '');
                var rx = new RegExp(urls[i]);

                note_html = note_html.replace(rx, '<a href="' + urls[i] + '" target="_blank">&#8594; ' + urls[i] + '</a>');
            }
            $j(this).html(note_html);
        } catch (e) {
            $j(this).html();
        }
    });
}

function show_timeline(when_start, when_finish) {
    var meeting = $j(".meeting");

    if (meeting.length == 0) return;
    if (meeting.find(".datetime").length < 1 && !when_start) return;

    var current = new Date();
    
    var timestamps = meeting.find(".datetime");

    var starter_original = null;
    var starter = null;
    if (when_start) {
        starter = when_start;
    } else {
        starter_original = timestamps.eq(0).text();
        starter = new Date(starter_original);
    }
    
    var begin = new Date(current<starter?current:starter);
    begin.setHours(0, 0, 0, 0);

    var finisher_original = null;
    var finisher = null;
    var end = null

    if (when_finish > when_start) {
        finisher = when_finish;
        end = new Date(finisher);
    } else if (timestamps.length > 1) {
        finisher_original = timestamps.eq(1).text();
        finisher = new Date(finisher_original);
        end = new Date(finisher);
    } else {
        end = new Date(starter);
    }
    
    end.setHours(24, 0, 0, 0);

    var time_format = {
        begin_end: "%A, %B %e, %Y %Z",
        normal: "%A, %B %e, %Y %H:%M %Z"
    }

    var time_output = {
        begin: "← " + begin.toString(),
        starter: starter,
        finisher: finisher,
        end: end.toString() + " →"
    }
    
    if (begin.toLocaleFormat) {
        time_output = {
            begin: "← " + begin.toLocaleFormat(time_format.begin_end),
            starter: starter.toLocaleFormat(time_format.normal),
            finisher: finisher,
            end: end.toLocaleFormat(time_format.begin_end) + " →"
        }

        if (time_output.finisher != null) {
            time_output.finisher = finisher.toLocaleFormat(time_format.normal);
        }
    }
    
    var set_duration = end - begin;
    var day_duration = 1000*60*60*24;
    var number_of_day = set_duration / day_duration;
    var cx = {
        b: 0,
        e: 818,
        s: 0,
        f: 0,
        c: 0,
        d: 225
    };
    
    if (begin.toLocaleFormat) {
        cx.d = 150;
    }

    cx.c = cx.b + (cx.e - cx.b) * (current - begin) / set_duration;
    cx.s = cx.b + (cx.e - cx.b) * (starter - begin) / set_duration;
    if (finisher) {
        cx.f = cx.b + (cx.e - cx.b) * (finisher - begin) / set_duration;
    }

    if (meeting.find("canvas").length == 0) {
        if (meeting.find("form").length > 0) {
            meeting.find("form").before('<canvas id="timeline" width="818" height="100"></canvas>');
        } else {
            meeting.append('<canvas id="timeline" width="818" height="100"></canvas>');
        }
    } else {
        artist.restart("timeline");
    }
    
    // draw the duration
    if (finisher) {
        artist.draw_box("timeline", cx.s, 0, cx.f, 100, "#ccff66", "#000", "fill");
    } else {
        artist.draw_text("timeline", time_output.starter, cx.s, 70);
        artist.draw_line("timeline", cx.s, 0, cx.s, 100, "#669933");
    }

    // draw the current time
    artist.draw_circle("timeline", cx.c, 50, 5, 0, Math.PI*2, true, "#ff9900");

    // draw the time flow
    for (var i = 1; i < number_of_day; i++) {
        var width_between_interval = (cx.e - cx.b) / number_of_day;
        artist.draw_line("timeline", cx.b + width_between_interval * i, 0, cx.b + width_between_interval * i, 100, "#fff");
    }
    artist.draw_text("timeline", time_output.begin, cx.b + 5, 15);
    artist.draw_text("timeline", time_output.end, cx.e - cx.d, 95);
}

function update_timeline() {
    var forms = $j("form.new_meeting, form.edit_meeting");
    var when_begin = null;
    var when_end = null;
    forms.find("label[for=meeting_start], label[for=meeting_finish]").each(function(index) {
        var datetime = convert_time_selector_to_object($j(this).parent().find("select"));

        if ($j(this).attr('for') == "meeting_start") {
            when_begin = make_date_object_from_time_object(datetime.locale);
        } else {
            when_end = make_date_object_from_time_object(datetime.locale);
        }
    });
    show_timeline(when_begin, when_end);
}

$j(document).ready(function() {
    enhance_note();
    fix_timezone();
    if ($j(".edit_meeting").length == 0) {
        show_timeline();
    } else {
        update_timeline();
    }
    $j(".edit_meeting select").change(update_timeline);
    
    nudge_elements("#errorExplanation");
    //nudge_elements(".meeting .warning, .meeting .instruction, #errorExplanation");

    $j("form[onsubmit]").submit(function (e) {
        put_up_black_screen("Please wait.");
    });

    // trigger participant's info panel
    $j(".participant a[href=#info]").live("click", function(event) {
        event.preventDefault();
        var data_card = $j(this).parent();
        var id_card = $j(".idcard");
        id_card.find(".name").html(data_card.find(".name").html());
        id_card.find(".status").html(data_card.find(".status").html() + " (" + data_card.find(".invited_at").html() + " ago)");
        if (data_card.find(".email").length) {
            id_card.find(".email").html(data_card.find(".email").html());
        }
        if (data_card.find(".note").length && $j.trim(data_card.find(".note").html()).length > 0) {
            id_card.find(".note").html($j.trim(data_card.find(".note").html()).replace(/\n/g, "<br/>"));
            id_card.find(".note").show();
        } else {
            id_card.find(".note").hide();
        }
        id_card.slideDown(100);
    });
    $j(".idcard [href=#hide]").click(function(event) {
        event.preventDefault();
        $j(".idcard").slideUp(100);
    });

    // invitation responding form activator
    $j("a[href=#respond]").click(function(e) {
        e.preventDefault();
        $j("#participants .edit_participant").slideDown(100);
        $j("a[href=#respond]").fadeOut(200);
    });
    // invitation responding form canceller
    $j("#participants .edit_participant button[type=reset]").click(function(e) {
        $j("#participants .edit_participant").slideUp(100);
        $j("a[href=#respond]").fadeIn(200);
    });

    // invitation form activator
    $j("a[href=#invite]").click(function(e) {
        e.preventDefault();
        $j("#participants .new_participant").slideDown(100);
        $j("a[href=#invite]").fadeOut(200);
    });
    // invitation form canceller
    $j("#participants .new_participant button[type=reset]").click(function(e) {
        $j("#participants .new_participant").slideUp(100);
        $j("a[href=#invite]").fadeIn(200);
    });

    // invitation form activator for additionals (info)
    $j("button.change-info").click(function(e) {
        e.preventDefault();
        $j("#participants .edit_participant .extra-info").slideDown(100);
        $j(this).fadeOut(200);
    });
    // invitation form activator for additionals (note)
    $j("button.leave-a-note").click(function(e) {
        e.preventDefault();
        $j("#participants .edit_participant .extra-note").slideDown(100);
        $j(this).fadeOut(200);
    });
});
