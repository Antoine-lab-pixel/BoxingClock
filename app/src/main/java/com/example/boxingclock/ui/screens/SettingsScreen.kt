package com.example.boxingclock.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.boxingclock.model.TimerSettings
import com.example.boxingclock.ui.components.RoundsPicker
import com.example.boxingclock.ui.components.TimePicker

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    settings: TimerSettings,
    onSettingsChange: (TimerSettings) -> Unit,
    onBackClick: () -> Unit
) {
    var preparationMinutes by remember { mutableIntStateOf(settings.preparationTime / 60) }
    var preparationSeconds by remember { mutableIntStateOf(settings.preparationTime % 60) }
    var workMinutes by remember { mutableIntStateOf(settings.workTime / 60) }
    var workSeconds by remember { mutableIntStateOf(settings.workTime % 60) }
    var restMinutes by remember { mutableIntStateOf(settings.restTime / 60) }
    var restSeconds by remember { mutableIntStateOf(settings.restTime % 60) }
    var rounds by remember { mutableIntStateOf(settings.rounds) }
    var clapperEnabled by remember { mutableStateOf(settings.clapperEnabled) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Réglages", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = {
                        val newSettings = TimerSettings(
                            preparationTime = preparationMinutes * 60 + preparationSeconds,
                            workTime = workMinutes * 60 + workSeconds,
                            restTime = restMinutes * 60 + restSeconds,
                            rounds = rounds,
                            clapperEnabled = clapperEnabled
                        )
                        onSettingsChange(newSettings)
                        onBackClick()
                    }) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Preparation Time
            Text("Temps de Préparation", fontSize = 20.sp, fontWeight = FontWeight.Bold)
            TimePicker(
                minutes = preparationMinutes,
                seconds = preparationSeconds,
                onMinutesChange = { preparationMinutes = it },
                onSecondsChange = { preparationSeconds = it }
            )

            Divider()

            // Work Time
            Text("Temps de Travail", fontSize = 20.sp, fontWeight = FontWeight.Bold)
            TimePicker(
                minutes = workMinutes,
                seconds = workSeconds,
                onMinutesChange = { workMinutes = it },
                onSecondsChange = { workSeconds = it }
            )

            Divider()

            // Rest Time
            Text("Temps de Repos", fontSize = 20.sp, fontWeight = FontWeight.Bold)
            TimePicker(
                minutes = restMinutes,
                seconds = restSeconds,
                onMinutesChange = { restMinutes = it },
                onSecondsChange = { restSeconds = it }
            )

            Divider()

            // Rounds
            Text("Nombre de Rounds", fontSize = 20.sp, fontWeight = FontWeight.Bold)
            RoundsPicker(
                rounds = rounds,
                onRoundsChange = { rounds = it }
            )

            Divider()

            // Clapper
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text("Clapper", fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    Text("Son 10s avant la fin du travail", fontSize = 14.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Switch(
                    checked = clapperEnabled,
                    onCheckedChange = { clapperEnabled = it }
                )
            }
        }
    }
}