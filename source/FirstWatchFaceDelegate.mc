import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Application;
import Toybox.Complications;

class FirstWatchFaceDelegate extends WatchUi.WatchFaceDelegate {

  var view;

	function initialize(viewp) {
		WatchFaceDelegate.initialize();
    view = viewp;
	}

  public function onPress(clickEvent) {
    // grab the [x,y] position of the clickEvent
    var co_ords = clickEvent.getCoordinates();
    var crustRadius = view.getCrustRadius(); 
    var centerY = view.getCenterH();
    var centerX = view.getCenterW();
    var complicationType = 0;
    var reversedDegrees;

    //System.println(crustRadius + " " + centerX + " " + centerY);

    //System.println( "clickEvent x:" + co_ords[0] + ", y:" + co_ords[1] );

    // returns the complicationId within the boundingBoxes

    // test if click coords are outside radius
    if (Math.sqrt(Math.pow((co_ords[0]-centerX), 2) + Math.pow((co_ords[1]-centerY), 2)) >= crustRadius) {
      //System.println("We have entered the crust");
      // see which sector the coords are in
      var radians = Math.atan2(co_ords[1]-centerX, co_ords[0]-centerY);
      reversedDegrees = -Math.toDegrees(radians);
      //System.println(radians + " " + reversedDegrees);

    } else {
      //System.println("On the cheese");
      return(false);
    }


    var crustDataDictValues = view.getCrustDataDict.values() as Array<CrustData>;
    for( var i = 0; i < crustDataDictValues.size(); i++ ) {
      var crustData = crustDataDictValues[i] as CrustData;
        var deg = crustData.deg;
        if (reversedDegrees > deg-30 and reversedDegrees < deg+30) {
          //System.println(compCache["type"]);
          complicationType = crustData.type;
        }
    }

    //
    if (complicationType <= 40) {
        //System.println( "We found a complication! let's launch it: " + complicationType );
        var thisComplication = new Complications.Id(complicationType);
        if (thisComplication != 0 ) {
          //System.println( "Launching Complication: " + 
          //  Complications.getComplication(thisComplication).longLabel );
          Complications.exitTo(thisComplication);
          WatchUi.requestUpdate();
        }
        return(true);
    } else {
        //System.println( "No complication found" );
    }

    return(false);
  }
}