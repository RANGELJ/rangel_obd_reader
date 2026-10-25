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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "obd/bt").setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> request_permission(result)
                "getBondedDevices" -> get_bonded_devices(result)
                else -> result.notImplemented()
            }
        }
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
