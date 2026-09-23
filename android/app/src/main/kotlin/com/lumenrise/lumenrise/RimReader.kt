package com.lumenrise.lumenrise

import android.app.Activity
import androidx.core.view.ViewCompat

// Hardware cutout for the sheet. The page gets a zeroed MediaQuery, so this
// map is the only inset Dart still has to paint as a black band.
class RimReader(private val activity: Activity) {

    fun edges(): Map<String, Int> {
        val cutout = ViewCompat
            .getRootWindowInsets(activity.window.decorView)
            ?.displayCutout
        return mapOf(
            "west" to (cutout?.safeInsetLeft ?: 0),
            "north" to (cutout?.safeInsetTop ?: 0),
            "east" to (cutout?.safeInsetRight ?: 0),
            "south" to (cutout?.safeInsetBottom ?: 0),
        )
    }
}
