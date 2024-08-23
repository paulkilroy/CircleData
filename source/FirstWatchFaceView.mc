import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Complications;
import Toybox.Position;
import Toybox.Weather;

using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi as Ui;

class CrustData {
    var type as Complications.Type or Number;
    var deg as Number;
    var icon as WatchUi.BitmapResource or Graphics.BitmapReference or Null = null;
    var label as String = "";
    var value as String = "XXX";

    public function initialize( t,d ) {
        type = t;
        deg = d;
    }
}

class FirstWatchFaceView extends WatchUi.WatchFace  {
    var MAX_COMPLICATIONS = 40;
    enum {
        CUSTOM_NEXT_SUN_EVENT = MAX_COMPLICATIONS + 1, 
        CUSTOM_MOON_PHASE
    }    
    var crustDataDict = {
        Complications.COMPLICATION_TYPE_ALTITUDE => 
            new CrustData( Complications.COMPLICATION_TYPE_ALTITUDE, 30 ),
        Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY => 
            new CrustData( Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY, 90 ),
        Complications.COMPLICATION_TYPE_HEART_RATE => 
            new CrustData( Complications.COMPLICATION_TYPE_HEART_RATE, 150 ),
        Complications.COMPLICATION_TYPE_PULSE_OX => 
            new CrustData( Complications.COMPLICATION_TYPE_PULSE_OX, -150 ),
        CUSTOM_NEXT_SUN_EVENT => 
            new CrustData( CUSTOM_NEXT_SUN_EVENT, -90 ),
        Complications.COMPLICATION_TYPE_BATTERY => 
            new CrustData( Complications.COMPLICATION_TYPE_BATTERY, -30 ),
    } as Dictionary<Complications.Type, CrustData>;

    var iconFont;
    var timeFont2;
    var crustRadius;
    var centerH;
    var centerW;
    var nextSunriseEvent = null;
    var nextSunsetEvent = null;


    function getCenterH() {
        return centerH;
    }

    function getCenterW() {
        return centerW;
    }

    function getCrustRadius() {
        return crustRadius;
    }

    function getCrustDataDict() {
        return crustDataDict;
    }
        // make the surrounding crust separators go red if battery is low!
        // Turn pusleox, HR color red if low (config -- enter # to turn red, blank to disable)
        // 

        // Above: HR, Day, Altitude, PulseOx, Sunrise/SunSet
        // Need to code "Next Sun Event"
        // Missing Weather, Barometer / Pressure, Humidity, Dew Point, Temp (Feels Like)
        //    Wind Speed/Direction, 
        //    weather icons https://support.garmin.com/en-MY/?faq=1N9a2SxuV90lkQ1s7g3yK8
        // Other static fields - Alternate timezone, Countdown to Date, Custom Text
        // Move - Steps, distance, floors, calories, active minutes (daily/weekly)
        // Alarms Count / Notifications Count
        // Battery (%/days) / Body Battery
        // Resting HR
        // Moon Phase
        //  https://forums.garmin.com/developer/connect-iq/f/discussion/3029/show-draw-representing-lunar-phase/20888#20888
        // Sensor Temperature, Stress Level %, Time to Recover

        // Think about bars for each field? https://apps.garmin.com/en-US/apps/a9b44812-47b9-4242-ba79-eef25b1807a8

    function formatTime( hours, minutes ) as String {
        var timeFormat = "$1$:$2$";
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            } else if( hours == 0 ) {
                hours = 12;
            }
        } else {
            if (Application.Properties.getValue("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
            }
        }
        return Lang.format(timeFormat, [hours.format("%02d"), minutes.format("%02d")]);
    }

    function myDrawText(dc, x, y, font, text, justification, outlineColor, fillColor) {
		if(outlineColor != Graphics.COLOR_TRANSPARENT) {
			dc.setColor(outlineColor, Graphics.COLOR_TRANSPARENT);
			
			var ds = 3;
			dc.drawText(x - ds, y - ds, font, text, justification);
			dc.drawText(x + ds, y - ds, font, text, justification);
			dc.drawText(x - ds, y + ds, font, text, justification);
			dc.drawText(x + ds, y + ds, font, text, justification);
			
			ds = 4;
			dc.drawText(x, y + ds, font, text, justification);
			dc.drawText(x, y - ds, font, text, justification);
			dc.drawText(x + ds, y, font, text, justification);
			dc.drawText(x - ds, y, font, text, justification);
		}
		
		if(fillColor != Graphics.COLOR_TRANSPARENT) {
			dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
			dc.drawText(x, y, font, text, justification);
		}
	}
    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        //setLayout(Rez.Layouts.WatchFace(dc));
        iconFont = Ui.loadResource(Rez.Fonts.IconsFont);
        timeFont2 = Ui.loadResource(Rez.Fonts.RA);
        Complications.registerComplicationChangeCallback(self.method(:onComplicationChanged));
        Complications.subscribeToUpdates( Complications.getComplication(new Complications.Id( Complications.COMPLICATION_TYPE_SUNRISE )).complicationId);
        Complications.subscribeToUpdates( Complications.getComplication(new Complications.Id( Complications.COMPLICATION_TYPE_SUNSET )).complicationId);
System.println("A");

        var crustDataDictValues = crustDataDict.values() as Array<CrustData>;
        for( var i = 0; i < crustDataDictValues.size(); i++ ) {
            var crustData = crustDataDictValues[i] as CrustData;
            if( crustData.type <= MAX_COMPLICATIONS ) {
                var c = Complications.getComplication(new Complications.Id(crustData.type ));

                // Fix complication label issues            
                if( crustData.type == Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY ) {
                    crustData.label = "";
                } else if( crustData.type == Complications.COMPLICATION_TYPE_PULSE_OX ) {
                    crustData.label = "SPO2 ";
                } else {
                    crustData.label = c.shortLabel + " ";
                }

                crustData.icon = c.getIcon();

                Complications.subscribeToUpdates( c.complicationId );
            // Custom Complications
            } else if( crustData.type == CUSTOM_NEXT_SUN_EVENT ) {
                crustData.label = "NEXT ";
            }
        }
System.println("B");

    }

    function onComplicationChanged(complicationId as Complications.Id) as Void {
        var complication = Complications.getComplication(complicationId);

        var crustData = crustDataDict[complicationId.getType()] as CrustData;
        if( complicationId.getType() == Complications.COMPLICATION_TYPE_SUNRISE ||
            complicationId.getType() == Complications.COMPLICATION_TYPE_SUNSET ) {
            // Value is a non-negative Number representing seconds since midnight local time of the sunrise or null
            var hours = complication.value / (60 * 60);
            var minutes = complication.value % (60 * 60) / 60;
            if( crustData != null ) {
                crustData.value = formatTime( hours, minutes );
            }
            // Now store off the next sun event
            if( complicationId.getType() == Complications.COMPLICATION_TYPE_SUNRISE ) {
                nextSunriseEvent = complication.value;
            } else {
                nextSunsetEvent = complication.value;
            }
        // Value is a Number of the current altitude in meters or null
        } else if( complicationId.getType() == Complications.COMPLICATION_TYPE_ALTITUDE ) {
            // If we need to convert to feet?
            crustData.value = (complication.value * 3).toString();
        } else if( complicationId.getType() == Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY ) {
            var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            var dateString = Lang.format( "$1$ $2$ $3$",
                [
                    today.day_of_week,
                    today.day,
                    today.month,
                ]
            );
            crustData.value = dateString.toUpper();
        } else {
            crustData.value = complication.value;
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
System.println("1");
        // https://forums.garmin.com/developer/connect-iq/f/discussion/349473/simple-example-wf-that-shows-a-bunch-of-things
        var height=dc.getHeight();
        var width=dc.getWidth();
        centerH=height/2;
        centerW=width/2;

        var smallFontHeight = dc.getFontHeight(Graphics.FONT_SMALL)-12;
        //var tinyFontHeight = dc.getFontHeight(Graphics.FONT_TINY)-5;

        // TODO Move these to onLayout()
        var vectorFont = Graphics.getVectorFont({:face=>["NanumGothicBold"], :size=>smallFontHeight});
        var boldVectorFont = Graphics.getVectorFont({:face=>["RobotoCondensedBold","RobotoRegular"], :size=>smallFontHeight+50});
        //var timeFont = Graphics.getVectorFont({:face=>["RobotoCondensedRegular","RobotoRegular"], :size=>165});
        var trueVectorFontHeight = Graphics.getFontAscent(vectorFont) - Graphics.getFontDescent(vectorFont)/2;
        var vectorFontRadius = centerH - trueVectorFontHeight;
        crustRadius = vectorFontRadius;
System.println("2");

        //var tinyVectorFont = Graphics.getVectorFont({:face=>["RobotoCondensedRegular","RobotoRegular"], :size=>tinyFontHeight});

        //var pskFont=Graphics.getVectorFont({:face=>"RobotoCondensedRegular", :size=>height*.2});
        //var vectorR=centerH-smallH;
        //var a = Graphics.getFontAscent(vectorFont);
        //var d = Graphics.getFontDescent(vectorFont);
        //System.println("fh: " + trueVectorFontHeight + " a: " + a + " d: " + d);

        //var vectorFontRadius = centerH - dc.getFontHeight( vectorFont );
        //var pskV = centerH - dc.getFontHeight(pskFont);
        //System.println("smallH: " + smallH);
        //dc.setColor(COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
		dc.clear();

        drawMoon(dc,centerW+70,centerH+200,trueVectorFontHeight*.6);

        //dc.drawRadialText(x, y, font, text, justification, angle, radius, direction)

        // For an outline font:
        dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
	    //dc.drawText(x, y, font, text, justification);

        // Debugging Guideline Circles
        //dc.drawCircle(centerW, centerH, vectorFontRadius);
        //dc.drawCircle(centerW, centerH, centerH);

        //dc.drawCircle(centerW, centerH, centerH - Graphics.getFontAscent(smallVectorFont) );

        //dc.drawCircle(centerW, centerH, centerH - Graphics.getFontAscent(vectorFont) + 
        //    Graphics.getFontDescent(vectorFont)/2 );

        //dc.drawLine(centerW, 0, centerW, smallVectorFontHeight);

        dc.setColor(Application.Properties.getValue("SeparatorColor"), Graphics.COLOR_TRANSPARENT);
        for( var deg = 0; deg < 360; deg += 60 ) {
            dc.drawRadialText( centerW, centerH, boldVectorFont, "|", Graphics.TEXT_JUSTIFY_CENTER, deg, 
                vectorFontRadius * 1.05, 
                Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE );
        }

System.println("3");

        var crustDataDictValues = crustDataDict.values() as Array<CrustData>;
        for( var i = 0; i < crustDataDictValues.size(); i++ ) {
System.println("3.1");
            var crustData = crustDataDictValues[i] as CrustData;
System.println("3.2");
            var deg = crustData.deg;
            var r = vectorFontRadius;
            var dir = Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE;
            var ideg = deg + 20;
            var iconRadius = vectorFontRadius + 13;
            var iconHOffset = 0;
            if( deg < 0 ) {
                ideg = deg -20;
                dir = Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE;
                r += Graphics.getFontDescent(vectorFont)*2.5+5;
                iconHOffset -= 10;
            } else {
                r += 3;
                iconHOffset -= 10;
            }
System.println("3.3");

System.println("4");
            

            // If this is a custom Complication, update the value now
            if( crustData.type == CUSTOM_NEXT_SUN_EVENT ) {
                if( nextSunsetEvent != null && nextSunriseEvent != null ) {
                    var sunriseHours = nextSunriseEvent / (60 * 60);
                    var sunriseMinutes = nextSunriseEvent % (60 * 60) / 60;
                    var sunsetHours = nextSunsetEvent / (60 * 60);
                    var sunsetMinutes = nextSunsetEvent % (60 * 60) / 60;
                    var clockTimeEvent = System.getClockTime().hour * 60 * 60;
                    clockTimeEvent += System.getClockTime().min * 60;
                    clockTimeEvent += System.getClockTime().sec;
                    var fontChar;
                    // if its between sunrise and sunset, then the next event is sunset
                    if( clockTimeEvent > nextSunriseEvent && 
                        clockTimeEvent < nextSunsetEvent ) {
                        crustData.value = formatTime( sunsetHours, sunsetMinutes );
                        fontChar = 63;
                        //crustData.label = "S ";
                    } else { // else the next event is sunrise
                        crustData.value = formatTime( sunriseHours, sunriseMinutes );
                        //crustData.label = "R ";
                        fontChar = 62;
                    }
System.println("5");

                    crustData.label = "";                   
                    //crustData.value += "    ";
                    //drawMoon(dc,centerW+70,centerH+202,trueVectorFontHeight*.6);
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
System.println("5.1");
                    dc.drawText( centerW-70, centerH+190, iconFont, fontChar.toChar()+"", Graphics.TEXT_JUSTIFY_CENTER );
System.println("5.2");
                }
                /*
                var info = Position.getInfo();
                var nextEvent = Weather.getSunrise( info.position, Time.now() );
                if ( nextEvent == null || Time.now().greaterThan( nextEvent) ) {
                    nextEvent = Weather.getSunset( info.position, Time.now() );
                }
                if( nextEvent != null ) {
                    var nextEventInfo = Time.Gregorian.info(nextEvent, Time.FORMAT_MEDIUM );
                    crustData.value = formatTime( nextEventInfo.hour, nextEventInfo.min );
                }*/
            }

            if( crustData.value != null ) {
                // Draw the Label
                var rH = centerH - iconRadius * Math.sin( Math.toRadians(ideg) );
                var rW = centerW + iconRadius * Math.cos( Math.toRadians(ideg) );
                var value = crustData.value.toString();

                if( crustData.icon != null) {
                    dc.drawBitmap( rW, rH, crustData.icon);
                } else if( false && crustData.type != Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY &&
                        crustData.type != CUSTOM_NEXT_SUN_EVENT ) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText( rW, rH + iconHOffset, iconFont, 59.toChar()+"", Graphics.TEXT_JUSTIFY_CENTER );
                } else {
                    value = crustData.label + crustData.value.toString();
                }

                // Draw the value
System.println("5.3");
                dc.setColor(Application.Properties.getValue("DataColor"), Graphics.COLOR_TRANSPARENT);
System.println("5.4: " + value);
                dc.drawRadialText(centerW, centerH, vectorFont,
                    value, 
                    Graphics.TEXT_JUSTIFY_CENTER,
                    deg, r, dir );
System.println("5.5: " + value);
            }
        }
System.println("6");

        // Get the current time and format it correctly
        var clockTime = System.getClockTime();
        var timeString = formatTime( clockTime.hour, clockTime.min );
        // Get the configuration settings
        // https://forums.garmin.com/developer/connect-iq/f/discussion/1767/performance-of-getproperty
        var hourColor = Application.Properties.getValue("HourColor");

        myDrawText(dc, centerW, centerH - Graphics.getFontHeight(timeFont2)/2, timeFont2, 
            timeString, 
            Graphics.TEXT_JUSTIFY_CENTER, hourColor, Graphics.COLOR_BLACK );
System.println("7");

        // Out of the box OUTLINE font
        //dc.drawText( centerW, centerH - Graphics.getFontHeight(timeFont2)/2, timeFont2, 
        //    timeString, Graphics.TEXT_JUSTIFY_CENTER );

        //dc.drawText(centerW, centerH - Graphics.getFontHeight(f)/2, f, "12:01", Graphics.TEXT_JUSTIFY_CENTER);
        //fh = dc.getFontHeight(Graphics.FONT_TINY);
        //dc.drawText(centerW, centerH+50, Graphics.FONT_TINY, "Tiny Font " + fh, Graphics.TEXT_JUSTIFY_CENTER);
        //fh = dc.getFontHeight(Graphics.FONT_XTINY);
        //dc.drawText(centerW, centerH+100, Graphics.FONT_XTINY, "XTiny Font " + fh, Graphics.TEXT_JUSTIFY_CENTER);

        //var font=Graphics.getVectorFont({:face=>"RobotoCondensedRegular", :size=>height*.2});
        // Here I useRobotoCondensedRegular, and set it to be 20% of the screen height (height is from dc.getHeight())
        // After that, it's just making the proper call to display it
        //dc.drawRadialText(width/2, height/2, font, "Battery", Graphics.TEXT_JUSTIFY_CENTER, 0, height/2, 
          //  Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);
        
        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);

        // Draw the moon phase -- Draw this after the next Time event data
		// var w=gW*0.05;

    }

    // https://minkukel.com/en/various/calculating-moon-phase/
    function moonAge() {
        var cycle = 29.53058770576;
        // The first new moon of 2000 was on January 6 at 18:14 UTC
        var today = Time.now();
        //var info = Gregorian.utcInfo(now, Time.FORMAT_SHORT);

        // The first new moon of 2000 was on January 6 at 18:14 UTC
        var options = {
            :year   => 2023,
            :month  => 12,
            :day    => 13,
            :hour   => 18,
            :minute => 14
        };
        var newMoon = Gregorian.moment(options);

        var delta = today.subtract(newMoon).value() / Gregorian.SECONDS_PER_DAY;
        var cyclesF = delta.toFloat() / cycle;
        var cycles = cyclesF.toNumber();
        var lastNewMoon = cycles * cycle;
        var moonAgeDays = delta.toNumber() - lastNewMoon.toNumber();
        return moonAgeDays;
    }

    // https://forums.garmin.com/developer/connect-iq/f/discussion/3029/show-draw-representing-lunar-phase/20888#20888
    function drawMoon(dc,x,y,w){
        var south = false;
		var A = moonAge();
        if(south){A=29.53-A;}
		var F=14.765, Q=F/2.0,Q2=F+Q;
		
		var s=A<F?0:180;
		dc.setPenWidth(w);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawArc(x, y, w/2, 0, 270+s, 90+s);
		
		var p = w/Q*(A>F?A-F:A);
        p=w-p;
		var c = A<Q||A>Q2 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
		dc.setPenWidth(1);
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
		dc.fillEllipse(x, y, p.abs(), w);
		
		//dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		//dc.drawCircle(x, y, w);
	}


    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
