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
const nengo = 2018;
const hand = 82;
const centerY = 86;

const weatherType = [
    "快晴", "晴", "曇り", "雪", "強風", "雷雨", "あられ", "きり", "かすみ", "ひょう",
    "雨", "雷雨", "雨", "小雨", "大雨", "小雪", "大雪", "小雨雪", "大雨雪", "曇り",
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
        for(var i=0; i<60; i++){
            var angle = i / 60.0 * Math.PI * 2;
            handX[i] = (88 + Math.sin(angle)*hand).toNumber();
            handY[i] = (centerY - Math.cos(angle)*hand).toNumber();
        }

        _screenBuf = new Graphics.BufferedBitmap({
            :width=>172, :height=>168,
            :palette=>[Graphics.COLOR_BLACK, Graphics.COLOR_WHITE],
        });
        _bufDc = _screenBuf.getDc();
        _bufDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        _bufDc.fillRectangle(0, 0, 174, 168);
        _bufDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // System.println(dc.getFontHeight(Graphics.FONT_XTINY)); //14
        // System.println(dc.getFontHeight(Graphics.FONT_TINY)); //19
        // System.println(dc.getFontHeight(Graphics.FONT_SMALL)); //20
        // System.println(dc.getFontHeight(Graphics.FONT_MEDIUM)); //22
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);        
        dc.clear();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function drawHand(dc as Dc, sec as Number) as Void {
        dc.setPenWidth(3);
        dc.drawLine(88, centerY, handX[sec], handY[sec]);
    }

    function drawTime(dc as Dc, time as Gregorian.Info) as Void {
        // 日時表示
        var timeString = Lang.format("$1$/$2$/$3$ $4$:$5$:", 
            [
                (time.year -nengo).toString(), time.month.format("%02d"), time.day.format("%02d"),
                time.hour.format("%02d"), time.min.format("%02d"),
            ]);
        dc.drawText(138, 20, Graphics.FONT_SMALL, timeString, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    function onSecond(dc as Dc, sec as Number) as Void {
        // 秒
        dc.drawText(140, 20, Graphics.FONT_SMALL, sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);

        // 心拍数
        var heart = Activity.getActivityInfo().currentHeartRate;
        dc.drawText(174, 40, Graphics.FONT_MEDIUM, (heart != null?heart.format("%3d"):"---")+"拍", Graphics.TEXT_JUSTIFY_RIGHT);

        // 歩数
        var st = ActivityMonitor.getInfo().steps;
        dc.drawText(174, 62, Graphics.FONT_SMALL,(st != null?st.toString():"----")+"歩", Graphics.TEXT_JUSTIFY_RIGHT);

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
        var topLine = Lang.format("$1$ $2$ $3$", [
            sunrise, weekTable[day_of_week], sunset,
        ]);
        dc.drawText(86, 0, Graphics.FONT_SMALL, topLine, Graphics.TEXT_JUSTIFY_CENTER);

        // バッテリ
        var battery = (stats.battery + 0.5).format("%d") + "%";
        dc.drawText(42, 40, Graphics.FONT_MEDIUM, battery, Graphics.TEXT_JUSTIFY_RIGHT);

        var inDay = (stats.batteryInDays);
        dc.drawText(42, 43, Graphics.FONT_TINY, (inDay != null?inDay.format("%d"):"--") + "日", Graphics.TEXT_JUSTIFY_LEFT);

        // 通知
        var notifiy = device.notificationCount;
        dc.drawText(100, 40, Graphics.FONT_MEDIUM, (notifiy != null?notifiy.toString():"-") + "通", Graphics.TEXT_JUSTIFY_CENTER);

        // 気圧
        var prs = act.ambientPressure; //.format("%02d");
        dc.drawText(34, 62, Graphics.FONT_SMALL, (prs != null?(prs / 100).format("%4d"):"----")+"hPa", Graphics.TEXT_JUSTIFY_CENTER);


        // ボディバッテリ
        var iterBb = SensorHistory.getBodyBatteryHistory({});
        var body = "--bb";
        var bb = iterBb.next();
        while (bb != null){
            if(bb.data != null){
                body = bb.data.format("%d") + "bb";
                break;
            }
            bb = iterBb.next();
        }
        dc.drawText(34, 82, Graphics.FONT_SMALL, body, Graphics.TEXT_JUSTIFY_CENTER);

        // ストレス
        var iterSt = SensorHistory.getStressHistory({});
        var stress = "--st";
        var st = iterSt.next();
        while (st != null){
            if(st.data != null){
                stress = st.data.format("%d") + "st";
                break;
            }
            st = iterSt.next();
        }
        dc.drawText(140, 82, Graphics.FONT_SMALL, stress, Graphics.TEXT_JUSTIFY_CENTER);


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
                tmp = f.temperature !=null? f.temperature.format("%d")+"℃":tmp;
                wind = f.windSpeed!=null? f.windSpeed.format("%d")+"m":wind;
            }
            var xp = i*35+16;
            dc.drawText(xp, 0+offset, Graphics.FONT_XTINY, wt, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*27+32, 52+offset, Graphics.FONT_XTINY, wind, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(i*31+24, 39+offset, Graphics.FONT_XTINY, pc, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(xp, 26+offset, Graphics.FONT_XTINY, tmp, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(xp, 12+offset, Graphics.FONT_XTINY, cd, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var time = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        //_bufDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        _bufDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        _bufDc.fillRectangle(0, 0, 174, 168);
        _bufDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        onMimute(_bufDc, time.day_of_week);
        drawWeather(_bufDc, 102);
        drawTime(_bufDc, time);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setClip(2, 0, 174, 168);

        dc.drawBitmap(2, 0, _screenBuf);

        onSecond(dc, time.sec);
        
        drawHand(dc, time.sec);
        
    }

    function onPartialUpdate(dc as Dc) as Void {
        var sec = System.getClockTime().sec;
        
        var of = centerY-hand;
        var ou = 88+hand;
        if(sec>45){
            //46-59
            var x = handX[sec-1]-1;
            dc.setClip(x, of, 160-x, hand+2);
            //dc.setClip(handX[sec-1]-1, 0, 176, 89);
        }else if(sec>30){
            //31-45
            var x = handX[sec]-1;
            dc.setClip(x, 20, 160-x, handY[sec-1]+2-20);
        }else if(sec>15){
            //16-30
            dc.setClip(87, 20, ou-87, handY[sec]+2-20);
        }else{
            //0-15
            dc.setClip(87, of, ou-87, hand+1);
        }
        // dc.setClip(87, 24, 168, 89);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.drawBitmap(2, 0, _screenBuf);

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