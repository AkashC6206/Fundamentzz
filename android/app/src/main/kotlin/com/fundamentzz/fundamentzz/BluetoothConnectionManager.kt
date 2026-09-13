package com.fundamentzz.fundamentzz

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.util.Log
import kotlinx.coroutines.*
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID

enum class PrinterConnectionState(val stateName: String) {
    DISCONNECTED("disconnected"),
    PAIRING("pairing"),
    CONNECTING("connecting"),
    CONNECTED("connected"),
    RECONNECTING("reconnecting"),
    WAITING("waiting"),
    ERROR("error")
}

@SuppressLint("MissingPermission")
class BluetoothConnectionManager(
    private val context: Context,
    private val stateCallback: (PrinterConnectionState) -> Unit
) {
    // Standard Serial Port Profile (SPP) UUID used by ESC/POS thermal printers
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val TAG = "BTConnectionManager"
    
    private var bluetoothSocket: BluetoothSocket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null

    private var currentDevice: BluetoothDevice? = null
    private var currentState: PrinterConnectionState = PrinterConnectionState.DISCONNECTED
    
    private var connectionJob: Job? = null
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private var retryCount = 0
    @Volatile
    private var isIntentionalDisconnect = false

    fun setState(state: PrinterConnectionState) {
        if (currentState != state) {
            currentState = state
            Log.d(TAG, "State transition -> ${state.stateName}")
            stateCallback(state)
        }
    }

    fun getCurrentDevice(): BluetoothDevice? = currentDevice

    @Synchronized
    fun connect(device: BluetoothDevice) {
        isIntentionalDisconnect = false
        currentDevice = device
        retryCount = 0
        startConnectionLoop()
    }

    private fun startConnectionLoop() {
        connectionJob?.cancel()
        connectionJob = coroutineScope.launch {
            while (isActive && !isIntentionalDisconnect && currentDevice != null) {
                val device = currentDevice ?: break

                try {
                    if (retryCount == 0) {
                        setState(PrinterConnectionState.CONNECTING)
                    } else if (retryCount <= 4) {
                        setState(PrinterConnectionState.RECONNECTING)
                    } else {
                        setState(PrinterConnectionState.WAITING)
                    }

                    // Stop discovery before connecting (critical for RFCOMM stability)
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter?.isDiscovering == true) {
                        adapter.cancelDiscovery()
                        delay(150)
                    }

                    closeSocket()

                    Log.d(TAG, "Attempting connection to ${device.name ?: "Device"} (${device.address}) [attempt: $retryCount]")
                    val socket = connectWithFallback(device)
                    bluetoothSocket = socket
                    inputStream = socket.inputStream
                    outputStream = socket.outputStream

                    retryCount = 0
                    setState(PrinterConnectionState.CONNECTED)
                    Log.i(TAG, "Successfully connected to ${device.name ?: "Printer"}")

                    // Monitor connection health until remote disconnects or socket breaks
                    monitorConnection()

                    if (isIntentionalDisconnect) break

                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, "Connection attempt failed: ${e.message}")
                    closeSocket()
                }

                if (isIntentionalDisconnect) break

                retryCount++
                val delayMs = when (retryCount) {
                    1 -> 1000L
                    2 -> 2000L
                    3 -> 5000L
                    4 -> 10000L
                    else -> 15000L
                }

                if (retryCount <= 4) {
                    setState(PrinterConnectionState.RECONNECTING)
                } else {
                    setState(PrinterConnectionState.WAITING)
                }

                Log.d(TAG, "Waiting ${delayMs}ms before next reconnection attempt (#$retryCount)...")
                delay(delayMs)
            }
        }
    }

    /**
     * Attempts connection across 4 fallback strategies for ESC/POS thermal printers.
     */
    private fun connectWithFallback(device: BluetoothDevice): BluetoothSocket {
        val errors = mutableListOf<String>()

        // 1. Standard SPP UUID
        try {
            val s = device.createRfcommSocketToServiceRecord(SPP_UUID)
            s.connect()
            Log.d(TAG, "Connected via standard RFCOMM SPP socket")
            return s
        } catch (e: Exception) {
            errors.add("Standard SPP: ${e.message}")
            Log.w(TAG, "Standard SPP failed (${e.message}), trying insecure SPP...")
        }

        // 2. Insecure SPP UUID
        try {
            val s = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)
            s.connect()
            Log.d(TAG, "Connected via insecure RFCOMM SPP socket")
            return s
        } catch (e: Exception) {
            errors.add("Insecure SPP: ${e.message}")
            Log.w(TAG, "Insecure SPP failed (${e.message}), trying reflection channel 1...")
        }

        // 3. Direct RFCOMM channel 1 reflection (standard)
        try {
            val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
            val s = method.invoke(device, 1) as BluetoothSocket
            s.connect()
            Log.d(TAG, "Connected via channel 1 reflection")
            return s
        } catch (e: Exception) {
            errors.add("Channel 1: ${e.message}")
            Log.w(TAG, "Channel 1 reflection failed (${e.message}), trying insecure reflection...")
        }

        // 4. Direct RFCOMM channel 1 reflection (insecure)
        try {
            val method = device.javaClass.getMethod("createInsecureRfcommSocket", Int::class.javaPrimitiveType)
            val s = method.invoke(device, 1) as BluetoothSocket
            s.connect()
            Log.d(TAG, "Connected via insecure channel 1 reflection")
            return s
        } catch (e: Exception) {
            errors.add("Insecure Channel 1: ${e.message}")
        }

        throw IOException("All socket connection attempts failed: " + errors.joinToString(" | "))
    }

    private suspend fun monitorConnection() {
        val stream = inputStream
        if (stream == null) {
            while (currentCoroutineContext().isActive && isConnected()) {
                delay(3000)
            }
            return
        }

        val buffer = ByteArray(256)
        try {
            while (currentCoroutineContext().isActive && isConnected()) {
                val bytesRead = stream.read(buffer)
                if (bytesRead == -1) {
                    Log.d(TAG, "Stream EOF detected")
                    break
                }
            }
        } catch (e: IOException) {
            Log.d(TAG, "Connection stream terminated: ${e.message}")
        } finally {
            closeSocket()
        }
    }

    fun disconnect() {
        isIntentionalDisconnect = true
        connectionJob?.cancel()
        closeSocket()
        currentDevice = null
        setState(PrinterConnectionState.DISCONNECTED)
    }

    private fun closeSocket() {
        try {
            inputStream?.close()
        } catch (_: Exception) {}
        try {
            outputStream?.close()
        } catch (_: Exception) {}
        try {
            bluetoothSocket?.close()
        } catch (_: Exception) {}
        
        inputStream = null
        outputStream = null
        bluetoothSocket = null
    }

    fun write(bytes: ByteArray): Boolean {
        if (currentState != PrinterConnectionState.CONNECTED || outputStream == null) {
            Log.e(TAG, "Cannot write, printer is not connected")
            return false
        }
        return try {
            outputStream?.write(bytes)
            outputStream?.flush()
            true
        } catch (e: IOException) {
            Log.e(TAG, "Write failed: ${e.message}")
            if (!isIntentionalDisconnect) {
                closeSocket()
                startConnectionLoop()
            }
            false
        }
    }

    fun isConnected(): Boolean {
        return currentState == PrinterConnectionState.CONNECTED && bluetoothSocket?.isConnected == true
    }
}
