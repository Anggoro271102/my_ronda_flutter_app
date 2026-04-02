import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localizations/app_localizations.dart';
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
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @dashboard.
  ///
  /// In id, this message translates to:
  /// **'Dasboard'**
  String get dashboard;

  /// No description provided for @plantLocation.
  ///
  /// In id, this message translates to:
  /// **'Lokasi Plant'**
  String get plantLocation;

  /// No description provided for @allPlant.
  ///
  /// In id, this message translates to:
  /// **'Semua Unit'**
  String get allPlant;

  /// No description provided for @inspectionProgress.
  ///
  /// In id, this message translates to:
  /// **'Progres Inspeksi'**
  String get inspectionProgress;

  /// No description provided for @complete.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get complete;

  /// No description provided for @incomplete.
  ///
  /// In id, this message translates to:
  /// **'Belum Selesai'**
  String get incomplete;

  /// No description provided for @completionRate.
  ///
  /// In id, this message translates to:
  /// **'Tingkat Penyelesaian'**
  String get completionRate;

  /// No description provided for @issuesBySeverity.
  ///
  /// In id, this message translates to:
  /// **'Temuan Berdasarkan Tingkat Keparahan'**
  String get issuesBySeverity;

  /// No description provided for @inspection.
  ///
  /// In id, this message translates to:
  /// **'Inspeksi'**
  String get inspection;

  /// No description provided for @analysisResult.
  ///
  /// In id, this message translates to:
  /// **'Hasil Analisis'**
  String get analysisResult;

  /// No description provided for @objectDetected.
  ///
  /// In id, this message translates to:
  /// **'Objek Terdeteksi'**
  String get objectDetected;

  /// No description provided for @category.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @gpsLocation.
  ///
  /// In id, this message translates to:
  /// **'Lokasi GPS'**
  String get gpsLocation;

  /// No description provided for @severity.
  ///
  /// In id, this message translates to:
  /// **'Tingkat Keparahan'**
  String get severity;

  /// No description provided for @description.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi'**
  String get description;

  /// No description provided for @recommendation.
  ///
  /// In id, this message translates to:
  /// **'Rekomendasi'**
  String get recommendation;

  /// No description provided for @manualOverride.
  ///
  /// In id, this message translates to:
  /// **'Koreksi Manual Hasil AI?'**
  String get manualOverride;

  /// No description provided for @submit.
  ///
  /// In id, this message translates to:
  /// **'KIRIM'**
  String get submit;

  /// No description provided for @camera.
  ///
  /// In id, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In id, this message translates to:
  /// **'Galeri'**
  String get gallery;

  /// No description provided for @searchDetail.
  ///
  /// In id, this message translates to:
  /// **'Cari Berdasarkan Detail'**
  String get searchDetail;

  /// No description provided for @searchObject.
  ///
  /// In id, this message translates to:
  /// **'Cari Berdasarkan Objek'**
  String get searchObject;

  /// No description provided for @advancedFilters.
  ///
  /// In id, this message translates to:
  /// **'Filter Lanjutan'**
  String get advancedFilters;

  /// No description provided for @filterOptions.
  ///
  /// In id, this message translates to:
  /// **'Opsi Filter'**
  String get filterOptions;

  /// No description provided for @reset.
  ///
  /// In id, this message translates to:
  /// **'Atur Ulang'**
  String get reset;

  /// No description provided for @status.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @allCategories.
  ///
  /// In id, this message translates to:
  /// **'Semua Kategori'**
  String get allCategories;

  /// No description provided for @severityLevel.
  ///
  /// In id, this message translates to:
  /// **'Level Keparahan'**
  String get severityLevel;

  /// No description provided for @applyFilter.
  ///
  /// In id, this message translates to:
  /// **'Terapkan Filter'**
  String get applyFilter;

  /// No description provided for @safety.
  ///
  /// In id, this message translates to:
  /// **'KEAMANAN'**
  String get safety;

  /// No description provided for @hygiene.
  ///
  /// In id, this message translates to:
  /// **'KEBERSIHAN'**
  String get hygiene;

  /// No description provided for @orderliness.
  ///
  /// In id, this message translates to:
  /// **'KETERTIBAN'**
  String get orderliness;

  /// No description provided for @shift.
  ///
  /// In id, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @resolve.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan'**
  String get resolve;

  /// No description provided for @reports.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get reports;

  /// No description provided for @listReports.
  ///
  /// In id, this message translates to:
  /// **'Daftar Laporan'**
  String get listReports;

  /// No description provided for @tasks.
  ///
  /// In id, this message translates to:
  /// **'Tugas'**
  String get tasks;

  /// No description provided for @completedTasks.
  ///
  /// In id, this message translates to:
  /// **'Tugas Selesai'**
  String get completedTasks;

  /// No description provided for @employeeId.
  ///
  /// In id, this message translates to:
  /// **'ID Karyawan'**
  String get employeeId;

  /// No description provided for @email.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @department.
  ///
  /// In id, this message translates to:
  /// **'Departemen'**
  String get department;

  /// No description provided for @accountDetails.
  ///
  /// In id, this message translates to:
  /// **'Detail Akun'**
  String get accountDetails;

  /// No description provided for @assignedPlant.
  ///
  /// In id, this message translates to:
  /// **'Lokasi Tugas'**
  String get assignedPlant;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @browseMenu.
  ///
  /// In id, this message translates to:
  /// **'MENU UTAMA'**
  String get browseMenu;

  /// No description provided for @accountSupport.
  ///
  /// In id, this message translates to:
  /// **'AKUN & DUKUNGAN'**
  String get accountSupport;

  /// No description provided for @uploadToServer.
  ///
  /// In id, this message translates to:
  /// **'Mengirim Data ke Server...'**
  String get uploadToServer;

  /// No description provided for @object.
  ///
  /// In id, this message translates to:
  /// **'Objek'**
  String get object;

  /// No description provided for @editRecommendation.
  ///
  /// In id, this message translates to:
  /// **'Edit rekomendasi...'**
  String get editRecommendation;

  /// No description provided for @submitChanges.
  ///
  /// In id, this message translates to:
  /// **'KIRIM PERUBAHAN'**
  String get submitChanges;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @completeReport.
  ///
  /// In id, this message translates to:
  /// **'SELESAIKAN LAPORAN'**
  String get completeReport;

  /// No description provided for @profile.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @actionDescription.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi Tindakan'**
  String get actionDescription;

  /// No description provided for @editManual.
  ///
  /// In id, this message translates to:
  /// **'Edit Manual'**
  String get editManual;

  /// No description provided for @typeManualHint.
  ///
  /// In id, this message translates to:
  /// **'Ketik manual...'**
  String get typeManualHint;

  /// No description provided for @aiAnalysisResultHint.
  ///
  /// In id, this message translates to:
  /// **'Hasil analisis AI...'**
  String get aiAnalysisResultHint;

  /// No description provided for @submitCompletion.
  ///
  /// In id, this message translates to:
  /// **'SIMPAN PENYELESAIAN'**
  String get submitCompletion;

  /// No description provided for @editAiDescriptionTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Deskripsi AI'**
  String get editAiDescriptionTitle;

  /// No description provided for @editAiDescriptionDialog.
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda ingin mengubah deskripsi yang dihasilkan AI secara manual?'**
  String get editAiDescriptionDialog;

  /// No description provided for @yesEdit.
  ///
  /// In id, this message translates to:
  /// **'Ya, Edit'**
  String get yesEdit;

  /// No description provided for @errorLoadCompletion.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data penyelesaian'**
  String get errorLoadCompletion;

  /// No description provided for @completionSummary.
  ///
  /// In id, this message translates to:
  /// **'RINGKASAN PENYELESAIAN'**
  String get completionSummary;

  /// No description provided for @actionNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan Tindakan'**
  String get actionNote;

  /// No description provided for @resolvedBy.
  ///
  /// In id, this message translates to:
  /// **'Diselesaikan Oleh'**
  String get resolvedBy;

  /// No description provided for @resolutionTime.
  ///
  /// In id, this message translates to:
  /// **'Waktu Penyelesaian'**
  String get resolutionTime;

  /// No description provided for @descriptionTitle.
  ///
  /// In id, this message translates to:
  /// **'DESKRIPSI'**
  String get descriptionTitle;

  /// No description provided for @editDescriptionHint.
  ///
  /// In id, this message translates to:
  /// **'Edit deskripsi...'**
  String get editDescriptionHint;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
