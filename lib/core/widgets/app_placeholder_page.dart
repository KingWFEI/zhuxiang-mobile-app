import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_spacing.dart';

class AppPlaceholderAction {
  const AppPlaceholderAction({
    required this.label,
    required this.routeName,
    this.pathParameters = const {},
  });

  final String label;
  final String routeName;
  final Map<String, String> pathParameters;
}

class AppPlaceholderPage extends StatelessWidget {
  const AppPlaceholderPage({
    required this.title,
    super.key,
    this.description = '基础架构占位页，暂不包含真实业务逻辑',
    this.actions = const [],
  });

  final String title;
  final String description;
  final List<AppPlaceholderAction> actions;

  @override
  Widget build(BuildContext context) {
    final routeName = GoRouterState.of(context).name;
    final shouldShowReturnToMain =
        routeName != RouteNames.splash &&
        routeName != RouteNames.home &&
        routeName != RouteNames.search &&
        routeName != RouteNames.messageCenter &&
        routeName != RouteNames.profile;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                for (final action in actions) ...[
                  ElevatedButton(
                    onPressed: () => context.goNamed(
                      action.routeName,
                      pathParameters: action.pathParameters,
                    ),
                    child: Text(action.label),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
              const Spacer(),
              if (shouldShowReturnToMain)
                OutlinedButton(
                  onPressed: () => context.goNamed(RouteNames.main),
                  child: const Text('返回主框架'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
