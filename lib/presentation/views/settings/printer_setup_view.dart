import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../../core/services/bluetooth_printer_service.dart';
import 'bill_customizer_view.dart';

class PrinterSetupView extends StatefulWidget {
  const PrinterSetupView({super.key});

  @override
  State<PrinterSetupView> createState() => _PrinterSetupViewState();
}

class _PrinterSetupViewState extends State<PrinterSetupView> {
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().refreshPrinters();
    });
  }
  
  @override
  void dispose() {
    // Stop scanning when leaving the view
    final prov = context.read<SettingsProvider>();
    prov.stopScanning();
    super.dispose();
  }

  Future<void> _sendTestPrint() async {
    setState(() => _isTesting = true);
    final prov = context.read<SettingsProvider>();
    final success = await prov.testPrint();
    setState(() => _isTesting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test receipt sent to printer successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send print. Please ensure printer is powered on and connected.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _getConnectionStatusText(PrinterConnectionState state) {
    switch (state) {
      case PrinterConnectionState.connected: return 'CONNECTED';
      case PrinterConnectionState.connecting: return 'CONNECTING...';
      case PrinterConnectionState.reconnecting: return 'RECONNECTING...';
      case PrinterConnectionState.pairing: return 'PAIRING...';
      case PrinterConnectionState.waiting: return 'WAITING (OFFLINE)';
      case PrinterConnectionState.error: return 'ERROR';
      case PrinterConnectionState.disconnected: return 'DISCONNECTED';
    }
  }

  BadgeVariant _getBadgeVariant(PrinterConnectionState state) {
    switch (state) {
      case PrinterConnectionState.connected: return BadgeVariant.success;
      case PrinterConnectionState.connecting:
      case PrinterConnectionState.reconnecting:
      case PrinterConnectionState.pairing:
        return BadgeVariant.warning;
      case PrinterConnectionState.waiting: return BadgeVariant.neutral;
      case PrinterConnectionState.error: return BadgeVariant.danger;
      case PrinterConnectionState.disconnected: return BadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final printers = settings.discoveredPrinters;
    final activePrinter = settings.selectedPrinter;
    final state = settings.connectionState;
    final isConnected = state == PrinterConnectionState.connected;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Bluetooth Thermal Printer'),
        actions: [
          IconButton(
            icon: settings.isScanningPrinters
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, color: AppColors.primaryBlue),
            tooltip: 'Refresh / Scan Paired Printers',
            onPressed: () => settings.refreshPrinters(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_bluetooth, color: AppColors.accentNavy),
            tooltip: 'Open Phone Bluetooth Settings',
            onPressed: () => settings.openSystemBluetoothSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Printer Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Printer Status',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                      ),
                      AppBadge(
                        text: (settings.savedPrinterMac != null && activePrinter == null) ? 'SAVED (OFFLINE)' : _getConnectionStatusText(state),
                        variant: (settings.savedPrinterMac != null && activePrinter == null) ? BadgeVariant.neutral : _getBadgeVariant(state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (activePrinter != null && isConnected) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.print, color: AppColors.success, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activePrinter.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                              ),
                              Text(
                                'MAC: ${activePrinter.address} • Roll: ${settings.selectedPaperSize}',
                                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Test Print Slip',
                            icon: Icons.receipt_long,
                            height: 38,
                            isLoading: _isTesting,
                            onPressed: _sendTestPrint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            text: 'Disconnect',
                            variant: ButtonVariant.danger,
                            height: 38,
                            onPressed: () => settings.disconnectPrinter(),
                          ),
                        ),
                      ],
                    ),
                  ] else if (settings.savedPrinterMac != null || activePrinter != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.print_disabled, color: AppColors.warning, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activePrinter?.name ?? settings.savedPrinterName ?? 'Saved Thermal Printer',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                              ),
                              Text(
                                'MAC: ${activePrinter?.address ?? settings.savedPrinterMac}',
                                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: state == PrinterConnectionState.connecting || state == PrinterConnectionState.reconnecting || state == PrinterConnectionState.pairing ? 'Connecting...' : 'Reconnect Printer',
                            icon: Icons.sync,
                            height: 38,
                            isLoading: state == PrinterConnectionState.connecting || state == PrinterConnectionState.reconnecting || state == PrinterConnectionState.pairing,
                            onPressed: () {
                              if (settings.savedPrinterMac != null) {
                                settings.connectPrinter(BluetoothPrinterInfo(
                                  name: settings.savedPrinterName ?? 'Printer', 
                                  address: settings.savedPrinterMac!,
                                  isPaired: true
                                ));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            text: 'Forget Printer',
                            variant: ButtonVariant.ghost,
                            height: 38,
                            onPressed: () => settings.disconnectPrinter(),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No thermal printer connected. Pair your POS printer via Bluetooth and select it below.',
                        style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Printer Configuration (Paper Roll Size & Auto Print)
            const Text(
              'Printer Preferences',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thermal Paper Width', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('Standard 58mm (2") or 80mm (3")', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: '58mm', label: Text('58mm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          ButtonSegment(value: '80mm', label: Text('80mm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                        ],
                        selected: {settings.selectedPaperSize},
                        onSelectionChanged: (newSelection) {
                          if (newSelection.isNotEmpty) {
                            settings.setPaperSize(newSelection.first);
                          }
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: AppColors.primaryBlue,
                          selectedForegroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Auto-Print on Checkout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Automatically print receipt when a sale is paid', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                    value: settings.autoPrintOnSale,
                    activeTrackColor: AppColors.primaryBlue,
                    onChanged: (val) => settings.setAutoPrintOnSale(val),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.tune, color: AppColors.primaryBlue),
                    title: const Text('Bill & Receipt Customizer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Toggle header, breakdown, totals & KOT ticket', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                    trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.secondaryText),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BillCustomizerView())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // System Pairing Guidance Callout
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to pair a new Bluetooth Printer:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Printers should automatically show up in the list below. If they ask for a PIN, it is usually 0000 or 1234.',
                          style: TextStyle(fontSize: 11, color: AppColors.secondaryText, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Discovered / Paired Devices Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Available Bluetooth Thermal Printers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => settings.refreshPrinters(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Scan', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Printer list
            if (printers.isEmpty)
              CustomCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.bluetooth_searching, size: 36, color: AppColors.secondaryText),
                      const SizedBox(height: 8),
                      const Text(
                        'Scanning for Bluetooth printers...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentNavy),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Make sure Bluetooth is turned on and your thermal printer is in pairing mode.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => settings.refreshPrinters(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Scan Again'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: printers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = printers[index];
                  final isCurrent = settings.savedPrinterMac == p.address;

                  return CustomCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isCurrent ? AppColors.success : AppColors.primaryBlue).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCurrent ? Icons.print : Icons.bluetooth,
                            color: isCurrent ? AppColors.success : AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                  if (p.isPaired)
                                    const AppBadge(text: 'PAIRED', variant: BadgeVariant.neutral)
                                ],
                              ),
                              Text('MAC: ${p.address}', style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                            ],
                          ),
                        ),
                        if (isCurrent && isConnected)
                          const AppBadge(text: 'CONNECTED', variant: BadgeVariant.success)
                        else if (isCurrent)
                          const AppBadge(text: 'SELECTED', variant: BadgeVariant.warning)
                        else
                          ElevatedButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final isEnabled = await settings.isBluetoothEnabled();
                              if (!isEnabled) {
                                await settings.enableBluetooth();
                                if (mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enable Bluetooth on your phone and try again.'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                }
                                return;
                              }

                              bool paired = p.isPaired;
                              if (!paired) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Pairing with ${p.name}... (enter PIN 0000 or 1234 if prompted)'))
                                  );
                                }
                                paired = await settings.pairPrinter(p);
                              }
                              
                              final ok = await settings.connectPrinter(p);
                              if (mounted) {
                                if (ok) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Connecting to ${p.name}...'),
                                      backgroundColor: AppColors.primaryBlue,
                                    ),
                                  );
                                } else {
                                  final stillEnabled = await settings.isBluetoothEnabled();
                                  final msg = !stillEnabled
                                      ? 'Bluetooth is turned off. Please turn on Bluetooth.'
                                      : 'Could not connect to ${p.name}. Make sure Nearby Devices permission is granted and printer is on.';
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
                            ),
                            child: Text(p.isPaired ? 'Connect' : 'Pair & Connect', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
