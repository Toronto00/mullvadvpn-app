package net.mullvad.mullvadvpn.service.endpoint

import net.mullvad.mullvadvpn.ipc.Event
import net.mullvad.mullvadvpn.model.DnsOptions
import net.mullvad.mullvadvpn.model.RelaySettings
import net.mullvad.mullvadvpn.model.Settings
import net.mullvad.talpid.util.EventNotifier

class SettingsListener(endpoint: ServiceEndpoint) {
    private val daemon = endpoint.intermittentDaemon

    val accountNumberNotifier = EventNotifier<String?>(null)
    val dnsOptionsNotifier = EventNotifier<DnsOptions?>(null)
    val relaySettingsNotifier = EventNotifier<RelaySettings?>(null)
    val settingsNotifier = EventNotifier<Settings?>(null)

    var settings by settingsNotifier.notifiable()
        private set

    init {
        daemon.registerListener(this) { maybeNewDaemon ->
            maybeNewDaemon?.let { newDaemon ->
                newDaemon.onSettingsChange.subscribe(this@SettingsListener) { maybeSettings ->
                    synchronized(this@SettingsListener) {
                        maybeSettings?.let { newSettings -> handleNewSettings(newSettings) }
                    }
                }

                synchronized(this@SettingsListener) {
                    newDaemon.getSettings()?.let { newSettings ->
                        handleNewSettings(newSettings)
                    }
                }
            }
        }

        settingsNotifier.subscribe(this) { settings ->
            endpoint.sendEvent(Event.SettingsUpdate(settings))
        }
    }

    fun onDestroy() {
        daemon.unregisterListener(this)

        accountNumberNotifier.unsubscribeAll()
        dnsOptionsNotifier.unsubscribeAll()
        relaySettingsNotifier.unsubscribeAll()
        settingsNotifier.unsubscribeAll()
    }

    fun subscribe(id: Any, listener: (Settings) -> Unit) {
        settingsNotifier.subscribe(id) { maybeSettings ->
            maybeSettings?.let { settings ->
                listener(settings)
            }
        }
    }

    fun unsubscribe(id: Any) {
        settingsNotifier.unsubscribe(id)
    }

    private fun handleNewSettings(newSettings: Settings) {
        synchronized(this) {
            if (settings?.accountToken != newSettings.accountToken) {
                accountNumberNotifier.notify(newSettings.accountToken)
            }

            if (settings?.tunnelOptions?.dnsOptions != newSettings.tunnelOptions.dnsOptions) {
                dnsOptionsNotifier.notify(newSettings.tunnelOptions.dnsOptions)
            }

            if (settings?.relaySettings != newSettings.relaySettings) {
                relaySettingsNotifier.notify(newSettings.relaySettings)
            }

            settings = newSettings
        }
    }
}
