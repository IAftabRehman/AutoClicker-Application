package com.example.big_idea.models

data class BotActionStep(
    val id: String,
    val actionType: String,
    val startX: Double,
    val startY: Double,
    val endX: Double?,
    val endY: Double?,
    val minDelayMs: Int,
    val maxDelayMs: Int,
    val minHoldTimeMs: Int,
    val maxHoldTimeMs: Int,
    val jitterRadius: Double,
    val isCurvedSwipe: Boolean,
    val waitForText: String?,
    val stepTimeoutMs: Int
)
