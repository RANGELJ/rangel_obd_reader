package com.example.rangel_obd_reader

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val serial_port_profile = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val main_thread = Handler(Looper.getMainLooper())
    private var bluetooth_socket: BluetoothSocket? = null
    private var output_stream: OutputStream? = null
    private var event_sink: EventChannel.EventSink? = null
    private var pending_permission_result: MethodChannel.Result? = null
    private val bluetooth_permission_request_code = 1827

    override fun onDestroy() {
      close_connection()
      super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "obd/bt").setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> request_permission(result)
                "getBondedDevices" -> get_bonded_devices(result)
                "connectDevice" -> connect_device(call.argument<String>("address")!!, result)
                "sendCommand" -> send_command(call.argument<String>("command")!!, result)
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "obd/bt/data").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink,
                ) {
                    event_sink = events
                }

                override fun onCancel(arguments: Any?) {
                    event_sink = null
                }
            }
        )
    }

    private fun send_command(command: String, result: MethodChannel.Result) {
        when (command) {
            "ATI" -> Unit
            else -> {
                result.error("command_blocked", "Only ATI is allowed for now", null)
                return
            }
        }

        val socket = bluetooth_socket
        if (socket == null) {
            result.error("not_connected", "Connect to the adapter first", null)
            return
        }

        thread {
            try {
                val bytes = (command + "\r").toByteArray(Charsets.US_ASCII)
                socket.outputStream.write(bytes)
                socket.outputStream.flush()
                main_thread.post { result.success(null) }
            } catch (exception: java.io.IOException) {
                main_thread.post {
                    result.error("send_failed", exception.message, null)
                }
            }
        }
    }

    @Suppress("MissingPermission")
    private fun connect_device(address: String, result: MethodChannel.Result) {
        thread {
            try {
                close_connection()
                val adapter = bluetooth_adapter()!!
                val socket = adapter.getRemoteDevice(address)
                    .createRfcommSocketToServiceRecord(serial_port_profile)
                socket.connect()
                bluetooth_socket = socket
                output_stream = socket.outputStream
                main_thread.post { result.success(null) }
                start_reading(socket)
            } catch (e: Exception) {
                close_connection()
                main_thread.post { result.error("connect_failed", e.message, null) }
            }
        }
    }

    private fun start_reading(socket: BluetoothSocket) {
        thread {
            try {
                val input = socket.inputStream
                val buffer = ByteArray(1024)

                while (true) {
                    val byte_count = input.read(buffer)
                    if (byte_count == -1) break

                    val chunk = String(buffer, 0, byte_count, Charsets.US_ASCII)
                    main_thread.post {
                        if (bluetooth_socket === socket) {
                            event_sink?.success(chunk)
                        }
                    }
                }

                main_thread.post {
                    if (bluetooth_socket === socket) {
                        event_sink?.endOfStream()
                        close_connection()
                    }
                }
            } catch (exception: java.io.IOException) {
                main_thread.post {
                    if (bluetooth_socket === socket) {
                        event_sink?.error("read_failed", exception.message, null)
                        close_connection()
                    }
                }
            }
        }
    }

    private fun close_connection() {
        try { bluetooth_socket?.close() } catch (_: Exception) {}
        bluetooth_socket = null
        output_stream = null
    }

    private fun has_permission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED

    private fun request_permission(result: MethodChannel.Result) {
        if (has_permission()) {
            result.success(true)
            return
        }
        if (pending_permission_result != null) {
            result.error("busy", "a permission request is already in progress", null)
            return
        }
        pending_permission_result = result
        requestPermissions(arrayOf(Manifest.permission.BLUETOOTH_CONNECT), bluetooth_permission_request_code)
    }

    private fun bluetooth_adapter(): BluetoothAdapter? =
        (getSystemService(BLUETOOTH_SERVICE) as BluetoothManager).adapter

    private fun get_bonded_devices(result: MethodChannel.Result) {
        if (!has_permission()) {
            result.error("permission_denied", "Bluetooth permission not granted", null)
            return
        }
        val adapter = bluetooth_adapter()
        if (adapter == null) {
            result.error("no_bluetooth", "Bluetooth adapter not available", null)
            return
        }
        if (!adapter.isEnabled) {
            result.error("bluetooth_disabled", "Bluetooth adapter is not enabled", null)
            return
        }
        val devices = adapter.bondedDevices.map { device ->
            mapOf(
                "name" to device.name,
                "address" to device.address
            )
        }
        result.success(devices)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != bluetooth_permission_request_code) return

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED

        pending_permission_result?.success(granted)
        pending_permission_result = null
    }
}
