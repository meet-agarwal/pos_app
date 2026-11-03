package com.example.pos_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var xprinterBridge: XprinterBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        xprinterBridge = XprinterBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
