import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @account_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get account_delete;

  /// No description provided for @action_account_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete your account? This operation can not be undone!'**
  String get action_account_delete_confirm;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get action_delete;

  /// No description provided for @action_delete_checked.
  ///
  /// In en, this message translates to:
  /// **'Delete checked entries'**
  String get action_delete_checked;

  /// No description provided for @action_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get action_done;

  /// No description provided for @action_edit_entry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get action_edit_entry;

  /// No description provided for @action_sure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get action_sure;

  /// No description provided for @bug_report.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get bug_report;

  /// No description provided for @changelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @household_add.
  ///
  /// In en, this message translates to:
  /// **'Add household'**
  String get household_add;

  /// No description provided for @household_create.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get household_create;

  /// No description provided for @household_create_first.
  ///
  /// In en, this message translates to:
  /// **'Create your first household'**
  String get household_create_first;

  /// No description provided for @household_empty.
  ///
  /// In en, this message translates to:
  /// **'Empty around here...'**
  String get household_empty;

  /// No description provided for @household_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave household'**
  String get household_leave;

  /// No description provided for @household_name.
  ///
  /// In en, this message translates to:
  /// **'Name of household'**
  String get household_name;

  /// No description provided for @households.
  ///
  /// In en, this message translates to:
  /// **'Households'**
  String get households;

  /// No description provided for @item_add.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get item_add;

  /// No description provided for @item_hint.
  ///
  /// In en, this message translates to:
  /// **'Pasta'**
  String get item_hint;

  /// No description provided for @item_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get item_name;

  /// No description provided for @list_create.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get list_create;

  /// No description provided for @list_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get list_delete;

  /// No description provided for @lists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get lists;

  /// No description provided for @status_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get status_error;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tag_add.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get tag_add;

  /// No description provided for @tag_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag'**
  String get tag_hint;

  /// No description provided for @template_create.
  ///
  /// In en, this message translates to:
  /// **'Create template'**
  String get template_create;

  /// No description provided for @template_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get template_delete;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @user_invite.
  ///
  /// In en, this message translates to:
  /// **'Invite user'**
  String get user_invite;

  /// No description provided for @user_invite_hint.
  ///
  /// In en, this message translates to:
  /// **'friend@example.com'**
  String get user_invite_hint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
