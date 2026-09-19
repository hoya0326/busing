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
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.busing_widget_layout)
            views.setTextViewText(R.id.widget_title, "🚌 버씽 실시간 막차 위젯")
            views.setTextViewText(R.id.widget_info, "첨단30 | 3분 후 도착")
            views.setTextViewText(R.id.widget_sub, "삼익아파트 정류장 · 1개 전")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
