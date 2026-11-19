import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/activity_rings.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';

/// Екран 1 — Вітальний.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _open(BuildContext context, bool register) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AuthScreen(startWithRegister: register)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.monitor_heart_outlined, color: AppColors.bg, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text('FitLife', style: AppText.display(20)),
                ],
              ),
              const Expanded(
                child: Center(
                  child: ActivityRings(
                    size: 260,
                    stroke: 22,
                    rings: <RingData>[
                      RingData(0.76, AppColors.lime),
                      RingData(0.70, AppColors.orange),
                      RingData(0.72, AppColors.blue),
                    ],
                    center: Icon(Icons.monitor_heart_outlined, color: AppColors.text, size: 40),
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  style: AppText.display(32),
                  children: const <TextSpan>[
                    TextSpan(text: 'Тренуйся розумно.\n'),
                    TextSpan(text: 'Живи активно.', style: TextStyle(color: AppColors.lime)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Плануй тренування, відстежуй активність і формуй корисні звички — все в одному застосунку.',
                style: AppText.body(16, color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              AppButton(label: 'Почати', icon: Icons.arrow_forward, onPressed: () => _open(context, true)),
              const SizedBox(height: 12),
              AppButton(label: 'Вже маю акаунт', primary: false, onPressed: () => _open(context, false)),
            ],
          ),
        ),
      ),
    );
  }
}
