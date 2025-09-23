import 'package:driver/controller/payment_method_controller.dart';
import 'package:driver/services/payment_method_service.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PaymentMethodSection extends StatelessWidget {
  const PaymentMethodSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<PaymentMethodController>(
      init: PaymentMethodController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Don't show if payment method switching is not available
        if (!controller.shouldShowPaymentMethodSwitch) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // Payment Method Header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_wallet.svg',
                    width: 24,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Payment Method".tr,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Current Payment Method Status
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeChange.getThem()
                    ? AppColors.darkContainerBackground
                    : AppColors.containerBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeChange.getThem()
                      ? AppColors.darkContainerBorder
                      : AppColors.containerBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Method Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: controller.selectedPaymentMethod.value == 'flat_rate' && controller.flatRateActive.value
                          ? Colors.green.withOpacity(0.1)
                          : themeChange.getThem()
                              ? AppColors.darkModePrimary.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.selectedPaymentMethod.value == 'flat_rate'
                              ? Icons.access_time
                              : Icons.percent,
                          color: controller.selectedPaymentMethod.value == 'flat_rate' && controller.flatRateActive.value
                              ? Colors.green
                              : themeChange.getThem()
                                  ? AppColors.darkModePrimary
                                  : AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current: ${PaymentMethodService.getPaymentMethodDisplayText(controller.selectedPaymentMethod.value)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (controller.selectedPaymentMethod.value == 'flat_rate') ...[
                                Text(
                                  controller.flatRateActive.value
                                      ? 'Active: ${controller.flatRateCountdownText}'
                                      : 'Expired - Renew or switch to commission',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: controller.flatRateActive.value 
                                        ? Colors.green 
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  controller.currentPaymentMethodDescription,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Flat Rate Renewal Section (if flat rate is selected but expired)
                  if (controller.selectedPaymentMethod.value == 'flat_rate' && !controller.flatRateActive.value) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Flat Rate Expired',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your 24-hour flat rate period has expired. Renew for ${controller.flatRateAmountText} or switch to commission.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: controller.isProcessingFlatRate.value || !controller.hasSufficientBalance.value
                                      ? null
                                      : controller.renewFlatRate,
                                  icon: controller.isProcessingFlatRate.value
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.refresh),
                                  label: Text('Renew ${controller.flatRateAmountText}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: controller.isSwitching.value
                                    ? null
                                    : controller.switchToCommission,
                                child: const Text('Switch to Commission'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (!controller.hasSufficientBalance.value) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Insufficient wallet balance for renewal.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Switch Options (only show if can switch and not in expired flat rate state)
                  if (controller.canSwitch.value && 
                      !(controller.selectedPaymentMethod.value == 'flat_rate' && !controller.flatRateActive.value)) ...[
                    Text(
                      'Switch Payment Method:'.tr,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Commission Option
                    if (controller.selectedPaymentMethod.value != 'commission' || 
                        (controller.selectedPaymentMethod.value == 'flat_rate' && !controller.flatRateActive.value))
                      _buildPaymentOption(
                        context,
                        themeChange,
                        controller,
                        'commission',
                        'Commission Based',
                        PaymentMethodService.getPaymentMethodDescription(
                          'commission',
                          controller.adminCommission.value,
                        ),
                        Icons.percent,
                        onTap: controller.switchToCommission,
                      ),

                    // Flat Rate Option
                    if (controller.selectedPaymentMethod.value != 'flat_rate' || 
                        !controller.flatRateActive.value)
                      _buildPaymentOption(
                        context,
                        themeChange,
                        controller,
                        'flat_rate',
                        'Daily Flat Rate',
                        'Pay ${controller.flatRateAmountText} for 24 hours of unlimited rides',
                        Icons.access_time,
                        onTap: () => _showFlatRateConfirmation(context, controller),
                        showBalance: true,
                        hasSufficientBalance: controller.hasSufficientBalance.value,
                      ),
                  ] else if (!controller.canSwitch.value) ...[
                    // Switch Cooldown Message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Switch Cooldown'.tr,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You can switch again in ${controller.switchCountdownText}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    DarkThemeProvider themeChange,
    PaymentMethodController controller,
    String method,
    String title,
    String description,
    IconData icon, {
    VoidCallback? onTap,
    bool showBalance = false,
    bool hasSufficientBalance = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (controller.isSwitching.value || controller.isProcessingFlatRate.value)
              ? null
              : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: !hasSufficientBalance && method == 'flat_rate'
                    ? Colors.red.withOpacity(0.5)
                    : themeChange.getThem()
                        ? AppColors.darkTextFieldBorder
                        : AppColors.textFieldBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: !hasSufficientBalance && method == 'flat_rate'
                        ? Colors.red.withOpacity(0.2)
                        : themeChange.getThem()
                            ? AppColors.darkModePrimary.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: !hasSufficientBalance && method == 'flat_rate'
                        ? Colors.red
                        : themeChange.getThem()
                            ? AppColors.darkModePrimary
                            : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (showBalance && !hasSufficientBalance) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Insufficient wallet balance',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (controller.isSwitching.value || controller.isProcessingFlatRate.value)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFlatRateConfirmation(
    BuildContext context,
    PaymentMethodController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Activate Daily Flat Rate'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activate daily flat rate for ${controller.flatRateAmountText}?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Benefits:',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• No commission on any trips for 24 hours\n• Unlimited rides without per-trip charges\n• Predictable daily cost',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Details:',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Amount: ${controller.flatRateAmountText}\n• Valid for: 24 hours from payment\n• Deducted from: Your wallet balance',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can only switch payment methods once every 24 hours.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: controller.hasSufficientBalance.value
                ? () {
                    Get.back();
                    controller.switchToFlatRate();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Activate ${controller.flatRateAmountText}'),
          ),
        ],
      ),
    );
  }
}