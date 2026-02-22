package com.example.boxingclock

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.boxingclock.ui.screens.MainScreen
import com.example.boxingclock.ui.screens.SettingEditScreen
import com.example.boxingclock.ui.screens.SettingsScreen

@Composable
fun BoxingClockApp(viewModel: TimerViewModel) {
    val navController = rememberNavController()
    val timerState by viewModel.timerState.collectAsState()
    val settings by viewModel.settings.collectAsState()

    NavHost(navController = navController, startDestination = "main") {
        composable("main") {
            MainScreen(
                timerState = timerState,
                totalRounds = settings.rounds,
                workTime = settings.workTime,
                restTime = settings.restTime,
                onStartClick = { viewModel.startTimer() },
                onPauseClick = { viewModel.pauseTimer() },
                onResetClick = { viewModel.resetTimer() },
                onSettingsClick = { navController.navigate("settings") }
            )
        }
        composable("settings") {
            SettingsScreen(
                settings = settings,
                onSettingClick = { key -> navController.navigate("settings/edit/$key") },
                onSettingsChange = { newSettings -> viewModel.updateSettings(newSettings) },
                onBackClick = { navController.popBackStack() }
            )
        }
        composable("settings/edit/{setting}") { backStackEntry ->
            val settingKey = backStackEntry.arguments?.getString("setting") ?: return@composable
            SettingEditScreen(
                settingKey = settingKey,
                settings = settings,
                onSettingsChange = { newSettings -> viewModel.updateSettings(newSettings) },
                onBackClick = { navController.popBackStack() }
            )
        }
    }
}
