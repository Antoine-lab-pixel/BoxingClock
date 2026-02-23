package com.example.boxingclock

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.ViewModelProvider
import com.example.boxingclock.ui.theme.BoxingClockTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Create ViewModel using ViewModelProvider
        val viewModel = ViewModelProvider(
            this,
            TimerViewModelFactory(application)
        )[TimerViewModel::class.java]

        setContent {
            BoxingClockTheme {
                BoxingClockApp(viewModel)
            }
        }
    }
}