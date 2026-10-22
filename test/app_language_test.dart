import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxmi_manager/core/localization/app_language.dart';
import 'package:xxmi_manager/core/localization/app_locale_cubit.dart';
import 'package:xxmi_manager/core/theme/app_theme.dart';
import 'package:xxmi_manager/features/settings/presentation/settings_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists and restores the selected language', () async {
    final cubit = AppLocaleCubit();
    await cubit.load();
    expect(cubit.state, AppLanguage.vietnamese);
    await cubit.changeLanguage(AppLanguage.chinese);

    final restored = AppLocaleCubit();
    await restored.load();
    expect(restored.state, AppLanguage.chinese);
    await cubit.close();
    await restored.close();
  });

  test('falls back to Vietnamese for an unknown stored language', () async {
    SharedPreferences.setMockInitialValues({
      AppLocaleCubit.preferenceKey: 'xx',
    });
    final cubit = AppLocaleCubit();
    await cubit.load();
    expect(cubit.state, AppLanguage.vietnamese);
    await cubit.close();
  });

  testWidgets('language radio cards stay horizontal and update the open page', (
    tester,
  ) async {
    void expectLanguageSurfaces(AppLanguage selected) {
      final tiles = tester.elementList(find.byType(RadioListTile<AppLanguage>));
      expect(tiles, hasLength(AppLanguage.values.length));
      for (final element in tiles) {
        final tile = element.widget as RadioListTile<AppLanguage>;
        final material = element.findAncestorWidgetOfExactType<Material>()!;
        // Each tile paints its own background and ink on the same Material.
        expect(
          material.color,
          tile.value == selected ? AppColors.primarySoft : AppColors.surface,
        );
        expect(material.clipBehavior, Clip.antiAlias);
        final shape = material.shape! as RoundedRectangleBorder;
        expect(
          shape.side.color,
          tile.value == selected ? AppColors.primary : AppColors.border,
        );
        element.visitAncestorElements((ancestor) {
          if (ancestor.widget is Material) return false;
          expect(ancestor.widget, isNot(isA<DecoratedBox>()));
          return true;
        });
      }
    }

    final cubit = AppLocaleCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocBuilder<AppLocaleCubit, AppLanguage>(
          builder: (context, language) => MaterialApp(
            theme: AppTheme.dark,
            locale: language.locale,
            supportedLocales: AppLanguage.values.map((item) => item.locale),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: SettingsPage(
              modsPath: '/Mods',
              downloadPath: '/ZZZ_Download',
              onChanged: (_, _) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expectLanguageSurfaces(AppLanguage.vietnamese);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    final vietnamese = tester.getCenter(find.text('Tiếng Việt'));
    final english = tester.getCenter(find.text('English'));
    final chinese = tester.getCenter(find.text('汉语'));
    expect(english.dy, vietnamese.dy);
    expect(chinese.dy, vietnamese.dy);
    expect(vietnamese.dx, lessThan(english.dx));
    expect(english.dx, lessThan(chinese.dx));

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Change'), findsNWidgets(2));
    expect(find.text('/ZZZ_Download'), findsOneWidget);
    expect(cubit.state, AppLanguage.english);
    expectLanguageSurfaces(AppLanguage.english);

    await tester.tap(find.text('汉语'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('更改'), findsNWidgets(2));
    expect(find.text('/Mods'), findsOneWidget);
    expect(cubit.state, AppLanguage.chinese);
    expectLanguageSurfaces(AppLanguage.chinese);
  });
}
