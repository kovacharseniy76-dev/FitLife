import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Робоче місце адміністратора: «Керувати обліковими записами» і «Переглянути журнал подій».
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  late Future<List<Account>> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = context.read<AppState>().listAccounts();
  }

  void _reload() => setState(() => _accounts = context.read<AppState>().listAccounts());

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final admin = state.account! as Administrator;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(child: Text('Адміністрування', style: AppText.display(22))),
              SquareIconButton(icon: Icons.logout, tooltip: 'Вийти', onPressed: () => state.signOut()),
            ]),
            const SizedBox(height: 6),
            Text(admin.getDisplayName(), style: AppText.body(14, color: AppColors.muted)),
            const SizedBox(height: 18),
            Segmented(labels: const <String>['Облікові записи', 'Журнал подій'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
            const SizedBox(height: 16),
            if (_tab == 0)
              FutureBuilder<List<Account>>(
                future: _accounts,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: AppColors.lime)),
                    );
                  }
                  return Column(children: <Widget>[
                    for (final a in snap.data!) ...<Widget>[
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        radius: 16,
                        child: Row(children: <Widget>[
                          TintIcon(
                            icon: a is Administrator
                                ? Icons.shield_outlined
                                : (a is ContentManager ? Icons.edit_note : Icons.person_outline),
                            color: a.isActive() ? AppColors.lime : AppColors.danger,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                              Text(a.getDisplayName(), style: AppText.body(15, weight: FontWeight.w600)),
                              Text('${a.email} · ${a.roleName} · ${a.isActive() ? 'активний' : 'заблокований'}',
                                  style: AppText.body(12, color: AppColors.muted)),
                            ]),
                          ),
                          if (a.id != admin.id)
                            TextButton(
                              onPressed: () async {
                                await state.toggleBlock(a);
                                _reload();
                              },
                              child: Text(a.isActive() ? 'Блокувати' : 'Розблокувати',
                                  style: AppText.body(13,
                                      color: a.isActive() ? AppColors.danger : AppColors.lime, weight: FontWeight.w600)),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ]);
                },
              )
            else ...<Widget>[
              if (admin.viewSystemLogs().isEmpty) const EmptyHint(text: 'Журнал порожній'),
              for (final line in admin.viewSystemLogs().reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line, style: AppText.body(13, color: AppColors.soft)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
