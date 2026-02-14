package com.billma007.infalsustouch

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Bundle
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import androidx.appcompat.app.AppCompatActivity

class FullMappingActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Hide system UI for immersion
        window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN)

        setContentView(GameControllerView(this))
    }
}

class GameControllerView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    // Key definition
    data class Key(val char: Char, val rect: RectF, var isPressed: Boolean = false, var activePointerId: Int = -1)

    private val leftKeyChars = listOf('s', 'd', 'f')
    private val rightKeyChars = listOf('j', 'k', 'l')
    private val keys = mutableListOf<Key>()
    private val padRect = RectF()

    // Paints
    private val keyPaint = Paint().apply { color = Color.parseColor("#4DFFFFFF"); style = Paint.Style.STROKE; strokeWidth = 5f }
    private val keyFillPaint = Paint().apply { color = Color.parseColor("#99FFFFFF"); style = Paint.Style.FILL }
    private val textPaint = Paint().apply { color = Color.WHITE; textSize = 60f; textAlign = Paint.Align.CENTER }
    private val padPaint = Paint().apply { color = Color.parseColor("#262196F3"); style = Paint.Style.FILL }
    private val padBorderPaint = Paint().apply { color = Color.parseColor("#802196F3"); style = Paint.Style.STROKE; strokeWidth = 5f }
    private val padTextPaint = Paint().apply { color = Color.parseColor("#B32196F3"); textSize = 40f; textAlign = Paint.Align.CENTER }

    // Touch logic state
    // Map pointerId -> Last X Position
    private val previousTouchX = mutableMapOf<Int, Float>()
    
    // Sensitivity
    private val SENSITIVITY = 2.0f
    
    // Palm Rejection Threshold (Pixels)
    // iOS 60pts. 1 pt ~= 1/163 inch. 60/163 ~= 0.37 inch ~= 9.3mm.
    // On Android: 160dp = 1 inch. 60pts iOS ~= 60dp Android roughly?
    // Let's use a safe pixel value. typical finger ~15mm (~95px at 160dpi). Palm is much larger.
    // Let's set a conservative threshold.
    // toolMajor returns touches in pixels.
    // If we assume standard correlation, > 150px might be palm on high density?
    // It's safer to use touchMajor/Minor if available, but toolMajor works.
    // We'll set a high pixel threshold for now, readable from resources maybe?
    // Let's hardcode a reasonable value for a tablet: 200px seems like a small palm.
    private val PALM_THRESHOLD_PX = 200f 

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        setupLayout(w.toFloat(), h.toFloat())
    }

    private fun setupLayout(w: Float, h: Float) {
        keys.clear()
        
        // 1. Trigger Keys Layout
        // Side Margin: 10%
        // Height: 25% (was 20% then increased)
        // Top Margin: 40% (moved down)
        // Group Width: Previously approx 32.5% of total width (kept constant)
        
        val sideMargin = w * 0.10f
        val keyHeight = h * 0.25f
        val keyTop = h * 0.40f
        val groupWidth = w * 0.325f
        val keyWidth = groupWidth / 3.0f

        // Left Group (S D F)
        // Starts at sideMargin
        for (i in leftKeyChars.indices) {
            val left = sideMargin + (i * keyWidth)
            val rect = RectF(left, keyTop, left + keyWidth, keyTop + keyHeight)
            keys.add(Key(leftKeyChars[i], rect))
        }

        // Right Group (J K L)
        // Starts at w - sideMargin - groupWidth
        val rightGroupStart = w - sideMargin - groupWidth
        for (i in rightKeyChars.indices) {
            val left = rightGroupStart + (i * keyWidth)
            val rect = RectF(left, keyTop, left + keyWidth, keyTop + keyHeight)
            keys.add(Key(rightKeyChars[i], rect))
        }

        // 2. TouchPad Layout (Relative)
        // Bottom aligned
        // Height: 15%
        // Width: 85%
        // Bottom Margin: 5%
        val padW = w * 0.85f
        val padH = h * 0.15f
        val padBottomMargin = h * 0.05f
        
        val padLeft = (w - padW) / 2.0f
        val padTop = h - padBottomMargin - padH
        padRect.set(padLeft, padTop, padLeft + padW, padTop + padH)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawColor(Color.BLACK)

        // Draw Keys
        for (key in keys) {
            if (key.isPressed) {
                canvas.drawRect(key.rect, keyFillPaint)
            }
            canvas.drawRect(key.rect, keyPaint)
            // Center text
            val fontMetrics = textPaint.fontMetrics
            val baseline = key.rect.centerY() - (fontMetrics.bottom + fontMetrics.top) / 2
            canvas.drawText(key.char.uppercase(), key.rect.centerX(), baseline, textPaint)
        }

        // Draw Pad
        canvas.drawRect(padRect, padPaint)
        canvas.drawRect(padRect, padBorderPaint)
        canvas.drawText("光标 (相对)", padRect.centerX(), padRect.centerY(), padTextPaint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val action = event.actionMasked
        val pointerIndex = event.actionIndex
        val pointerId = event.getPointerId(pointerIndex)

        // Get touch properties
        // Note: For ACTION_MOVE, there is no single index, we must loop all
        
        when (action) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                val x = event.getX(pointerIndex)
                val y = event.getY(pointerIndex)
                val size = event.getToolMajor(pointerIndex) // In pixels
                
                // Always track history
                previousTouchX[pointerId] = x

                if (size > PALM_THRESHOLD_PX) {
                    // Ignore palm for actions
                    return true
                }

                // Check Keys
                for (key in keys) {
                    if (key.rect.contains(x, y) && key.activePointerId == -1) {
                        key.activePointerId = pointerId
                        key.isPressed = true
                        NetworkManager.sendKeyDown(key.char)
                        invalidate()
                        return true
                    }
                }
                
                // We don't need to "check" pad for DOWN event in relative mode,
                // we just start tracking (which we did above).
                // Relative logic happens in MOVE.
            }
            
            MotionEvent.ACTION_MOVE -> {
                // Loop through all active pointers
                for (i in 0 until event.pointerCount) {
                    val pid = event.getPointerId(i)
                    val x = event.getX(i)
                    // val y = event.getY(i)
                    val size = event.getToolMajor(i)
                    
                    val prevX = previousTouchX[pid]
                    
                    // Crucial Logic: Always update previous position to prevent jumps
                    previousTouchX[pid] = x 
                    
                    // If Palm, skip processing but history is updated
                    if (size > PALM_THRESHOLD_PX) continue
                    
                    // 1. Check if this pointer owns a Key
                    // (Keys don't support dragging out currently to keep it simple, or do they?)
                    // iOS logic: if touch started in key, it stays in key until released.
                    // We don't process MOVE for keys unless we want to support sliding OFF the key?
                    // Let's stick to simple tap logic for now. Use UP to release.
                    
                    // 2. Check if this pointer is valid for Pad (and NOT holding a key)
                    var isKeyOwner = false
                    for (key in keys) {
                        if (key.activePointerId == pid) {
                            isKeyOwner = true
                            break
                        }
                    }
                    
                    if (!isKeyOwner) {
                        // It's a free finger. Check if it started or is currently in pad?
                        // iOS logic: entire screen (except keys/palm) worked?
                        // No, the prompt says "TouchPad Area".
                        // Wait, iOS `MultiTouchPad` was in a ZStack in specific frame.
                        // So only touches INSIDE that frame fired events.
                        // Here, we check if current point is inside PadRect?
                        // Or if it started inside?
                        // Let's check contains(x,y).
                        
                        // Strict check: current point must be in pad area to send delta.
                        if (padRect.contains(x, event.getY(i))) {
                            if (prevX != null) {
                                val dx = x - prevX
                                if (Math.abs(dx) > 0.1) {
                                    NetworkManager.sendDelta(dx * SENSITIVITY)
                                }
                            }
                        }
                    }
                }
            }
            
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP, MotionEvent.ACTION_CANCEL -> {
                previousTouchX.remove(pointerId)
                
                // Release Keys if owned by this pointer
                for (key in keys) {
                    if (key.activePointerId == pointerId) {
                        key.activePointerId = -1
                        key.isPressed = false
                        NetworkManager.sendKeyUp(key.char)
                        invalidate()
                    }
                }
            }
        }
        return true
    }
}
