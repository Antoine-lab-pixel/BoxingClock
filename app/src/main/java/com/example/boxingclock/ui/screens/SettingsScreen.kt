package com.example.boxingclock.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.boxingclock.model.TimerSettings

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    settings: TimerSettings,
    onSettingClick: (String) -> Unit,
    onSettingsChange: (TimerSettings) -> Unit,
    onBackClick: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Réglages", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Retour")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            SettingRow(
                label = "Préparation",
                value = formatDuration(settings.preparationTime),
                onClick = { onSettingClick("preparation") }
            )
            Divider()
            SettingRow(
                label = "Travail",
                value = formatDuration(settings.workTime),
                onClick = { onSettingClick("work") }
            )
            Divider()
            SettingRow(
                label = "Repos",
                value = formatDuration(settings.restTime),
                onClick = { onSettingClick("rest") }
            )
            Divider()
            SettingRow(
                label = "Rounds",
                value = if (settings.rounds == 0) "∞" else "${settings.rounds}",
                onClick = { onSettingClick("rounds") }
            )
            Divider()

            // Clapper toggle — immediate, no dedicated edit screen needed
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 20.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text("Clapper", fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    Text(
                        text = "Son 10s avant la fin du travail",
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Switch(
                    checked = settings.clapperEnabled,
                    onCheckedChange = { onSettingsChange(settings.copy(clapperEnabled = it)) }
                )
            }
        }
    }
}

@Composable
private fun SettingRow(label: String, value: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 20.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, fontSize = 20.sp, fontWeight = FontWeight.Bold)
        Text(value, fontSize = 20.sp, color = MaterialTheme.colorScheme.primary)
    }
}

private fun formatDuration(seconds: Int): String =
    if (seconds >= 60) String.format("%d:%02d", seconds / 60, seconds % 60)
    else "${seconds}s"
