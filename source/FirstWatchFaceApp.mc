import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Complications;

class FirstWatchFaceApp extends Application.AppBase {
    var complicationFaceView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        /*
        Complications.registerComplicationChangeCallback(self.method(:onComplicationChanged));

        heartRateComplicationId = new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE);
        Complications.subscribeToUpdates(heartRateComplicationId);

        altitudeComplicationId = new Complications.Id(Complications.COMPLICATION_TYPE_ALTITUDE);
        Complications.subscribeToUpdates(altitudeComplicationId);
        */
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() {
        complicationFaceView = new FirstWatchFaceView();
        var delegate = new FirstWatchFaceDelegate( complicationFaceView );

        return [ complicationFaceView, delegate ];
    }


    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

}

/* not needed anymore
function getApp() as FirstWatchFaceApp {
    return Application.getApp() as FirstWatchFaceApp;
}
*/