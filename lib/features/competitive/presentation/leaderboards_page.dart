import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class LeaderboardsPage extends ConsumerStatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  ConsumerState<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends ConsumerState<LeaderboardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _mockWeekly = const [
    {
      'rank': 1,
      'name': 'Alice (BrushMaster)',
      'score': 2850,
      'tier': 'Platinum',
    },
    {'rank': 2, 'name': 'Bob (ScribbleLord)', 'score': 2400, 'tier': 'Gold'},
    {'rank': 3, 'name': 'Charlie (LineKing)', 'score': 2100, 'tier': 'Gold'},
    {'rank': 4, 'name': 'David (PaintQueen)', 'score': 1800, 'tier': 'Silver'},
  ];

  final List<Map<String, dynamic>> _mockMonthly = const [
    {
      'rank': 1,
      'name': 'Bob (ScribbleLord)',
      'score': 12400,
      'tier': 'Grandmaster',
    },
    {
      'rank': 2,
      'name': 'Alice (BrushMaster)',
      'score': 11800,
      'tier': 'Platinum',
    },
    {'rank': 3, 'name': 'Charlie (LineKing)', 'score': 9500, 'tier': 'Gold'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text('Leaderboard Standings', style: typography.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelStyle: typography.body.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: typography.caption,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Seasonal'),
          ],
        ),
      ),
      body: Container(
        color: colors.background,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStandingsList(context, _mockWeekly),
            _buildStandingsList(context, _mockMonthly),
            _buildStandingsList(context, _mockWeekly), // reuse for seasonal
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsList(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return ListView.builder(
      padding: EdgeInsets.all(spacing.md.r),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final entry = data[index];
        final rank = entry['rank'] as int;

        Color medalColor = colors.textMuted;
        if (rank == 1) medalColor = Colors.amber;
        if (rank == 2) medalColor = Colors.grey;
        if (rank == 3) medalColor = Colors.brown;

        return Padding(
          padding: EdgeInsets.only(bottom: spacing.sm.r),
          child: SWGlassCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: rank <= 3
                    ? medalColor.withValues(alpha: 0.2)
                    : colors.border,
                child: Text(
                  '#$rank',
                  style: typography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? medalColor : colors.textPrimary,
                  ),
                ),
              ),
              title: Text(
                entry['name'] as String,
                style: typography.body.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Tier: ${entry['tier']}',
                style: typography.caption.copyWith(color: colors.primary),
              ),
              trailing: Text(
                '${entry['score']} pts',
                style: typography.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
