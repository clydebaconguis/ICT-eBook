package com.example.ebooks

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager.LayoutParams
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    window.clearFlags(LayoutParams.FLAG_SECURE)
    super.configureFlutterEngine(flutterEngine)
  }
}

