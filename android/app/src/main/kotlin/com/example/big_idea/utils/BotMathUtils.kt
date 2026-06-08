package com.example.big_idea.utils

import kotlin.random.Random
import kotlin.math.max

object BotMathUtils {

    fun getRandomTime(minMs: Int, maxMs: Int): Long {
        if (minMs >= maxMs) return minMs.toLong()
        return Random.nextLong(minMs.toLong(), maxMs.toLong() + 1L)
    }

    fun applyJitter(originalCoordinate: Float, jitterRadius: Double): Float {
        if (jitterRadius <= 0.0) return max(0f, originalCoordinate)
        
        val offset = Random.nextDouble(-jitterRadius, jitterRadius)
        val newCoordinate = originalCoordinate + offset.toFloat()
        
        return max(0f, newCoordinate)
    }
}
