package com.example.pos_app

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.posprinter.IConnectListener
import net.posprinter.IDeviceConnection
import net.posprinter.POSConnect

/**
 * Carries bytes to the printer through Xprinter's own SDK.
 * Dart builds the print data (TSC or ESC/POS); this only connects, sends and
 * reports what the SDK says happened, so the app can log it.
 */
class XprinterBridge(context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val appContext = context.applicationContext
    private val main = Handler(Looper.getMainLooper())

    private var connection: IDeviceConnection? = null
    private var currentTarget: String? = null
    private var events: EventChannel.EventSink? = null

    private var pendingConnect: MethodChannel.Result? = null
    private var connectTimeout: Runnable? = null

    private val listener = IConnectListener { code, info, msg ->
        emit(codeName(code), info, msg)
        when (code) {
            POSConnect.CONNECT_SUCCESS -> finishConnect(true)
            POSConnect.CONNECT_FAIL -> finishConnect(false)
        }
    }

    init {
        POSConnect.init(appContext)
        POSConnect.openLog(true)
        MethodChannel(messenger, "pos_app/xprinter").setMethodCallHandler(this)
        EventChannel(messenger, "pos_app/xprinter/events").setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> connect(call, result)
            "send" -> send(call, result)
            "isConnected" -> result.success(connection?.isConnect == true)
            "disconnect" -> {
                connection?.close()
                connection = null
                currentTarget = null
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        val type = call.argument<String>("type")
        val target: String? = when (type) {
            "bluetooth" -> call.argument<String>("address")
            "usb" -> findUsbPath(call.argument<String>("vendorId"), call.argument<String>("productId"))
            else -> null
        }
        if (target == null) {
            result.error("no_target", "No $type printer found to connect to.", null)
            return
        }

        // Already connected to this printer: reuse the link.
        if (connection?.isConnect == true && currentTarget == target) {
            emit("reuse", target, "already connected")
            result.success(true)
            return
        }

        connection?.close()
        pendingConnect?.let { finishConnect(false) }
        pendingConnect = result
        currentTarget = target
        connection = POSConnect.createDevice(
            if (type == "bluetooth") POSConnect.DEVICE_TYPE_BLUETOOTH else POSConnect.DEVICE_TYPE_USB
        )
        emit("connecting", target, type)
        connection!!.connect(target, listener)

        connectTimeout = Runnable {
            emit("connect_timeout", target, "no answer in 15s")
            finishConnect(false)
        }
        main.postDelayed(connectTimeout!!, 15000)
    }

    private fun send(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val chunkSize = call.argument<Int>("chunkSize") ?: 1024
        val conn = connection
        if (bytes == null || conn == null || !conn.isConnect) {
            emit("send_refused", currentTarget, "not connected")
            result.success(mapOf("queued" to false, "connected" to false))
            return
        }
        val chunks = bytes.toList().chunked(chunkSize).map { it.toByteArray() }
        emit("sending", currentTarget, "${bytes.size} bytes in ${chunks.size} chunks")
        conn.sendData(chunks)
        // sendData is asynchronous; failures arrive as events, so give it a
        // moment and report whether the link is still up.
        main.postDelayed({
            result.success(mapOf("queued" to true, "connected" to (connection?.isConnect == true)))
        }, 600)
    }

    private fun finishConnect(ok: Boolean) {
        main.post {
            connectTimeout?.let { main.removeCallbacks(it) }
            connectTimeout = null
            pendingConnect?.success(ok)
            pendingConnect = null
        }
    }

    /** The SDK connects USB printers by device path, which changes on replug. */
    private fun findUsbPath(vendorId: String?, productId: String?): String? {
        val devices = POSConnect.getUsbDevice(appContext)
        val match = devices.firstOrNull {
            it.vendorId.toString() == vendorId && it.productId.toString() == productId
        } ?: devices.firstOrNull()
        return match?.deviceName
    }

    private fun emit(name: String, info: String?, msg: String?) {
        val event = mapOf(
            "time" to System.currentTimeMillis(),
            "event" to name,
            "info" to info,
            "message" to msg,
        )
        main.post { events?.success(event) }
    }

    private fun codeName(code: Int): String = when (code) {
        POSConnect.CONNECT_SUCCESS -> "connect_success"
        POSConnect.CONNECT_FAIL -> "connect_fail"
        POSConnect.CONNECT_INTERRUPT -> "connect_interrupt"
        POSConnect.SEND_FAIL -> "send_fail"
        POSConnect.BLUETOOTH_INTERRUPT -> "bluetooth_interrupt"
        POSConnect.USB_ATTACHED -> "usb_attached"
        POSConnect.USB_DETACHED -> "usb_detached"
        else -> "code_$code"
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }
}
