import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.SensorHistory;
import Toybox.Weather;

const weekTable = ["", "日", "月", "火", "水", "木", "金", "土"];
const screenSize = 176;
const center = 88;
const nengo = 2018;

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
    private var handX as Array<Number>?;
    private var handY as Array<Number>?;


    function initialize() {
        WatchFace.initialize();

        handX = new Array<Number>[60];
        handY = new Array<Number>[60];
        var size = 80;
        for(var i=0; i<60; i++){
            var angle = i / 60.0 * Math.PI * 2;
            handX[i] = (center + Math.sin(angle)*size).toNumber();
            handY[i] = (center - Math.cos(angle)*size).toNumber();
        }

        _screenBuf = new Graphics.BufferedBitmap({
            :width=>screenSize, :height=>screenSize,
            :palette=>[Graphics.COLOR_BLACK, Graphics.COLOR_WHITE],
        });
        _bufDc = _screenBuf.getDc();
        _bufDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        _bufDc.drawRectangle(0, 0, 176, 176);
        _bufDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // System.println(dc.getFontHeight(Graphics.FONT_XTINY)); //14
        // System.println(dc.getFontHeight(Graphics.FONT_TINY)); //19
        // System.println(dc.getFontHeight(Graphics.FONT_SMALL)); //20
        // System.println(dc.getFontHeight(Graphics.FONT_MEDIUM)); //22
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function drawHand(dc as Dc, sec as Number) as Void {
        dc.setPenWidth(3);
        // var angle = sec / 60.0 * Math.PI * 2;
        // var size = 80;
        // var pos = [(center + Math.sin(angle)*size).toNumber(), (center - Math.cos(angle)*size).toNumber()];
        // dc.drawLine(center, center, pos[0], pos[1]);
        dc.drawLine(center, center, handX[sec], handY[sec]);
        //System.println(width);
    }

    function drawTime(dc as Dc, time as Gregorian.Info) as Void {
        // 日時表示
        var timeString = Lang.format("$1$/$2$/$3$ $4$:$5$:", 
            [
                (time.year -nengo).toString(), time.month.format("%02d"), time.day.format("%02d"),
                time.hour.format("%02d"), time.min.format("%02d"),
            ]);
        dc.drawText(147, 24, Graphics.FONT_SMALL, timeString, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    function onSecond(dc as Dc, sec as Number) as Void {
        // 秒
        dc.drawText(147, 24, Graphics.FONT_SMALL, sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);

        // 心拍数
        var heart = Activity.getActivityInfo().currentHeartRate;
        dc.drawText(142, 45, Graphics.FONT_MEDIUM, (heart != null?heart.format("%3d"):"---")+"拍", Graphics.TEXT_JUSTIFY_CENTER);

        // 歩数
        var st = ActivityMonitor.getInfo().steps;
        dc.drawText(142, 66, Graphics.FONT_SMALL,(st != null?st.toString():"----")+"歩", Graphics.TEXT_JUSTIFY_CENTER);

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
        var device = System.getDeviceSettings();

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
        dc.drawText(center, 4, Graphics.FONT_SMALL, topLine, Graphics.TEXT_JUSTIFY_CENTER);

        // バッテリ
        var battery = (stats.battery + 0.5).format("%d") + "%";
        dc.drawText(44, 45, Graphics.FONT_MEDIUM, battery, Graphics.TEXT_JUSTIFY_RIGHT);

        var inDay = (stats.batteryInDays);
        dc.drawText(54, 47, Graphics.FONT_TINY, (inDay != null?inDay.format("%d"):"--") + "日", Graphics.TEXT_JUSTIFY_LEFT);

        // 気圧
        var prs = act.ambientPressure; //.format("%02d");
        dc.drawText(34, 66, Graphics.FONT_SMALL, (prs != null?(prs / 100).format("%4d"):"----")+"hPa", Graphics.TEXT_JUSTIFY_CENTER);

        // 通知
        var notifiy = device.notificationCount;
        dc.drawText(34, 86, Graphics.FONT_SMALL, (notifiy != null?notifiy.toString():"-") + "通", Graphics.TEXT_JUSTIFY_CENTER);

        // ストレス
        var iter = SensorHistory.getStressHistory({});
        var stress = "--st";
        var st = iter.next();
        while (st != null){
            if(st.data != null){
                stress = st.data.format("%d") + "st";
                break;
            }
            st = iter.next();
        }
        dc.drawText(142, 87, Graphics.FONT_SMALL, stress, Graphics.TEXT_JUSTIFY_CENTER);


        //dc.drawCircle(88,88,80);
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
            dc.drawText(i*24+41, 50+offset, Graphics.FONT_XTINY, wind, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*29+31, 37+offset, Graphics.FONT_XTINY, pc, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*32+25, 24+offset, Graphics.FONT_XTINY, tmp, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(xp, 11+offset, Graphics.FONT_XTINY, cd, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var time = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        // _bufDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        // _bufDc.drawRectangle(0, 0, screenSize, screenSize);
        // _bufDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        onMimute(_bufDc, time.day_of_week);
        drawWeather(_bufDc, 107);
        drawTime(_bufDc, time);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setClip(0, 0, 176, 176);

        dc.drawBitmap(0, 0, _screenBuf);

        onSecond(dc, time.sec);
        
        drawHand(dc, time.sec);
        // dc.drawText(20, 90, Graphics.FONT_XTINY, weatherType[time.sec % 53], Graphics.TEXT_JUSTIFY_CENTER);
        
    }

    function onPartialUpdate(dc as Dc) as Void {
        var sec = System.getClockTime().sec;
        
        if(sec>45){
            dc.setClip(handX[sec-1]-1, 8, 170, 89);
        }else if(sec>30){
            dc.setClip(handX[sec]-1, 8, 170, handY[sec-1]+1);
        }else if(sec>15){
            dc.setClip(87, 8, 170, handY[sec]+1);
        }else{
            dc.setClip(87, 8, 170, 89);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.drawBitmap(0, 0, _screenBuf);

        onSecond(dc, sec);        
        drawHand(dc, sec);
        
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

class SmfaceViewDelegate extends WatchUi.WatchFaceDelegate {
    function initialize() {
        WatchFaceDelegate.initialize();
    }
    function onPowerBudgetExceeded(powerInfo) as Void{
        System.println(powerInfo.executionTimeAverage);
        System.println(powerInfo.executionTimeLimit);
    }
}