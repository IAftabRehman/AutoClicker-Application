package com.example.big_idea.models

data class GlobalConfig(
    val idleBreakAfterXSteps: Int,
    val idleBreakDurationMs: Int,
    val maxSequenceTimeoutMs: Int
)
