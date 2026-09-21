package com.example.busing

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class BusingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // 💡 [수석 개발자] Flutter SharedPreferences에서 실제 데이터 읽기
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val busName = prefs.getString("flutter.widget_busName", "정보 없음") ?: "정보 없음"
        val remainMin = prefs.getString("flutter.widget_remainMin", "도착정보없음") ?: "도착정보없음"
        val stopName = prefs.getString("flutter.widget_stopName", "설정 대기 중") ?: "설정 대기 중"

        val mainText = if (remainMin == "도착정보없음" || remainMin == "-1" || remainMin == "-2") {
            "$busName | 도착정보없음"
        } else {
            "$busName | ${remainMin}분 후 도착"
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.busing_widget_layout)
            views.setTextViewText(R.id.widget_title, "🚌 버씽 실시간 막차/루틴 안내")
            views.setTextViewText(R.id.widget_info, mainText)
            views.setTextViewText(R.id.widget_sub, stopName)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
