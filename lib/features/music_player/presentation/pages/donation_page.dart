import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/localization/localization_extension.dart';
import '../widgets/meta_components.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  Future<void> _launchUrl(BuildContext context, String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlStr';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở liên kết: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('copied', args: {'label': label}, listen: false),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double paddingVal = MediaQuery.of(context).size.width < 360 ? 12 : 16;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          context.tr('donation_title'),
          style: AppTypography.headingSm.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        leading: Center(
          child: MetaIconCircularButton(
            icon: Icons.keyboard_arrow_left,
            size: 32,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(paddingVal),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heart graphic/icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 44,
                      color: AppColors.criticalStrong,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Thank you text
                Center(
                  child: Column(
                    children: [
                      Text(
                        context.tr('donation_thanks'),
                        style: AppTypography.subtitleLg.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkDeep,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('donation_desc'),
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.charcoal,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Method 1: Banking card design
                Text(
                  context.tr('banking_qr'),
                  style: AppTypography.bodySmBold.copyWith(
                    color: AppColors.inkDeep,
                  ),
                ),
                const SizedBox(height: 10),

                // Bank Card widget
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F2027),
                        Color(0xFF203A43),
                        Color(0xFF2C5364),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00FFCC).withAlpha(80),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'NAPAS / TECHCOMBANK',
                            style: TextStyle(
                              color: Color(0xFF00FFCC),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Icon(
                            Icons.contactless_outlined,
                            color: Colors.white.withAlpha(180),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Card number / Account number representation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '1907 2206 9400 11',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              fontFamily: 'monospace',
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _copyToClipboard(
                              context,
                              '19072206940011',
                              context.tr('account_number', listen: false),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('account_owner').toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                    fontSize: 8,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'VAN BA PHAT HUY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  context.tr('bank_branch').toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                    fontSize: 8,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('bank_branch_val'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // VietQR Image display
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'https://img.vietqr.io/image/techcombank-19072206940011-0.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 200,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: AppColors.surfaceSoft,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      color: AppColors.critical,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Không thể tải mã QR',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'VietQR',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Method 2: Mobile E-Wallets
                Text(
                  context.tr('mobile_wallets_title'),
                  style: AppTypography.bodySmBold.copyWith(
                    color: AppColors.inkDeep,
                  ),
                ),
                const SizedBox(height: 10),

                // MoMo card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.hairlineSoft,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // MoMo badge icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA50064), // MoMo pink color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'momo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('momo_wallet_label'),
                              style: AppTypography.bodySmBold.copyWith(
                                color: AppColors.inkDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SĐT: 0837444383\nVAN BA PHAT HUY',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.charcoal,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => _copyToClipboard(
                          context,
                          '0837444383',
                          context.tr('momo_wallet_label', listen: false),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ZaloPay card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.hairlineSoft,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ZaloPay badge icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0086DA), // ZaloPay blue color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Zalo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('zalopay_wallet_label'),
                              style: AppTypography.bodySmBold.copyWith(
                                color: AppColors.inkDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SĐT: 0837444383\nVAN BA PHAT HUY',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.charcoal,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => _copyToClipboard(
                          context,
                          '0837444383',
                          context.tr('zalopay_wallet_label', listen: false),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Method 3: External Platforms
                Text(
                  context.tr('external_platforms_title'),
                  style: AppTypography.bodySmBold.copyWith(
                    color: AppColors.inkDeep,
                  ),
                ),
                const SizedBox(height: 10),

                // Buy Me a Coffee card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.hairlineSoft,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDD00), // BMC yellow color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.coffee_rounded,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buy Me a Coffee',
                              style: AppTypography.bodySmBold.copyWith(
                                color: AppColors.inkDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'buymeacoffee.com/huyp04',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => _launchUrl(
                          context,
                          'https://buymeacoffee.com/huyp04',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Ko-fi card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.hairlineSoft,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1595B), // Ko-fi red color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ko-fi',
                              style: AppTypography.bodySmBold.copyWith(
                                color: AppColors.inkDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ko-fi.com/huyp04',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () =>
                            _launchUrl(context, 'https://ko-fi.com/huyp04'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // PayPal card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.hairlineSoft,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF003087), // PayPal blue color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.payment_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PayPal',
                              style: AppTypography.bodySmBold.copyWith(
                                color: AppColors.inkDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'paypal.me/VanBaPhatHuy2004ph',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => _launchUrl(
                          context,
                          'https://paypal.me/VanBaPhatHuy2004ph',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
