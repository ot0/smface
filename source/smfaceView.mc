import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

const weekTable = ["", "日", "月", "火", "水", "木", "金", "土"];
const screenSize = 176;
const center = 88;
const nengo = 2018;
const under = 114;

const weatherType = [
    "快晴", "晴", "くもり", "雪", "強風", "雷雨", "あられ", "きり", "かすみ", "ひょう",
    "雨", "雷雨", "雨", "小雨", "大雨", "小雪", "大雪", "小雨雪", "大雨雪", "くもり",
    "雨雪", "晴", "晴", "小雨", "大雨", "大雨", "俄雨", "俄雷雨", "きり", "ほこり",
    "きり雨", "竜巻", "煙", "氷", "砂", "大雨", "砂嵐", "火山灰", "えんむ", "良好",
    "台風", "台風", "弱雪", "弱雷雨", "弱曇雨", "弱曇雪", "弱雷雨", "雪", "ひょう", "みぞれ",
    "氷雪", "薄曇", "未知"
];

class smfaceView extends WatchUi.WatchFace {
    private var _screenBuf as BufferedBitmap?;
    private var _bufDc as Dc?;
    private var isSleep = false;

    function initialize() {
        WatchFace.initialize();

    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        _screenBuf = new Graphics.BufferedBitmap({
            :width=>screenSize, :height=>screenSize-under,
            :palette=>[Graphics.COLOR_WHITE, Graphics.COLOR_BLACK],
        });
        _bufDc = _screenBuf.getDc();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function drawHand(sec as Number, dc as Dc) as [Number, Number] {
        if(isSleep){
            return [center, center];
        }
        var angle = sec / 60.0 * Math.PI * 2;
        var size = 80;
        var pos = [(center + Math.sin(angle)*size).toNumber(), (center - Math.cos(angle)*size).toNumber()];
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawLine(center, center, pos[0], pos[1]);
        //System.println(width);
        return pos;
    }

    function toTimeString(time as Time.Moment or Null) as String {
        if(time == null){
            return "--:--";
        }
        var gre = Gregorian.info(time, Time.FORMAT_SHORT);
        return gre.hour.format("%02d") + ":" + gre.min.format("%02d");
    }

    function drawTime(time as Gregorian.Info) as Void {
        // 日時表示
        var timeString = Lang.format("$1$/$2$/$3$ $4$:$5$:$6$", 
            [
                (time.year -nengo).toString(), time.month.format("%02d"), time.day.format("%02d"),
                time.hour.format("%02d"), time.min.format("%02d"), time.sec.format("%02d")
            ]);
        (View.findDrawableById("TimeLabel") as Text).setText(timeString);

    }

    function drawHeart(act as Activity.Info) as Void{
        // 心拍数
        var heart = act.currentHeartRate; //.format("%02d");
        (View.findDrawableById("Heart") as Text).setText((heart != null?heart.format("%3d"):"---")+"拍");
    }

    function drawPressure(act as Activity.Info) as Void{
        // 気圧
        var prs = act.ambientPressure; //.format("%02d");
        (View.findDrawableById("Pressure") as Text).setText((prs != null?(prs / 100).format("%4d"):"----")+"hPa");
    }

    function drawStep(step as ActivityMonitor.Info) as Void{
        // 気圧
        var st = step.steps; //.format("%02d");
        (View.findDrawableById("Step") as Text).setText((st != null?st.toString():"----")+"歩");
    }

    function drawButtery(stats as System.Stats) {
        // バッテリ
        var battery = (stats.battery + 0.5).toNumber().toString() + "%";
        (View.findDrawableById("Battery") as Text).setText(battery);

    }

    function drawTop(time as Gregorian.Info, weather as Weather.CurrentConditions) as Void {

        var sunrise = "--:--";
        var sunset = "--:--";

        if(weather != null && weather.observationLocationPosition != null){
            sunrise = toTimeString(Weather.getSunrise(weather.observationLocationPosition, weather.observationTime));
            sunset = toTimeString(Weather.getSunset(weather.observationLocationPosition, weather.observationTime));
        }
        // var pos = new Position.Location({:latitude=>35, :longitude=>135, :format=>:degrees});
        // sunrise = toTimeString(Weather.getSunrise(pos, Time.now()));
        // sunset = toTimeString(Weather.getSunset(pos, Time.now()));        
        var topLine = Lang.format("↑$1$ $2$ $3$↓", [
            sunrise, weekTable[time.day_of_week], sunset,
        ]);
        (View.findDrawableById("Week") as Text).setText(topLine);

    }

    function drawWeather(dc as Dc) as Void {
        // 天気
        var forecast = Weather.getHourlyForecast();
        for(var i=0; i<4; i++){
            var wt = "--:--";
            var pc = "--%";
            var cd = "--";
            var tmp = "--℃";
            if(forecast != null && i<forecast.size()){
                var f = forecast[i];
                wt = toTimeString(f.forecastTime);
                pc = f.precipitationChance != null?f.precipitationChance.toString()+"%":pc;
                cd = f.condition != null? weatherType[f.condition]:cd;
                tmp = f.temperature !=null? f.temperature.format("%2d")+"℃":tmp;
            }
            var xp = i*42+24;
            dc.drawText(xp, 0, Graphics.FONT_XTINY, wt, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(xp, 14, Graphics.FONT_XTINY, cd, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*38+32, 28, Graphics.FONT_XTINY, tmp, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*35+38, 42, Graphics.FONT_XTINY, pc, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get the current time and format it correctly
        //var time = System.getClockTime();
        dc.setClip(0,0,screenSize, screenSize);
        var time = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var act = Activity.getActivityInfo();
        var weather = Weather.getCurrentConditions();
        var stats = System.getSystemStats();
        var step = ActivityMonitor.getInfo();

        drawTop(time, weather);
        drawButtery(stats);
        drawPressure(act);

        drawTime(time);
        drawHeart(act);
        drawStep(step);
        View.onUpdate(dc);

        if(_bufDc != null && _screenBuf != null){
            //_bufDc.clear(); //clear はシンボルエラー
            _bufDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            _bufDc.fillRectangle(0, 0, screenSize, screenSize-under);

            _bufDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            drawWeather(_bufDc);
            dc.drawBitmap(0, under, _screenBuf);
        }

        drawHand(time.sec, dc);
        // dc.drawText(20, 90, Graphics.FONT_XTINY, weatherType[time.sec % 53], Graphics.TEXT_JUSTIFY_CENTER);
        
    }

    function onPartialUpdate(dc as Dc) as Void {
        var time = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        //var act = Activity.getActivityInfo();
        //var step = ActivityMonitor.getInfo();
        
        dc.setClip(136, 30, 164, 46);

        drawTime(time);
        //drawHeart(act);
        //drawStep(step);
        View.onUpdate(dc);

        // if(_screenBuf != null){
        //     dc.drawBitmap(0,under, _screenBuf);
        // }
        
        // drawHand(time.sec, dc);
        // pos[0] -=3; //針の太さ分
        // pos[1] +=3;
        // var xs = pos[0]<center?pos[0]:center;
        // var ye =  pos[1]>center?pos[1]:center;
        // dc.setClip(xs, 8, 169-xs, ye-7);
        // System.println(time.sec + ":" +xs + ":" + ye);
        // dc.setClip(88, 8, 176, 88);
        
    }


    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isSleep = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isSleep = true;
    }

}
