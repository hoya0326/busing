package com.example.busing

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

class BusingWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_WIDGET_REFRESH = "com.example.busing.ACTION_WIDGET_REFRESH"
        const val ACTION_WIDGET_CLICK = "com.example.busing.ACTION_WIDGET_CLICK"
        const val ACTION_WIDGET_PREV = "com.example.busing.ACTION_WIDGET_PREV"
        const val ACTION_WIDGET_NEXT = "com.example.busing.ACTION_WIDGET_NEXT"
    }

    private fun getSafeInt(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
        return try {
            val value = prefs.all[key]
            when (value) {
                is Int -> value
                is Long -> value.toInt()
                is Number -> value.toInt()
                else -> defaultVal
            }
        } catch (e: Exception) {
            defaultVal
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val count = getSafeInt(prefs, "flutter.widget_count", 1)
        var index = getSafeInt(prefs, "flutter.widget_index", 0)

        when (intent.action) {
            ACTION_WIDGET_PREV -> {
                index = max(0, index - 1)
                prefs.edit().putInt("flutter.widget_index", index).apply()
            }
            ACTION_WIDGET_NEXT -> {
                index = min(count - 1, index + 1)
                prefs.edit().putInt("flutter.widget_index", index).apply()
            }
        }

        if (intent.action == ACTION_WIDGET_PREV ||
            intent.action == ACTION_WIDGET_NEXT ||
            intent.action == ACTION_WIDGET_REFRESH ||
            intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, BusingWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val count = max(1, getSafeInt(prefs, "flutter.widget_count", 1))
        var index = getSafeInt(prefs, "flutter.widget_index", 0)
        if (index < 0) index = 0
        if (index >= count) index = count - 1

        val busName = prefs.getString("flutter.widget_busName_$index", null)
            ?: prefs.getString("flutter.widget_busName", "대기 중") ?: "대기 중"

        val remainMin = prefs.getString("flutter.widget_remainMin_$index", null)
            ?: prefs.getString("flutter.widget_remainMin", "막차시간이 아닙니다") ?: "막차시간이 아닙니다"

        val stopName = prefs.getString("flutter.widget_stopName_$index", null)
            ?: prefs.getString("flutter.widget_stopName", "18:00 ~ 00:00 사이 가동됩니다") ?: "18:00 ~ 00:00 사이 가동됩니다"

        val isNotLastBusTime = remainMin == "막차시간이 아닙니다" || busName == "대기 중"

        val mainText = when {
            isNotLastBusTime -> "막차시간이 아닙니다"
            remainMin == "도착정보없음" || remainMin == "-1" || remainMin == "-2" -> "$busName | 도착정보없음"
            else -> "$busName | ${remainMin}분 후 도착"
        }

        val subText = if (isNotLastBusTime) {
            if (stopName.isNotEmpty() && stopName != "설정 대기 중") stopName else "18:00 ~ 00:00 사이 가동됩니다"
        } else {
            stopName
        }

        val sdf = SimpleDateFormat("HH:mm", Locale.KOREA)
        val timeStr = "${sdf.format(Date())} 기준 업데이트"

        // 버튼 비활성화 색상 구분 설정
        val activeColor = Color.parseColor("#60A5FA") // 활성화 색상 (밝은 블루)
        val disabledColor = Color.parseColor("#4B5563") // 비활성화 색상 (어두운 회색)

        val hasPrev = index > 0
        val hasNext = index < count - 1

        val leftColor = if (hasPrev) activeColor else disabledColor
        val rightColor = if (hasNext) activeColor else disabledColor

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.busing_widget_layout)
            views.setTextViewText(R.id.widget_title, "버씽 막차알림 정보")
            views.setTextViewText(R.id.widget_info, mainText)
            views.setTextViewText(R.id.widget_sub, subText)
            views.setTextViewText(R.id.widget_time, timeStr)
            views.setTextViewText(R.id.widget_page_text, "${index + 1}/$count")

            // 좌우 버튼 색상 할당
            views.setInt(R.id.widget_prev_button, "setColorFilter", leftColor)
            views.setInt(R.id.widget_next_button, "setColorFilter", rightColor)

            // 1. 이전 버튼
            val prevIntent = Intent(context, BusingWidgetProvider::class.java).apply {
                action = ACTION_WIDGET_PREV
            }
            val prevPendingIntent = PendingIntent.getBroadcast(
                context,
                101,
                prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_prev_button, prevPendingIntent)

            // 2. 다음 버튼
            val nextIntent = Intent(context, BusingWidgetProvider::class.java).apply {
                action = ACTION_WIDGET_NEXT
            }
            val nextPendingIntent = PendingIntent.getBroadcast(
                context,
                102,
                nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_next_button, nextPendingIntent)

            // 3. 새로고침 버튼
            val refreshIntent = Intent(context, BusingWidgetProvider::class.java).apply {
                action = ACTION_WIDGET_REFRESH
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context,
                103,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshPendingIntent)

            // 4. 위젯 전체 클릭 시 선택된 목적지 길안내로 진입
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_WIDGET_CLICK
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                104,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
