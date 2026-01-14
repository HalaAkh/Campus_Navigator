package com.example.campus_navigator

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.app.Activity
import com.moko.support.nordic.MokoBleScanner
import com.moko.support.nordic.MokoSupport
import com.moko.support.nordic.callback.MokoScanDeviceCallback
import com.moko.support.nordic.entity.DeviceInfo
import com.moko.ble.lib.MokoConstants
import com.moko.ble.lib.event.ConnectStatusEvent
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.os.Build

class BeaconPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var mokoBleScanner: MokoBleScanner? = null
    private val PERMISSION_REQUEST_CODE = 1001

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "beacon_channel")
        channel.setMethodCallHandler(this)

        // Initialize MokoSupport
        MokoSupport.getInstance().init(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isBluetoothEnabled" -> {
                val isEnabled = isBluetoothEnabled()
                result.success(isEnabled)
            }
            "enableBluetooth" -> {
                enableBluetooth(result)
            }
            "startScan" -> {
                startScanning(result)
            }
            "stopScan" -> {
                stopScanning(result)
            }
            "connectBeacon" -> {
                val mac = call.argument<String>("mac")
                if (mac != null) {
                    connectToBeacon(mac, result)
                } else {
                    result.error("INVALID_ARGUMENT", "MAC address is required", null)
                }
            }
            "disconnectBeacon" -> {
                disconnectBeacon(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isBluetoothEnabled(): Boolean {
        return try {
            activity?.let { act ->
                val bluetoothManager = act.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
                val bluetoothAdapter = bluetoothManager.adapter
                bluetoothAdapter?.isEnabled ?: false
            } ?: false
        } catch (e: Exception) {
            false
        }
    }

    private fun enableBluetooth(result: Result) {
        activity?.let { act ->
            try {
                val bluetoothManager = act.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
                val bluetoothAdapter = bluetoothManager.adapter

                if (bluetoothAdapter != null && !bluetoothAdapter.isEnabled) {
                    val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                    act.startActivity(enableBtIntent)
                    result.success(true)
                } else if (bluetoothAdapter == null) {
                    result.error("NO_BLUETOOTH", "Device does not support Bluetooth", null)
                } else {
                    // Already enabled
                    result.success(true)
                }
            } catch (e: Exception) {
                result.error("BLUETOOTH_ERROR", "Failed to enable Bluetooth: ${e.message}", null)
            }
        } ?: result.error("NO_ACTIVITY", "Activity not available", null)
    }

    private fun startScanning(result: Result) {
        activity?.let { act ->
            // Check if Bluetooth is enabled first
            if (!isBluetoothEnabled()) {
                result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
                return
            }

            // Check permissions
            if (ContextCompat.checkSelfPermission(act, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(act,
                    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                    PERMISSION_REQUEST_CODE)
                result.error("PERMISSION_DENIED", "Location permission required", null)
                return
            }

            mokoBleScanner = MokoBleScanner(act)
            mokoBleScanner?.startScanDevice(object : MokoScanDeviceCallback {
                override fun onStartScan() {
                    activity?.runOnUiThread {
                        channel.invokeMethod("onScanStarted", null)
                    }
                }

                override fun onScanDevice(device: DeviceInfo) {
                    activity?.runOnUiThread {
                        val deviceMap = hashMapOf(
                            "name" to (device.name ?: "Unknown"),
                            "mac" to device.mac,
                            "rssi" to device.rssi
                        )
                        channel.invokeMethod("onDeviceFound", deviceMap)
                    }
                }

                override fun onStopScan() {
                    activity?.runOnUiThread {
                        channel.invokeMethod("onScanStopped", null)
                    }
                }
            })
            result.success("Scanning started")
        } ?: result.error("NO_ACTIVITY", "Activity not available", null)
    }

    private fun stopScanning(result: Result) {
        mokoBleScanner?.stopScanDevice()
        result.success("Scanning stopped")
    }

    private fun connectToBeacon(mac: String, result: Result) {
        // Check if Bluetooth is enabled
        if (!isBluetoothEnabled()) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
            return
        }

        // Register EventBus
        if (!EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().register(this)
        }

        MokoSupport.getInstance().connDevice(mac)
        result.success("Connecting to $mac")
    }

    private fun disconnectBeacon(result: Result) {
        MokoSupport.getInstance().disConnectBle()

        // Unregister EventBus
        if (EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().unregister(this)
        }

        result.success("Disconnected")
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    fun onConnectStatusEvent(event: ConnectStatusEvent) {
        when (event.action) {
            MokoConstants.ACTION_DISCONNECTED -> {
                channel.invokeMethod("onConnectionStatus", hashMapOf(
                    "status" to "disconnected",
                    "message" to "Connection failed or disconnected"
                ))
            }
            MokoConstants.ACTION_DISCOVER_SUCCESS -> {
                channel.invokeMethod("onConnectionStatus", hashMapOf(
                    "status" to "connected",
                    "message" to "Successfully connected to beacon"
                ))
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        if (EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().unregister(this)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}