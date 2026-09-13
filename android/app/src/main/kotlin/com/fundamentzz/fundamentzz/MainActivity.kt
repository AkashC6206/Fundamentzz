package com.fundamentzz.fundamentzz

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SETTINGS_CHANNEL = "com.fundamentzz.fundamentzz/settings"
    private val PRINTER_METHODS_CHANNEL = "com.fundamentzz.printer/methods"
    private val PRINTER_EVENTS_CHANNEL = "com.fundamentzz.printer/events"

    private var bluetoothPlugin: BluetoothPrinterPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openBluetoothSettings") {
                try {
                    val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        bluetoothPlugin = BluetoothPrinterPlugin(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRINTER_METHODS_CHANNEL)
            .setMethodCallHandler(bluetoothPlugin)
            
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PRINTER_EVENTS_CHANNEL)
            .setStreamHandler(bluetoothPlugin)
    }

    override fun onDestroy() {
        super.onDestroy()
        bluetoothPlugin?.onDestroy()
    }
}
