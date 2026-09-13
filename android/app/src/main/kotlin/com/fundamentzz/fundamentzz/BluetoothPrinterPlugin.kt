package com.fundamentzz.fundamentzz

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

@SuppressLint("MissingPermission")
class BluetoothPrinterPlugin(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val TAG = "BluetoothPrinterPlugin"
    private val mainHandler = Handler(Looper.getMainLooper())
    
    @Volatile
    private var isDetached = false
    private var eventSink: EventChannel.EventSink? = null
    
    private val bluetoothAdapter: BluetoothAdapter? = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    private var connectionManager: BluetoothConnectionManager? = null

    private val discoveredDevices = mutableSetOf<BluetoothDevice>()

    /**
     * Dispatches an event to Flutter guaranteed on the Android Main/UI thread.
     * All calls to EventSink (success/error/endOfStream) must be on the main thread.
     */
    private fun sendEvent(data: Any?) {
        if (isDetached) return
        val action = Runnable {
            if (!isDetached) {
                try {
                    eventSink?.success(data)
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending event to Flutter: ${e.message}")
                }
            }
        }
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action.run()
        } else {
            mainHandler.post(action)
        }
    }

    private fun sendError(errorCode: String, errorMessage: String?, errorDetails: Any? = null) {
        if (isDetached) return
        val action = Runnable {
            if (!isDetached) {
                try {
                    eventSink?.error(errorCode, errorMessage, errorDetails)
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending error to Flutter: ${e.message}")
                }
            }
        }
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action.run()
        } else {
            mainHandler.post(action)
        }
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    device?.let {
                        if (isPrinter(it)) {
                            discoveredDevices.add(it)
                            broadcastDiscoveredDevices()
                        }
                    }
                }
                BluetoothDevice.ACTION_BOND_STATE_CHANGED -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    val state = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.ERROR)
                    device?.let {
                        val event = JSONObject().apply {
                            put("event", "pairing_status")
                            put("address", it.address)
                            put("status", when(state) {
                                BluetoothDevice.BOND_BONDED -> "paired"
                                BluetoothDevice.BOND_BONDING -> "pairing"
                                else -> "unpaired"
                            })
                        }
                        sendEvent(event.toString())
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_STARTED -> {
                    sendEvent(JSONObject().apply { put("event", "discovery_started") }.toString())
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    sendEvent(JSONObject().apply { put("event", "discovery_finished") }.toString())
                }
                BluetoothAdapter.ACTION_STATE_CHANGED -> {
                    val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                    val event = JSONObject().apply {
                        put("event", "bluetooth_state_changed")
                        put("enabled", state == BluetoothAdapter.STATE_ON)
                    }
                    sendEvent(event.toString())
                }
            }
        }
    }

    init {
        connectionManager = BluetoothConnectionManager(context) { state ->
            val event = JSONObject().apply {
                put("event", "connection_state")
                put("state", state.stateName)
            }
            sendEvent(event.toString())
        }

        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
        }
        context.registerReceiver(receiver, filter)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSdkVersion" -> {
                result.success(Build.VERSION.SDK_INT)
                return
            }
        }

        if (bluetoothAdapter == null) {
            result.error("UNAVAILABLE", "Bluetooth is not available on this device", null)
            return
        }

        when (call.method) {
            "isBluetoothEnabled" -> result.success(bluetoothAdapter.isEnabled)
            "enableBluetooth" -> {
                if (!bluetoothAdapter.isEnabled) {
                    val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                }
                result.success(true)
            }
            "startDiscovery" -> {
                discoveredDevices.clear()
                if (bluetoothAdapter.isDiscovering) {
                    bluetoothAdapter.cancelDiscovery()
                }
                bluetoothAdapter.startDiscovery()
                result.success(true)
            }
            "stopDiscovery" -> {
                if (bluetoothAdapter.isDiscovering) {
                    bluetoothAdapter.cancelDiscovery()
                }
                result.success(true)
            }
            "getPairedPrinters" -> {
                val pairedDevices = bluetoothAdapter.bondedDevices
                val printers = pairedDevices?.filter { isPrinter(it) } ?: emptyList()
                val jsonArray = JSONArray()
                for (device in printers) {
                    val obj = JSONObject().apply {
                        put("name", device.name ?: "Unknown Printer")
                        put("address", device.address)
                        put("isPaired", true)
                    }
                    jsonArray.put(obj)
                }
                result.success(jsonArray.toString())
            }
            "pair" -> {
                val address = call.argument<String>("address") ?: return result.error("INVALID_ARG", "MAC address required", null)
                val device = bluetoothAdapter.getRemoteDevice(address)
                if (device.bondState != BluetoothDevice.BOND_BONDED) {
                    device.createBond()
                }
                result.success(true)
            }
            "connect" -> {
                val address = call.argument<String>("address") ?: return result.error("INVALID_ARG", "MAC address required", null)
                if (!bluetoothAdapter.isEnabled) {
                    return result.error("BLUETOOTH_DISABLED", "Bluetooth is turned off", null)
                }
                val device = bluetoothAdapter.getRemoteDevice(address)
                
                // Stop discovery before connecting (improves connection success rate)
                if (bluetoothAdapter.isDiscovering) {
                    bluetoothAdapter.cancelDiscovery()
                }
                
                connectionManager?.connect(device)
                result.success(true)
            }
            "disconnect" -> {
                connectionManager?.disconnect()
                result.success(true)
            }
            "write" -> {
                val bytes = call.argument<ByteArray>("bytes") ?: return result.error("INVALID_ARG", "Bytes required", null)
                val success = connectionManager?.write(bytes) ?: false
                result.success(success)
            }
            "isConnected" -> {
                result.success(connectionManager?.isConnected() ?: false)
            }
            "getConnectionState" -> {
                result.success(connectionManager?.isConnected() ?: false)
            }
            else -> result.notImplemented()
        }
    }

    private fun isPrinter(device: BluetoothDevice): Boolean {
        val bClass = device.bluetoothClass
        if (bClass != null) {
            if (bClass.majorDeviceClass == BluetoothClass.Device.Major.IMAGING) {
                return true
            }
        }
        
        val lowerName = device.name?.lowercase() ?: return false
        val printerKeywords = listOf("print", "thermal", "pos", "receipt", "mtp", "pt-", "hoin", "everycom", "rpp", "mpt")
        for (kw in printerKeywords) {
            if (lowerName.contains(kw)) return true
        }
        return false
    }

    private fun broadcastDiscoveredDevices() {
        val jsonArray = JSONArray()
        for (device in discoveredDevices) {
            val obj = JSONObject().apply {
                put("name", device.name ?: "Unknown Printer")
                put("address", device.address)
                put("isPaired", device.bondState == BluetoothDevice.BOND_BONDED)
            }
            jsonArray.put(obj)
        }
        val event = JSONObject().apply {
            put("event", "discovered_devices")
            put("devices", jsonArray)
        }
        sendEvent(event.toString())
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    fun onDestroy() {
        isDetached = true
        mainHandler.removeCallbacksAndMessages(null)
        this.eventSink = null
        try {
            context.unregisterReceiver(receiver)
        } catch (_: Exception) {}
        connectionManager?.disconnect()
    }
}
