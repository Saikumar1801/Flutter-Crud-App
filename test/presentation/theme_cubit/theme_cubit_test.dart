import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_crud_app/presentation/theme_cubit/theme_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String themeCubitPreferenceKeyForTest = 'app_theme_preference_v1';

void main() {
  group('ThemeCubit', () {
    blocTest<ThemeCubit, AppTheme>(
      'emits [AppTheme.light] as initial state when no preference is stored',
      setUp: () {
        SharedPreferences.setMockInitialValues({});
      },
      build: () => ThemeCubit(),
      expect: () => [AppTheme.light],
    );

    blocTest<ThemeCubit, AppTheme>(
      'emits [AppTheme.dark] when dark theme preference is stored',
      setUp: () {
        SharedPreferences.setMockInitialValues({
          themeCubitPreferenceKeyForTest: AppTheme.dark.index,
        });
      },
      build: () => ThemeCubit(),
      expect: () => [AppTheme.dark],
    );

    blocTest<ThemeCubit, AppTheme>(
      'emits [AppTheme.dark] (initial) then [AppTheme.light] when toggleTheme is called on dark theme',
      setUp: () {
        SharedPreferences.setMockInitialValues({
          themeCubitPreferenceKeyForTest: AppTheme.dark.index,
        });
      },
      build: () => ThemeCubit(),
      act: (cubit) async {
        await Future.delayed(Duration.zero);
        cubit.toggleTheme();
      },
      expect: () => [AppTheme.dark, AppTheme.light],
    );

    blocTest<ThemeCubit, AppTheme>(
      'emits [AppTheme.light] (initial) then [AppTheme.dark] when toggleTheme is called on light theme',
      setUp: () {
         SharedPreferences.setMockInitialValues({
            themeCubitPreferenceKeyForTest: AppTheme.light.index,
         });
      },
      build: () => ThemeCubit(),
      act: (cubit) async {
        await Future.delayed(Duration.zero);
        cubit.toggleTheme();
      },
      expect: () => [AppTheme.light, AppTheme.dark],
    );

    blocTest<ThemeCubit, AppTheme>(
      'setTheme updates to the correct theme and only emits on change',
      setUp: () {
         SharedPreferences.setMockInitialValues({});
      },
      build: () => ThemeCubit(),
      act: (cubit) async {
        await Future.delayed(Duration.zero);
        cubit.setTheme(AppTheme.dark);
        cubit.setTheme(AppTheme.dark);
        cubit.setTheme(AppTheme.light);
        cubit.setTheme(AppTheme.light);
        cubit.setTheme(AppTheme.dark);
      },
      expect: () => [AppTheme.light, AppTheme.dark, AppTheme.light, AppTheme.dark],
    );
  });
}