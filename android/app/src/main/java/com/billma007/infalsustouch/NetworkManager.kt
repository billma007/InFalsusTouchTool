package com.billma007.infalsustouch

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.charset.StandardCharsets

object NetworkManager {
    private var socket: DatagramSocket? = null
    private var targetAddress: InetAddress? = null
    private val PORT = 8888
    var isConnected = false
    var errorMsg = ""

    fun connect(ip: String): Boolean {
        return try {
            targetAddress = InetAddress.getByName(ip)
            if (socket == null || socket!!.isClosed) {
                socket = DatagramSocket()
            }
            isConnected = true
            errorMsg = ""
            true
        } catch (e: Exception) {
            e.printStackTrace()
            errorMsg = "Connection failed: ${e.message}"
            isConnected = false
            false
        }
    }

    fun disconnect() {
        socket?.close()
        socket = null
        isConnected = false
    }

    private fun send(message: String) {
        if (!isConnected || socket == null || targetAddress == null) return
        Thread {
            try {
                val data = message.toByteArray(StandardCharsets.UTF_8)
                val packet = DatagramPacket(data, data.size, targetAddress!!, PORT)
                socket?.send(packet)
                android.util.Log.d("UDP", "Sent to ${targetAddress?.hostAddress}:$PORT -> $message")
            } catch (e: Exception) {
                e.printStackTrace()
                android.util.Log.e("UDP", "Send failed: ${e.message}")
            }
        }.start()
    }

    fun sendKeyDown(char: Char) {
        send("KD$char")
    }

    fun sendKeyUp(char: Char) {
        send("KU$char")
    }

    fun sendDelta(dx: Float) {
        send("$dx")
    }
    
    // Absolute mode not used in this prompt but kept for completeness
    fun sendAbsoluteX(ratio: Float) {
        send("A$ratio")
    }
}
