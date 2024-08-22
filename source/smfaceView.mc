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
const under = 112;

const weatherType = [
    "快晴", "晴", "くもり", "雪", "強風", "雷雨", "あられ", "きり", "かすみ", "ひょう",
    "雨", "雷雨", "雨", "小雨", "大雨", "小雪", "大雪", "小雨雪", "大雨雪", "くもり",
    "雨雪", "晴", "晴", "小雨", "大雨", "大雨", "俄雨", "俄雷雨", "きり", "ほこり",
    "きり雨", "竜巻", "煙", "氷", "砂", "大雨", "砂嵐", "火山灰", "えんむ", "良好",
    "台風", "台風", "弱雪", "弱雷雨", "弱曇雨", "弱曇雪", "弱雷雨", "雪", "ひょう", "みぞれ",
    "氷雪", "薄曇", "未知"
];

class smfaceView extends WatchUi.WatchFace {
    //private var _screenBuf as BufferedBitmap?;
    //private var _bufDc as Dc?;
    private var _isSleep = false;
    //private var handX as Array<Number>[60];


    function initialize() {
        WatchFace.initialize();

    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // _screenBuf = new Graphics.BufferedBitmap({
        //     :width=>screenSize, :height=>screenSize-under,
        //     :palette=>[Graphics.COLOR_WHITE, Graphics.COLOR_BLACK],
        // });
        // _bufDc = _screenBuf.getDc();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function drawHand(dc as Dc, sec as Number) as [Number, Number] {
        if(_isSleep){
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

    function drawTime(dc as Dc, time as Gregorian.Info) as Void {
        // 日時表示
        var timeString = Lang.format("$1$/$2$/$3$ $4$:$5$:$6$", 
            [
                (time.year -nengo).toString(), time.month.format("%02d"), time.day.format("%02d"),
                time.hour.format("%02d"), time.min.format("%02d"), time.sec.format("%02d")
            ]);
        dc.drawText(center, 25, Graphics.FONT_SMALL, timeString, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onSecond(dc as Dc) as Void {
        // 心拍数
        var act = Activity.getActivityInfo();
        var heart = act.currentHeartRate; //.format("%02d");
        dc.drawText(142, 55, Graphics.FONT_MEDIUM, (heart != null?heart.format("%3d"):"---")+"拍", Graphics.TEXT_JUSTIFY_CENTER);

        // 歩数
        var step = ActivityMonitor.getInfo();
        var st = step.steps; //.format("%02d");
        dc.drawText(142, 80, Graphics.FONT_SMALL,(st != null?st.toString():"----")+"歩", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function toTimeString(time as Time.Moment or Null) as String {
        if(time == null){
            return "--:--";
        }
        var gre = Gregorian.info(time, Time.FORMAT_SHORT);
        return gre.hour.format("%02d") + ":" + gre.min.format("%02d");
    }

    function onMimute(dc as Dc, day_of_week as Number) as Void{
        var weather = Weather.getCurrentConditions();
        var act = Activity.getActivityInfo();
        var stats = System.getSystemStats();

        // top
        var sunrise = "--:--";
        var sunset = "--:--";
        if(weather != null && weather.observationLocationPosition != null){
            sunrise = toTimeString(Weather.getSunrise(weather.observationLocationPosition, weather.observationTime));
            sunset = toTimeString(Weather.getSunset(weather.observationLocationPosition, weather.observationTime));
        }
        var topLine = Lang.format("↑$1$ $2$ $3$↓", [
            sunrise, weekTable[day_of_week], sunset,
        ]);
        dc.drawText(center, 5, Graphics.FONT_SMALL, topLine, Graphics.TEXT_JUSTIFY_CENTER);

        // バッテリ
        var battery = (stats.battery + 0.5).toNumber().toString() + "%";
        dc.drawText(34, 55, Graphics.FONT_MEDIUM, battery, Graphics.TEXT_JUSTIFY_CENTER);

        // 気圧
        var prs = act.ambientPressure; //.format("%02d");
        dc.drawText(34, 80, Graphics.FONT_SMALL, (prs != null?(prs / 100).format("%4d"):"----")+"hPa", Graphics.TEXT_JUSTIFY_CENTER);

    }

    function drawWeather(dc as Dc, offset as Number) as Void {
        // 天気
        var forecast = Weather.getHourlyForecast();
        for(var i=0; i<5; i++){
            var wt = "--時";
            var pc = "--%";
            var cd = "--";
            var tmp = "--℃";
            var wind = "--m";
            if(forecast != null && i<forecast.size()){
                var f = forecast[i];
                wt = Gregorian.info(f.forecastTime, Time.FORMAT_SHORT).hour.toString() + "時";
                pc = f.precipitationChance != null?f.precipitationChance.toString()+"%":pc;
                cd = f.condition != null? weatherType[f.condition]:cd;
                tmp = f.temperature !=null? f.temperature.format("%2d")+"℃":tmp;
                wind = f.windSpeed!=null? f.windSpeed.format("%2d")+"m":tmp;
            }
            var xp = i*35+19;
            dc.drawText(xp, -1+offset, Graphics.FONT_XTINY, wt, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*32+25, 24+offset, Graphics.FONT_XTINY, tmp, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*29+31, 36+offset, Graphics.FONT_XTINY, pc, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*24+41, 49+offset, Graphics.FONT_XTINY, wind, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(xp, 11+offset, Graphics.FONT_XTINY, cd, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var time = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        onMimute(dc, time.day_of_week);
        drawWeather(dc, under);

        onSecond(dc);
        drawTime(dc, time);
        
        drawHand(dc, time.sec);
        // dc.drawText(20, 90, Graphics.FONT_XTINY, weatherType[time.sec % 53], Graphics.TEXT_JUSTIFY_CENTER);
        
    }

    function onPartialUpdate(dc as Dc) as Void {
        var time = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        //var act = Activity.getActivityInfo();
        //var step = ActivityMonitor.getInfo();
        
        dc.setClip(136, 25, 164, 41);

        drawTime(dc, time);
        //drawHeart(act);
        //drawStep(step);

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
        _isSleep = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        _isSleep = true;
    }

}

class SmfaceViewDelegate extends WatchUi.WatchFaceDelegate {
    function initialize() {
        WatchFaceDelegate.initialize();
    }
    function onPowerBudgetExceeded(powerInfo) as Void{
        System.println(powerInfo.executionTimeAverage);
        System.println(powerInfo.executionTimeLimit);
    }
}