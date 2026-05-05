import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ru.dart';

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
    Locale('en'),
    Locale('he'),
    Locale('ru')
  ];

  /// No description provided for @brandEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Instant legal defense'**
  String get brandEyebrow;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get navFeatures;

  /// No description provided for @navPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get navPricing;

  /// No description provided for @navHow.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get navHow;

  /// No description provided for @navContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get navContact;

  /// No description provided for @navCareers.
  ///
  /// In en, this message translates to:
  /// **'Careers'**
  String get navCareers;

  /// No description provided for @navLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get navLogin;

  /// No description provided for @navRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get navRegister;

  /// No description provided for @heroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'VETO · 24/7 nationwide'**
  String get heroEyebrow;

  /// No description provided for @heroTitleL1.
  ///
  /// In en, this message translates to:
  /// **'Your legal protection'**
  String get heroTitleL1;

  /// No description provided for @heroTitleL2.
  ///
  /// In en, this message translates to:
  /// **' — always '**
  String get heroTitleL2;

  /// No description provided for @heroTitleEm.
  ///
  /// In en, this message translates to:
  /// **'within reach'**
  String get heroTitleEm;

  /// No description provided for @heroBody.
  ///
  /// In en, this message translates to:
  /// **'VETO connects you with a specialized lawyer within seconds in any emergency — full conversation logging and an encrypted vault.'**
  String get heroBody;

  /// No description provided for @heroCta.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get heroCta;

  /// No description provided for @heroSecondary.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get heroSecondary;

  /// No description provided for @miniStatBefore.
  ///
  /// In en, this message translates to:
  /// **'Connect in '**
  String get miniStatBefore;

  /// No description provided for @miniStatEm.
  ///
  /// In en, this message translates to:
  /// **'3 seconds'**
  String get miniStatEm;

  /// No description provided for @miniStatSuffix.
  ///
  /// In en, this message translates to:
  /// **'criminal lawyer on duty'**
  String get miniStatSuffix;

  /// No description provided for @proof1Num.
  ///
  /// In en, this message translates to:
  /// **'4.9'**
  String get proof1Num;

  /// No description provided for @proof1Lbl.
  ///
  /// In en, this message translates to:
  /// **'User rating'**
  String get proof1Lbl;

  /// No description provided for @proof2Num.
  ///
  /// In en, this message translates to:
  /// **'3″'**
  String get proof2Num;

  /// No description provided for @proof2Lbl.
  ///
  /// In en, this message translates to:
  /// **'Avg. connect time'**
  String get proof2Lbl;

  /// No description provided for @proof3Num.
  ///
  /// In en, this message translates to:
  /// **'+200'**
  String get proof3Num;

  /// No description provided for @proof3Lbl.
  ///
  /// In en, this message translates to:
  /// **'Registered lawyers'**
  String get proof3Lbl;

  /// No description provided for @feat1Title.
  ///
  /// In en, this message translates to:
  /// **'Immediate protection'**
  String get feat1Title;

  /// No description provided for @feat1Body.
  ///
  /// In en, this message translates to:
  /// **'Connect with a specialized lawyer within seconds — investigations, detention, disputes.'**
  String get feat1Body;

  /// No description provided for @feat2Title.
  ///
  /// In en, this message translates to:
  /// **'Direct lawyer access'**
  String get feat2Title;

  /// No description provided for @feat2Body.
  ///
  /// In en, this message translates to:
  /// **'Voice, video, or text — your choice. Full call logs stored only in your encrypted vault.'**
  String get feat2Body;

  /// No description provided for @feat3Title.
  ///
  /// In en, this message translates to:
  /// **'Full privacy'**
  String get feat3Title;

  /// No description provided for @feat3Body.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encryption, backup in your vault, access only for you — not the company or authorities.'**
  String get feat3Body;

  /// No description provided for @stat1num.
  ///
  /// In en, this message translates to:
  /// **'24/7'**
  String get stat1num;

  /// No description provided for @stat1lbl.
  ///
  /// In en, this message translates to:
  /// **'Legal Protection'**
  String get stat1lbl;

  /// No description provided for @stat2num.
  ///
  /// In en, this message translates to:
  /// **'Real'**
  String get stat2num;

  /// No description provided for @stat2lbl.
  ///
  /// In en, this message translates to:
  /// **'Lawyers'**
  String get stat2lbl;

  /// No description provided for @stat3num.
  ///
  /// In en, this message translates to:
  /// **'+3'**
  String get stat3num;

  /// No description provided for @stat3lbl.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get stat3lbl;

  /// No description provided for @stat4num.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get stat4num;

  /// No description provided for @stat4lbl.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get stat4lbl;

  /// No description provided for @stackTitle.
  ///
  /// In en, this message translates to:
  /// **'One response chain'**
  String get stackTitle;

  /// No description provided for @stackKicker.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get stackKicker;

  /// No description provided for @stack1Title.
  ///
  /// In en, this message translates to:
  /// **'Situation awareness'**
  String get stack1Title;

  /// No description provided for @stack1Body.
  ///
  /// In en, this message translates to:
  /// **'Questioned, detained, or in an accident? The system responds immediately.'**
  String get stack1Body;

  /// No description provided for @stack2Title.
  ///
  /// In en, this message translates to:
  /// **'AI conversation'**
  String get stack2Title;

  /// No description provided for @stack2Body.
  ///
  /// In en, this message translates to:
  /// **'The agent organizes facts, sharpens questions, and guides your next legal step.'**
  String get stack2Body;

  /// No description provided for @stack3Title.
  ///
  /// In en, this message translates to:
  /// **'Human handoff'**
  String get stack3Title;

  /// No description provided for @stack3Body.
  ///
  /// In en, this message translates to:
  /// **'When a lawyer is required — dispatch with priority for the right language.'**
  String get stack3Body;

  /// No description provided for @pricingTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get pricingTitle;

  /// No description provided for @pricingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Always-on protection layer'**
  String get pricingHeroTitle;

  /// No description provided for @pricingIntro.
  ///
  /// In en, this message translates to:
  /// **'Everything on one plan — AI assistant, rights library, encrypted vault and live lawyer dispatch.'**
  String get pricingIntro;

  /// No description provided for @pricingPrice.
  ///
  /// In en, this message translates to:
  /// **'₪19.90'**
  String get pricingPrice;

  /// No description provided for @pricingPeriod.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get pricingPeriod;

  /// No description provided for @pricingLine1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited legal AI assistant'**
  String get pricingLine1;

  /// No description provided for @pricingLine2.
  ///
  /// In en, this message translates to:
  /// **'Rights scenarios and evidence tools'**
  String get pricingLine2;

  /// No description provided for @pricingLine3.
  ///
  /// In en, this message translates to:
  /// **'Live lawyer dispatch billed by event'**
  String get pricingLine3;

  /// No description provided for @pricingLine4.
  ///
  /// In en, this message translates to:
  /// **'Encrypted vault for your documents'**
  String get pricingLine4;

  /// No description provided for @pricingLine5.
  ///
  /// In en, this message translates to:
  /// **'Hebrew · English · Русский support'**
  String get pricingLine5;

  /// No description provided for @ctaTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your legal safety layer before the incident begins'**
  String get ctaTitle;

  /// No description provided for @ctaBody.
  ///
  /// In en, this message translates to:
  /// **'Registration is short. Once done, every legal emergency starts from one clear interface.'**
  String get ctaBody;

  /// No description provided for @ctaBtn.
  ///
  /// In en, this message translates to:
  /// **'Open the wizard'**
  String get ctaBtn;

  /// No description provided for @ctaSecondary.
  ///
  /// In en, this message translates to:
  /// **'Talk to sales'**
  String get ctaSecondary;

  /// No description provided for @footer.
  ///
  /// In en, this message translates to:
  /// **'VETO LEGAL · Fast, intelligent, multilingual legal response'**
  String get footer;

  /// No description provided for @linkPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get linkPrivacy;

  /// No description provided for @linkTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get linkTerms;

  /// No description provided for @linkContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get linkContact;

  /// No description provided for @linkCareers.
  ///
  /// In en, this message translates to:
  /// **'Careers'**
  String get linkCareers;

  /// No description provided for @navPersonalArea.
  ///
  /// In en, this message translates to:
  /// **'Personal area'**
  String get navPersonalArea;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @menuSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'What would you like to search?'**
  String get menuSearchPlaceholder;

  /// No description provided for @menuSmartServices.
  ///
  /// In en, this message translates to:
  /// **'Smart legal services'**
  String get menuSmartServices;

  /// No description provided for @menuBenefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits with VETO'**
  String get menuBenefits;

  /// No description provided for @menuPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans & pricing'**
  String get menuPlans;

  /// No description provided for @menuCare.
  ///
  /// In en, this message translates to:
  /// **'VETO Care'**
  String get menuCare;

  /// No description provided for @menuContact.
  ///
  /// In en, this message translates to:
  /// **'Contact & support'**
  String get menuContact;

  /// No description provided for @menuBusiness.
  ///
  /// In en, this message translates to:
  /// **'VETO for business'**
  String get menuBusiness;

  /// No description provided for @menuTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get menuTerms;

  /// No description provided for @menuSafeUse.
  ///
  /// In en, this message translates to:
  /// **'Safe use'**
  String get menuSafeUse;

  /// No description provided for @menuAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuAbout;

  /// No description provided for @menuCareers.
  ///
  /// In en, this message translates to:
  /// **'Careers'**
  String get menuCareers;

  /// No description provided for @wheelKicker.
  ///
  /// In en, this message translates to:
  /// **'ONE RESPONSE CHAIN'**
  String get wheelKicker;

  /// No description provided for @wheelTellMore.
  ///
  /// In en, this message translates to:
  /// **'Tell me more +'**
  String get wheelTellMore;

  /// No description provided for @fabAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask VETO AI'**
  String get fabAskAi;

  /// No description provided for @fabCustomerSupport.
  ///
  /// In en, this message translates to:
  /// **'Customer support'**
  String get fabCustomerSupport;

  /// No description provided for @fabAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get fabAccessibility;

  /// No description provided for @wheel1Label.
  ///
  /// In en, this message translates to:
  /// **'Traffic stop'**
  String get wheel1Label;

  /// No description provided for @wheel2Label.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get wheel2Label;

  /// No description provided for @wheel3Label.
  ///
  /// In en, this message translates to:
  /// **'Detention'**
  String get wheel3Label;

  /// No description provided for @wheel4Label.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get wheel4Label;

  /// No description provided for @wheel5Label.
  ///
  /// In en, this message translates to:
  /// **'General counsel'**
  String get wheel5Label;

  /// No description provided for @wheel1Title.
  ///
  /// In en, this message translates to:
  /// **'Rights at a traffic stop'**
  String get wheel1Title;

  /// No description provided for @wheel1Body.
  ///
  /// In en, this message translates to:
  /// **'A calm checklist: documentation, what you may decline, and when to escalate to a lawyer.'**
  String get wheel1Body;

  /// No description provided for @wheel1Point1.
  ///
  /// In en, this message translates to:
  /// **'Note badge number and reason for the stop.'**
  String get wheel1Point1;

  /// No description provided for @wheel1Point2.
  ///
  /// In en, this message translates to:
  /// **'Many voluntary searches can be declined — know your context.'**
  String get wheel1Point2;

  /// No description provided for @wheel1Point3.
  ///
  /// In en, this message translates to:
  /// **'Tap SOS to route a criminal lawyer in seconds.'**
  String get wheel1Point3;

  /// No description provided for @wheel2Title.
  ///
  /// In en, this message translates to:
  /// **'After a road accident'**
  String get wheel2Title;

  /// No description provided for @wheel2Body.
  ///
  /// In en, this message translates to:
  /// **'Evidence, reporting, insurance — structured steps so nothing is missed.'**
  String get wheel2Body;

  /// No description provided for @wheel2Point1.
  ///
  /// In en, this message translates to:
  /// **'Secure scene photos and witness contacts if safe.'**
  String get wheel2Point1;

  /// No description provided for @wheel2Point2.
  ///
  /// In en, this message translates to:
  /// **'Exchange details and file reports as required.'**
  String get wheel2Point2;

  /// No description provided for @wheel2Point3.
  ///
  /// In en, this message translates to:
  /// **'Keep everything in your encrypted VETO vault.'**
  String get wheel2Point3;

  /// No description provided for @wheel3Title.
  ///
  /// In en, this message translates to:
  /// **'Investigation or detention'**
  String get wheel3Title;

  /// No description provided for @wheel3Body.
  ///
  /// In en, this message translates to:
  /// **'Silence strategy, lawyer timing, and custody basics — without panic.'**
  String get wheel3Body;

  /// No description provided for @wheel3Point1.
  ///
  /// In en, this message translates to:
  /// **'You have the right to consult counsel.'**
  String get wheel3Point1;

  /// No description provided for @wheel3Point2.
  ///
  /// In en, this message translates to:
  /// **'Avoid signing without understanding.'**
  String get wheel3Point2;

  /// No description provided for @wheel3Point3.
  ///
  /// In en, this message translates to:
  /// **'Dispatch keeps language preference in mind.'**
  String get wheel3Point3;

  /// No description provided for @wheel4Title.
  ///
  /// In en, this message translates to:
  /// **'Domestic or civil dispute'**
  String get wheel4Title;

  /// No description provided for @wheel4Body.
  ///
  /// In en, this message translates to:
  /// **'De-escalation, protective steps, and documentation for later proceedings.'**
  String get wheel4Body;

  /// No description provided for @wheel4Point1.
  ///
  /// In en, this message translates to:
  /// **'Prioritize safety and clear boundaries.'**
  String get wheel4Point1;

  /// No description provided for @wheel4Point2.
  ///
  /// In en, this message translates to:
  /// **'Log threats and incidents with timestamps.'**
  String get wheel4Point2;

  /// No description provided for @wheel4Point3.
  ///
  /// In en, this message translates to:
  /// **'Human handoff when stakes rise.'**
  String get wheel4Point3;

  /// No description provided for @wheel5Title.
  ///
  /// In en, this message translates to:
  /// **'General legal guidance'**
  String get wheel5Title;

  /// No description provided for @wheel5Body.
  ///
  /// In en, this message translates to:
  /// **'AI structures facts; humans decide — VETO bridges both.'**
  String get wheel5Body;

  /// No description provided for @wheel5Point1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited scenario prompts in your plan.'**
  String get wheel5Point1;

  /// No description provided for @wheel5Point2.
  ///
  /// In en, this message translates to:
  /// **'Rights library tuned to your jurisdiction context.'**
  String get wheel5Point2;

  /// No description provided for @wheel5Point3.
  ///
  /// In en, this message translates to:
  /// **'Upgrade path to live counsel any time.'**
  String get wheel5Point3;

  /// No description provided for @csetTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get csetTitle;

  /// No description provided for @csetProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get csetProfile;

  /// No description provided for @csetName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get csetName;

  /// No description provided for @csetPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get csetPhone;

  /// No description provided for @csetEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get csetEmail;

  /// No description provided for @csetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get csetLanguage;

  /// No description provided for @csetHebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get csetHebrew;

  /// No description provided for @csetEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get csetEnglish;

  /// No description provided for @csetRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get csetRussian;

  /// No description provided for @csetNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get csetNotifications;

  /// No description provided for @csetNotifyEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency alerts'**
  String get csetNotifyEmergency;

  /// No description provided for @csetNotifyUpdates.
  ///
  /// In en, this message translates to:
  /// **'System updates'**
  String get csetNotifyUpdates;

  /// No description provided for @csetNotifySms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get csetNotifySms;

  /// No description provided for @csetSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get csetSubscription;

  /// No description provided for @csetCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get csetCurrentPlan;

  /// No description provided for @csetUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get csetUpgrade;

  /// No description provided for @csetManagePayment.
  ///
  /// In en, this message translates to:
  /// **'Manage payment'**
  String get csetManagePayment;

  /// No description provided for @csetLawyerSettings.
  ///
  /// In en, this message translates to:
  /// **'Lawyer settings'**
  String get csetLawyerSettings;

  /// No description provided for @csetAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get csetAvailability;

  /// No description provided for @csetSpecializations.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get csetSpecializations;

  /// No description provided for @csetContactLinks.
  ///
  /// In en, this message translates to:
  /// **'Contact links'**
  String get csetContactLinks;

  /// No description provided for @csetWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get csetWhatsapp;

  /// No description provided for @csetTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get csetTelegram;

  /// No description provided for @csetAdminSettings.
  ///
  /// In en, this message translates to:
  /// **'Admin settings'**
  String get csetAdminSettings;

  /// No description provided for @csetSystemEmail.
  ///
  /// In en, this message translates to:
  /// **'System email'**
  String get csetSystemEmail;

  /// No description provided for @csetMaintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode'**
  String get csetMaintenanceMode;

  /// No description provided for @csetMaxFileSizeMb.
  ///
  /// In en, this message translates to:
  /// **'Max file size (MB)'**
  String get csetMaxFileSizeMb;

  /// No description provided for @csetDefaultQuotaMb.
  ///
  /// In en, this message translates to:
  /// **'Default file quota (MB)'**
  String get csetDefaultQuotaMb;

  /// No description provided for @csetDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get csetDanger;

  /// No description provided for @csetDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get csetDeleteAccount;

  /// No description provided for @csetDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This is irreversible. Confirm?'**
  String get csetDeleteConfirm;

  /// No description provided for @csetSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get csetSave;

  /// No description provided for @csetSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get csetSaved;

  /// No description provided for @csetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get csetCancel;

  /// No description provided for @csetYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get csetYes;

  /// No description provided for @csetNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get csetNo;

  /// No description provided for @csetLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get csetLogout;

  /// No description provided for @csetLegalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get csetLegalSection;

  /// No description provided for @csetPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get csetPrivacyPolicy;

  /// No description provided for @csetTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get csetTermsOfService;

  /// No description provided for @csetDeployBuild.
  ///
  /// In en, this message translates to:
  /// **'Deploy build'**
  String get csetDeployBuild;

  /// No description provided for @csetAddLink.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get csetAddLink;

  /// No description provided for @csetPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get csetPlanFree;

  /// No description provided for @csetPlanBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get csetPlanBasic;

  /// No description provided for @csetPlanPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get csetPlanPro;

  /// No description provided for @csetAgoraCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Video/audio calls (Agora)'**
  String get csetAgoraCallTitle;

  /// No description provided for @csetAgoraCallBody.
  ///
  /// In en, this message translates to:
  /// **'VETO routes video and audio calls through Agora RTC. No manual STUN/TURN settings are required. Allow camera and microphone in your browser or device settings.'**
  String get csetAgoraCallBody;

  /// No description provided for @csetWebrtcTitle.
  ///
  /// In en, this message translates to:
  /// **'WebRTC calls'**
  String get csetWebrtcTitle;

  /// No description provided for @csetWebrtcHint.
  ///
  /// In en, this message translates to:
  /// **'Applies to the next call. STUN from here; if the backend exposes TURN/ICE env vars, they are merged automatically.'**
  String get csetWebrtcHint;

  /// No description provided for @csetWebrtcIce.
  ///
  /// In en, this message translates to:
  /// **'STUN server set'**
  String get csetWebrtcIce;

  /// No description provided for @csetWebrtcIceMin.
  ///
  /// In en, this message translates to:
  /// **'Minimal (3 servers)'**
  String get csetWebrtcIceMin;

  /// No description provided for @csetWebrtcIceExt.
  ///
  /// In en, this message translates to:
  /// **'Extended (5 servers)'**
  String get csetWebrtcIceExt;

  /// No description provided for @csetWebrtcPool.
  ///
  /// In en, this message translates to:
  /// **'ICE candidate pool size'**
  String get csetWebrtcPool;

  /// No description provided for @csetWebrtcEcho.
  ///
  /// In en, this message translates to:
  /// **'Echo cancellation'**
  String get csetWebrtcEcho;

  /// No description provided for @csetWebrtcNoise.
  ///
  /// In en, this message translates to:
  /// **'Noise suppression'**
  String get csetWebrtcNoise;

  /// No description provided for @csetWebrtcAgc.
  ///
  /// In en, this message translates to:
  /// **'Auto gain control'**
  String get csetWebrtcAgc;

  /// No description provided for @csetWebrtcRes.
  ///
  /// In en, this message translates to:
  /// **'Video resolution'**
  String get csetWebrtcRes;

  /// No description provided for @csetWebrtcResSd.
  ///
  /// In en, this message translates to:
  /// **'SD 640×480'**
  String get csetWebrtcResSd;

  /// No description provided for @csetWebrtcResHd.
  ///
  /// In en, this message translates to:
  /// **'HD 1280×720'**
  String get csetWebrtcResHd;

  /// No description provided for @csetWebrtcResFhd.
  ///
  /// In en, this message translates to:
  /// **'Full HD 1920×1080'**
  String get csetWebrtcResFhd;

  /// No description provided for @csetWebrtcFacing.
  ///
  /// In en, this message translates to:
  /// **'Camera facing'**
  String get csetWebrtcFacing;

  /// No description provided for @csetWebrtcFacingUser.
  ///
  /// In en, this message translates to:
  /// **'Front (user)'**
  String get csetWebrtcFacingUser;

  /// No description provided for @csetWebrtcFacingEnv.
  ///
  /// In en, this message translates to:
  /// **'Back (environment)'**
  String get csetWebrtcFacingEnv;

  /// No description provided for @csetWebrtcBundle.
  ///
  /// In en, this message translates to:
  /// **'Bundle policy'**
  String get csetWebrtcBundle;

  /// No description provided for @csetWebrtcBundleBalanced.
  ///
  /// In en, this message translates to:
  /// **'balanced'**
  String get csetWebrtcBundleBalanced;

  /// No description provided for @csetWebrtcBundleMaxBundle.
  ///
  /// In en, this message translates to:
  /// **'max-bundle (recommended)'**
  String get csetWebrtcBundleMaxBundle;

  /// No description provided for @csetWebrtcBundleMaxCompat.
  ///
  /// In en, this message translates to:
  /// **'max-compat'**
  String get csetWebrtcBundleMaxCompat;

  /// No description provided for @csetWebrtcMux.
  ///
  /// In en, this message translates to:
  /// **'RTCP mux policy'**
  String get csetWebrtcMux;

  /// No description provided for @csetWebrtcMuxReq.
  ///
  /// In en, this message translates to:
  /// **'require (recommended)'**
  String get csetWebrtcMuxReq;

  /// No description provided for @csetWebrtcMuxNeg.
  ///
  /// In en, this message translates to:
  /// **'negotiate'**
  String get csetWebrtcMuxNeg;

  /// No description provided for @csetWizStep.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get csetWizStep;

  /// No description provided for @csetWizOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get csetWizOf;

  /// No description provided for @csetWizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get csetWizNext;

  /// No description provided for @csetWizBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get csetWizBack;

  /// No description provided for @csetWiz1Title.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get csetWiz1Title;

  /// No description provided for @csetWiz2Title.
  ///
  /// In en, this message translates to:
  /// **'Language & alerts'**
  String get csetWiz2Title;

  /// No description provided for @csetWiz3Title.
  ///
  /// In en, this message translates to:
  /// **'Calls & media'**
  String get csetWiz3Title;

  /// No description provided for @csetWiz4Title.
  ///
  /// In en, this message translates to:
  /// **'Account & plan'**
  String get csetWiz4Title;

  /// No description provided for @csetWiz5Title.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get csetWiz5Title;

  /// No description provided for @csetAdvancedCalls.
  ///
  /// In en, this message translates to:
  /// **'Advanced call & WebRTC'**
  String get csetAdvancedCalls;

  /// No description provided for @csetAdvancedCallsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For power users — ICE, codecs, device tuning'**
  String get csetAdvancedCallsSubtitle;

  /// No description provided for @lsetTitle.
  ///
  /// In en, this message translates to:
  /// **'Lawyer Settings'**
  String get lsetTitle;

  /// No description provided for @lsetAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get lsetAvailability;

  /// No description provided for @lsetAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Available for cases'**
  String get lsetAvailableNow;

  /// No description provided for @lsetAvailableDesc.
  ///
  /// In en, this message translates to:
  /// **'When active, clients can see and send requests to you'**
  String get lsetAvailableDesc;

  /// No description provided for @lsetSchedule.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get lsetSchedule;

  /// No description provided for @lsetScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'Set your working hours for each day'**
  String get lsetScheduleDesc;

  /// No description provided for @lsetMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get lsetMon;

  /// No description provided for @lsetTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get lsetTue;

  /// No description provided for @lsetWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get lsetWed;

  /// No description provided for @lsetThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get lsetThu;

  /// No description provided for @lsetFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get lsetFri;

  /// No description provided for @lsetSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get lsetSat;

  /// No description provided for @lsetSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get lsetSun;

  /// No description provided for @lsetFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get lsetFrom;

  /// No description provided for @lsetTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get lsetTo;

  /// No description provided for @lsetClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get lsetClosed;

  /// No description provided for @lsetSpecializations.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get lsetSpecializations;

  /// No description provided for @lsetSpecDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your areas of expertise'**
  String get lsetSpecDesc;

  /// No description provided for @lsetAddSpec.
  ///
  /// In en, this message translates to:
  /// **'Add specialization'**
  String get lsetAddSpec;

  /// No description provided for @lsetAddSpecHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Labor law'**
  String get lsetAddSpecHint;

  /// No description provided for @lsetContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Links'**
  String get lsetContact;

  /// No description provided for @lsetWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get lsetWhatsapp;

  /// No description provided for @lsetWhatsappHint.
  ///
  /// In en, this message translates to:
  /// **'+972501234567'**
  String get lsetWhatsappHint;

  /// No description provided for @lsetTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram username'**
  String get lsetTelegram;

  /// No description provided for @lsetTelegramHint.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get lsetTelegramHint;

  /// No description provided for @lsetResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. response time'**
  String get lsetResponseTime;

  /// No description provided for @lsetMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get lsetMinutes;

  /// No description provided for @lsetNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get lsetNotifications;

  /// No description provided for @lsetNotifyEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency alerts'**
  String get lsetNotifyEmergency;

  /// No description provided for @lsetNotifyNewCase.
  ///
  /// In en, this message translates to:
  /// **'New case alert'**
  String get lsetNotifyNewCase;

  /// No description provided for @lsetNotifyUpdates.
  ///
  /// In en, this message translates to:
  /// **'System updates'**
  String get lsetNotifyUpdates;

  /// No description provided for @lsetNotifySms.
  ///
  /// In en, this message translates to:
  /// **'SMS alerts'**
  String get lsetNotifySms;

  /// No description provided for @lsetLicense.
  ///
  /// In en, this message translates to:
  /// **'License Details'**
  String get lsetLicense;

  /// No description provided for @lsetLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get lsetLicenseNumber;

  /// No description provided for @lsetBarAssociation.
  ///
  /// In en, this message translates to:
  /// **'Bar association'**
  String get lsetBarAssociation;

  /// No description provided for @lsetLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages handled'**
  String get lsetLanguages;

  /// No description provided for @lsetAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get lsetAccount;

  /// No description provided for @lsetAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get lsetAdd;

  /// No description provided for @lsetSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get lsetSave;

  /// No description provided for @lsetSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get lsetSaved;

  /// No description provided for @lsetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get lsetCancel;

  /// No description provided for @lsetYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get lsetYes;

  /// No description provided for @lsetNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get lsetNo;

  /// No description provided for @lsetLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get lsetLogout;

  /// No description provided for @lsetDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get lsetDeleteAccount;

  /// No description provided for @lsetDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This is irreversible. Confirm?'**
  String get lsetDeleteConfirm;

  /// No description provided for @landingRoleLawyer.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get landingRoleLawyer;

  /// No description provided for @landingRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get landingRoleAdmin;

  /// No description provided for @landingRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get landingRoleUser;

  /// No description provided for @landingGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get landingGuestName;

  /// No description provided for @pricingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get pricingGetStarted;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your rights protection system'**
  String get splashTagline;

  /// No description provided for @wizLawyerConnected.
  ///
  /// In en, this message translates to:
  /// **'Lawyer connected: {lawyerName}'**
  String wizLawyerConnected(String lawyerName);

  /// No description provided for @wizNoLawyersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lawyers are available right now. Please try again shortly.'**
  String get wizNoLawyersAvailable;

  /// No description provided for @wizDefaultLawyerName.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get wizDefaultLawyerName;

  /// No description provided for @wizSessionAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get wizSessionAudio;

  /// No description provided for @wizSessionVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get wizSessionVideo;

  /// No description provided for @wizSessionChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get wizSessionChat;

  /// No description provided for @wizSessionAccepted.
  ///
  /// In en, this message translates to:
  /// **'{lawyerName} accepted'**
  String wizSessionAccepted(String lawyerName);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @citizenShellNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get citizenShellNavHome;

  /// No description provided for @citizenShellNavCases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get citizenShellNavCases;

  /// No description provided for @citizenShellNavContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get citizenShellNavContracts;

  /// No description provided for @citizenShellNavAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get citizenShellNavAlerts;

  /// No description provided for @citizenShellNavTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get citizenShellNavTasks;

  /// No description provided for @citizenShellNavContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get citizenShellNavContacts;

  /// No description provided for @citizenShellNavTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get citizenShellNavTools;

  /// No description provided for @citizenShellNavReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get citizenShellNavReports;

  /// No description provided for @citizenShellNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get citizenShellNavSettings;

  /// No description provided for @citizenShellMobileHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get citizenShellMobileHome;

  /// No description provided for @citizenShellMobileProtections.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get citizenShellMobileProtections;

  /// No description provided for @citizenShellMobileDocuments.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get citizenShellMobileDocuments;

  /// No description provided for @citizenShellMobileMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get citizenShellMobileMore;

  /// No description provided for @citizenShellMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get citizenShellMoreTitle;

  /// No description provided for @citizenShellMoreAiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get citizenShellMoreAiChat;

  /// No description provided for @citizenShellMoreCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get citizenShellMoreCalendar;

  /// No description provided for @citizenShellMoreNotebook.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get citizenShellMoreNotebook;

  /// No description provided for @citizenShellMoreMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get citizenShellMoreMap;

  /// No description provided for @citizenShellMoreReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get citizenShellMoreReports;

  /// No description provided for @citizenShellMoreSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get citizenShellMoreSettings;

  /// No description provided for @citizenShellMoreProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get citizenShellMoreProfile;

  /// No description provided for @citizenShellSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search cases, contracts, contacts…'**
  String get citizenShellSearchHint;

  /// No description provided for @citizenShellSearchSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Search coming soon'**
  String get citizenShellSearchSnackbar;

  /// No description provided for @citizenBtnNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get citizenBtnNew;

  /// No description provided for @citizenHubYourTools.
  ///
  /// In en, this message translates to:
  /// **'Your tools'**
  String get citizenHubYourTools;

  /// No description provided for @citizenToolVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get citizenToolVault;

  /// No description provided for @citizenTaskNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get citizenTaskNewTitle;

  /// No description provided for @citizenTaskFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get citizenTaskFieldTitle;

  /// No description provided for @citizenDeleteTaskBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get citizenDeleteTaskBody;

  /// No description provided for @citizenDeleteContactBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this contact?'**
  String get citizenDeleteContactBody;

  /// No description provided for @citizenDeleteContractBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this contract?'**
  String get citizenDeleteContractBody;

  /// No description provided for @citizenContactDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get citizenContactDialogTitle;

  /// No description provided for @citizenContactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get citizenContactNameLabel;

  /// No description provided for @citizenContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get citizenContactPhoneLabel;

  /// No description provided for @citizenContractNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New contract'**
  String get citizenContractNewTitle;

  /// No description provided for @citizenContractTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get citizenContractTitleLabel;

  /// No description provided for @citizenContractPartyLabel.
  ///
  /// In en, this message translates to:
  /// **'Counterparty'**
  String get citizenContractPartyLabel;

  /// No description provided for @citizenSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security center'**
  String get citizenSecurityTitle;

  /// No description provided for @citizenSecurityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get citizenSecurityPrivacy;

  /// No description provided for @citizenSecurityTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get citizenSecurityTerms;

  /// No description provided for @citizenSecurityAccount.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get citizenSecurityAccount;

  /// No description provided for @citizenPageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get citizenPageNotifications;

  /// No description provided for @citizenContractExportPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get citizenContractExportPdfTooltip;

  /// No description provided for @citizenContractExportDocxTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export DOCX'**
  String get citizenContractExportDocxTooltip;

  /// No description provided for @citizenExportPdfDone.
  ///
  /// In en, this message translates to:
  /// **'PDF exported'**
  String get citizenExportPdfDone;

  /// No description provided for @citizenExportDocxDone.
  ///
  /// In en, this message translates to:
  /// **'DOCX exported'**
  String get citizenExportDocxDone;

  /// No description provided for @citizenExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get citizenExportFailed;

  /// No description provided for @lawyerDashAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept case'**
  String get lawyerDashAccept;

  /// No description provided for @lawyerDashAccepted.
  ///
  /// In en, this message translates to:
  /// **'The case was assigned to you successfully.'**
  String get lawyerDashAccepted;

  /// No description provided for @lawyerDashActivity.
  ///
  /// In en, this message translates to:
  /// **'Emergency inbox'**
  String get lawyerDashActivity;

  /// No description provided for @lawyerDashActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each request shows the live event details exactly as received from the citizen app.'**
  String get lawyerDashActivitySubtitle;

  /// No description provided for @lawyerDashActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Active requests'**
  String get lawyerDashActivityTitle;

  /// No description provided for @lawyerDashEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'As soon as a user triggers SOS and you are marked available, the request will appear here for immediate response.'**
  String get lawyerDashEmptyBody;

  /// No description provided for @lawyerDashEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Keep availability on to stay high in dispatch priority.'**
  String get lawyerDashEmptyHint;

  /// No description provided for @lawyerDashEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active requests right now'**
  String get lawyerDashEmptyTitle;

  /// No description provided for @lawyerDashEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Legal response center'**
  String get lawyerDashEyebrow;

  /// No description provided for @lawyerDashLiveDialog.
  ///
  /// In en, this message translates to:
  /// **'Incoming request'**
  String get lawyerDashLiveDialog;

  /// No description provided for @lawyerDashLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get lawyerDashLogout;

  /// No description provided for @lawyerDashProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get lawyerDashProfile;

  /// No description provided for @lawyerDashQueue.
  ///
  /// In en, this message translates to:
  /// **'Pending alerts'**
  String get lawyerDashQueue;

  /// No description provided for @lawyerDashReject.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get lawyerDashReject;

  /// No description provided for @lawyerDashRejected.
  ///
  /// In en, this message translates to:
  /// **'The request was removed from your queue.'**
  String get lawyerDashRejected;

  /// No description provided for @lawyerDashRequest.
  ///
  /// In en, this message translates to:
  /// **'Emergency request'**
  String get lawyerDashRequest;

  /// No description provided for @lawyerDashRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get lawyerDashRequestDetails;

  /// No description provided for @lawyerDashRequestFrom.
  ///
  /// In en, this message translates to:
  /// **'Request from user'**
  String get lawyerDashRequestFrom;

  /// No description provided for @lawyerDashRequestUnknown.
  ///
  /// In en, this message translates to:
  /// **'No additional details were sent.'**
  String get lawyerDashRequestUnknown;

  /// No description provided for @lawyerDashResponse.
  ///
  /// In en, this message translates to:
  /// **'Response target'**
  String get lawyerDashResponse;

  /// No description provided for @lawyerDashResponseValue.
  ///
  /// In en, this message translates to:
  /// **'Under 2 min'**
  String get lawyerDashResponseValue;

  /// No description provided for @lawyerDashShift.
  ///
  /// In en, this message translates to:
  /// **'Shift control'**
  String get lawyerDashShift;

  /// No description provided for @lawyerDashShiftBody.
  ///
  /// In en, this message translates to:
  /// **'Turn availability on when you are ready to take a case. Once you accept a call, the system marks you busy to avoid duplicate assignments.'**
  String get lawyerDashShiftBody;

  /// No description provided for @lawyerDashShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Live availability control'**
  String get lawyerDashShiftTitle;

  /// No description provided for @lawyerDashStatus.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get lawyerDashStatus;

  /// No description provided for @lawyerDashStatusHelp.
  ///
  /// In en, this message translates to:
  /// **'When the switch is on, nearby users can be matched to you during emergencies.'**
  String get lawyerDashStatusHelp;

  /// No description provided for @lawyerDashStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Unavailable right now'**
  String get lawyerDashStatusOffline;

  /// No description provided for @lawyerDashStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Available for emergency calls'**
  String get lawyerDashStatusOnline;

  /// No description provided for @lawyerDashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every emergency request lands here with full control over availability, response time, and case acceptance.'**
  String get lawyerDashSubtitle;

  /// No description provided for @lawyerDashTitle.
  ///
  /// In en, this message translates to:
  /// **'Lawyer console'**
  String get lawyerDashTitle;

  /// No description provided for @lawyerDashServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection.'**
  String get lawyerDashServerUnreachable;

  /// No description provided for @lawyerDashWaitingClientChoice.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the client to choose session type…'**
  String get lawyerDashWaitingClientChoice;

  /// No description provided for @lawyerDashNoPendingAlerts.
  ///
  /// In en, this message translates to:
  /// **'No pending emergency alerts'**
  String get lawyerDashNoPendingAlerts;

  /// No description provided for @lawyerDashVaultRequiresCase.
  ///
  /// In en, this message translates to:
  /// **'Accept a case or pick an active case to view files'**
  String get lawyerDashVaultRequiresCase;

  /// No description provided for @lawyerDashBadgeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get lawyerDashBadgeOnline;

  /// No description provided for @lawyerDashBadgeOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get lawyerDashBadgeOffline;

  /// No description provided for @lawyerDashMobileHeader.
  ///
  /// In en, this message translates to:
  /// **'Lawyer dashboard'**
  String get lawyerDashMobileHeader;

  /// No description provided for @lawyerDashGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, Adv. {name}'**
  String lawyerDashGreeting(String name);

  /// No description provided for @lawyerDashActiveCaseCount.
  ///
  /// In en, this message translates to:
  /// **'You have {count} active cases'**
  String lawyerDashActiveCaseCount(int count);

  /// No description provided for @lawyerDashStatActiveCases.
  ///
  /// In en, this message translates to:
  /// **'Active cases'**
  String get lawyerDashStatActiveCases;

  /// No description provided for @lawyerDashStatTodayCalls.
  ///
  /// In en, this message translates to:
  /// **'Today\'s calls'**
  String get lawyerDashStatTodayCalls;

  /// No description provided for @lawyerDashStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get lawyerDashStatRating;

  /// No description provided for @lawyerDashToggleAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available for calls'**
  String get lawyerDashToggleAvailable;

  /// No description provided for @lawyerDashToggleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get lawyerDashToggleUnavailable;

  /// No description provided for @lawyerDashSectionActiveCases.
  ///
  /// In en, this message translates to:
  /// **'Active cases'**
  String get lawyerDashSectionActiveCases;

  /// No description provided for @lawyerDashViewCase.
  ///
  /// In en, this message translates to:
  /// **'View case'**
  String get lawyerDashViewCase;

  /// No description provided for @lawyerDashCloseCase.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get lawyerDashCloseCase;

  /// No description provided for @lawyerDashNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get lawyerDashNavHome;

  /// No description provided for @lawyerDashNavCases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get lawyerDashNavCases;

  /// No description provided for @lawyerDashNavChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get lawyerDashNavChat;

  /// No description provided for @lawyerDashNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get lawyerDashNavProfile;

  /// No description provided for @lawyerDashSidebarNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get lawyerDashSidebarNavigation;

  /// No description provided for @lawyerDashSidebarDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get lawyerDashSidebarDashboard;

  /// No description provided for @lawyerDashSidebarCases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get lawyerDashSidebarCases;

  /// No description provided for @lawyerDashSidebarChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get lawyerDashSidebarChat;

  /// No description provided for @lawyerDashSidebarProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get lawyerDashSidebarProfile;

  /// No description provided for @lawyerDashSidebarSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get lawyerDashSidebarSettings;

  /// No description provided for @lawyerDashRoleLawyer.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get lawyerDashRoleLawyer;

  /// No description provided for @lawyerDashChipUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get lawyerDashChipUrgent;

  /// No description provided for @lawyerDashChipPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get lawyerDashChipPending;

  /// No description provided for @lawyerDashUserFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get lawyerDashUserFallback;

  /// No description provided for @lawyerDashClientLine.
  ///
  /// In en, this message translates to:
  /// **'Client: {name}'**
  String lawyerDashClientLine(String name);

  /// No description provided for @lawyerDashEmergencyFallback.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get lawyerDashEmergencyFallback;

  /// No description provided for @profScreenBadgePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get profScreenBadgePremium;

  /// No description provided for @profScreenBadgeSince.
  ///
  /// In en, this message translates to:
  /// **'Since 2025'**
  String get profScreenBadgeSince;

  /// No description provided for @profScreenBadgeVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profScreenBadgeVerified;

  /// No description provided for @profScreenLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get profScreenLanguage;

  /// No description provided for @profScreenLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profScreenLogout;

  /// No description provided for @profScreenName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profScreenName;

  /// No description provided for @profScreenNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get profScreenNameEmpty;

  /// No description provided for @profScreenNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get profScreenNameHint;

  /// No description provided for @profScreenPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profScreenPhone;

  /// No description provided for @profScreenRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profScreenRole;

  /// No description provided for @profScreenSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profScreenSave;

  /// No description provided for @profScreenSaveError.
  ///
  /// In en, this message translates to:
  /// **'We could not save your changes.'**
  String get profScreenSaveError;

  /// No description provided for @profScreenSaved.
  ///
  /// In en, this message translates to:
  /// **'Your profile was updated successfully.'**
  String get profScreenSaved;

  /// No description provided for @profScreenStatCases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get profScreenStatCases;

  /// No description provided for @profScreenStatDays.
  ///
  /// In en, this message translates to:
  /// **'Days on VETO'**
  String get profScreenStatDays;

  /// No description provided for @profScreenStatFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get profScreenStatFiles;

  /// No description provided for @profScreenSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'Premium Monthly · ₪19.90/mo · renews on the 15th'**
  String get profScreenSubscriptionBody;

  /// No description provided for @profScreenSubscriptionCta.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get profScreenSubscriptionCta;

  /// No description provided for @profScreenSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your subscription'**
  String get profScreenSubscriptionTitle;

  /// No description provided for @profScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profScreenTitle;

  /// No description provided for @loginAuthSideOtpH1Em.
  ///
  /// In en, this message translates to:
  /// **'6 digits'**
  String get loginAuthSideOtpH1Em;

  /// No description provided for @loginAuthSideOtpH1L1.
  ///
  /// In en, this message translates to:
  /// **'We sent a code'**
  String get loginAuthSideOtpH1L1;

  /// No description provided for @loginAuthSideOtpH1L2.
  ///
  /// In en, this message translates to:
  /// **'with '**
  String get loginAuthSideOtpH1L2;

  /// No description provided for @loginAuthSideOtpP.
  ///
  /// In en, this message translates to:
  /// **'Type the SMS code or paste it. Codes expire in about 10 minutes.'**
  String get loginAuthSideOtpP;

  /// No description provided for @loginAuthSideOtpQ.
  ///
  /// In en, this message translates to:
  /// **'\"It is not just counsel — it is knowing someone has your back at 2 a.m.\"'**
  String get loginAuthSideOtpQ;

  /// No description provided for @loginAuthSideOtpQi.
  ///
  /// In en, this message translates to:
  /// **'SK'**
  String get loginAuthSideOtpQi;

  /// No description provided for @loginAuthSideOtpQn.
  ///
  /// In en, this message translates to:
  /// **'Shira Cohen'**
  String get loginAuthSideOtpQn;

  /// No description provided for @loginAuthSideOtpQr.
  ///
  /// In en, this message translates to:
  /// **'Attorney · professional user'**
  String get loginAuthSideOtpQr;

  /// No description provided for @loginAuthSideProfF1b.
  ///
  /// In en, this message translates to:
  /// **'One-time OTP — no saved passwords.'**
  String get loginAuthSideProfF1b;

  /// No description provided for @loginAuthSideProfF1t.
  ///
  /// In en, this message translates to:
  /// **'Phone verification'**
  String get loginAuthSideProfF1t;

  /// No description provided for @loginAuthSideProfF2b.
  ///
  /// In en, this message translates to:
  /// **'Your Google account — one tap.'**
  String get loginAuthSideProfF2b;

  /// No description provided for @loginAuthSideProfF2t.
  ///
  /// In en, this message translates to:
  /// **'Or Google Sign-In'**
  String get loginAuthSideProfF2t;

  /// No description provided for @loginAuthSideProfH1Em.
  ///
  /// In en, this message translates to:
  /// **'to verify you'**
  String get loginAuthSideProfH1Em;

  /// No description provided for @loginAuthSideProfH1L1.
  ///
  /// In en, this message translates to:
  /// **'Details used'**
  String get loginAuthSideProfH1L1;

  /// No description provided for @loginAuthSideProfH1L2.
  ///
  /// In en, this message translates to:
  /// **'only '**
  String get loginAuthSideProfH1L2;

  /// No description provided for @loginAuthSideProfP.
  ///
  /// In en, this message translates to:
  /// **'No spam, no selling data, no sharing with authorities. Phone is verification only.'**
  String get loginAuthSideProfP;

  /// No description provided for @loginAuthSideRoleF1b.
  ///
  /// In en, this message translates to:
  /// **'Mobile app or desktop browser — your data stays in sync.'**
  String get loginAuthSideRoleF1b;

  /// No description provided for @loginAuthSideRoleF1t.
  ///
  /// In en, this message translates to:
  /// **'One account · every device'**
  String get loginAuthSideRoleF1t;

  /// No description provided for @loginAuthSideRoleF2b.
  ///
  /// In en, this message translates to:
  /// **'One-time OTP, JWT, and encrypted local storage.'**
  String get loginAuthSideRoleF2b;

  /// No description provided for @loginAuthSideRoleF2t.
  ///
  /// In en, this message translates to:
  /// **'Bank-grade security'**
  String get loginAuthSideRoleF2t;

  /// No description provided for @loginAuthSideRoleF3b.
  ///
  /// In en, this message translates to:
  /// **'Hebrew, English, Russian — full UI.'**
  String get loginAuthSideRoleF3b;

  /// No description provided for @loginAuthSideRoleF3t.
  ///
  /// In en, this message translates to:
  /// **'Three languages'**
  String get loginAuthSideRoleF3t;

  /// No description provided for @loginAuthSideRoleH1Em.
  ///
  /// In en, this message translates to:
  /// **'for every role'**
  String get loginAuthSideRoleH1Em;

  /// No description provided for @loginAuthSideRoleH1L1.
  ///
  /// In en, this message translates to:
  /// **'Your access layer'**
  String get loginAuthSideRoleH1L1;

  /// No description provided for @loginAuthSideRoleH1L2.
  ///
  /// In en, this message translates to:
  /// **'— '**
  String get loginAuthSideRoleH1L2;

  /// No description provided for @loginAuthSideRoleP.
  ///
  /// In en, this message translates to:
  /// **'Choose citizen if you need protection, or lawyer if you join our digital practice. The flow adapts to your role.'**
  String get loginAuthSideRoleP;

  /// No description provided for @loginAuthSideRoleQ.
  ///
  /// In en, this message translates to:
  /// **'\"I had a lawyer on the line in four seconds, in the middle of the night — before I said a word to the investigator.\"'**
  String get loginAuthSideRoleQ;

  /// No description provided for @loginAuthSideRoleQi.
  ///
  /// In en, this message translates to:
  /// **'DK'**
  String get loginAuthSideRoleQi;

  /// No description provided for @loginAuthSideRoleQn.
  ///
  /// In en, this message translates to:
  /// **'Daniel Cohen'**
  String get loginAuthSideRoleQn;

  /// No description provided for @loginAuthSideRoleQr.
  ///
  /// In en, this message translates to:
  /// **'Member since 2025'**
  String get loginAuthSideRoleQr;

  /// No description provided for @loginBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get loginBack;

  /// No description provided for @loginBrandTagline.
  ///
  /// In en, this message translates to:
  /// **'Immediate legal protection'**
  String get loginBrandTagline;

  /// No description provided for @loginChangePhone.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get loginChangePhone;

  /// No description provided for @loginChooseRole.
  ///
  /// In en, this message translates to:
  /// **'How do you enter VETO?'**
  String get loginChooseRole;

  /// No description provided for @loginChooseRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Your choice sets the dashboard, flow and working language.'**
  String get loginChooseRoleBody;

  /// No description provided for @loginCitizenBody.
  ///
  /// In en, this message translates to:
  /// **'Immediate legal guidance, AI, scenarios, SOS and evidence capture.'**
  String get loginCitizenBody;

  /// No description provided for @loginCitizenTitle.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get loginCitizenTitle;

  /// No description provided for @loginCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get loginCopied;

  /// No description provided for @loginCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get loginCopyCode;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get loginEmailHint;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailLabel;

  /// No description provided for @loginEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Sign in / Register'**
  String get loginEyebrow;

  /// No description provided for @loginFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get loginFullName;

  /// No description provided for @loginGoogleBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogleBtn;

  /// No description provided for @loginGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get loginGoogleFailed;

  /// No description provided for @loginGoogleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not configured yet. Please use phone.'**
  String get loginGoogleNotConfigured;

  /// No description provided for @loginInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 9–10 digit phone number.'**
  String get loginInvalidPhone;

  /// No description provided for @loginLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get loginLater;

  /// No description provided for @loginLawyerBody.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts, control availability and handle cases in your console.'**
  String get loginLawyerBody;

  /// No description provided for @loginLawyerTitle.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get loginLawyerTitle;

  /// No description provided for @loginLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginLogin;

  /// No description provided for @loginMissingName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name to complete registration.'**
  String get loginMissingName;

  /// No description provided for @loginNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginNext;

  /// No description provided for @loginOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOrDivider;

  /// No description provided for @loginOtpDialogBody.
  ///
  /// In en, this message translates to:
  /// **'SMS is currently unavailable. Use this temporary code:'**
  String get loginOtpDialogBody;

  /// No description provided for @loginOtpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Your verification code'**
  String get loginOtpDialogTitle;

  /// No description provided for @loginOtpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the code. Make sure the account exists or switch to registration.'**
  String get loginOtpFailed;

  /// No description provided for @loginOtpH2.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get loginOtpH2;

  /// No description provided for @loginOtpIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits.'**
  String get loginOtpIncomplete;

  /// No description provided for @loginOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'The code is not valid.'**
  String get loginOtpInvalid;

  /// No description provided for @loginOtpLede.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your phone:'**
  String get loginOtpLede;

  /// No description provided for @loginOtpNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Make sure the API is running (port 5001 locally) and the address is correct.'**
  String get loginOtpNetwork;

  /// No description provided for @loginOtpNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account was found for this phone number. Switch to registration or check the number.'**
  String get loginOtpNotFound;

  /// No description provided for @loginOtpRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many code requests in a short time. Please wait about 10 minutes and try again.'**
  String get loginOtpRateLimited;

  /// No description provided for @loginOtpSentLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent to'**
  String get loginOtpSentLabel;

  /// No description provided for @loginOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to '**
  String get loginOtpSentTo;

  /// No description provided for @loginOtpServer.
  ///
  /// In en, this message translates to:
  /// **'The server is temporarily unavailable. Please try again in a moment.'**
  String get loginOtpServer;

  /// No description provided for @loginOtpStepKicker.
  ///
  /// In en, this message translates to:
  /// **'Phone verification'**
  String get loginOtpStepKicker;

  /// No description provided for @loginOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone verification'**
  String get loginOtpTitle;

  /// No description provided for @loginPasteOtp.
  ///
  /// In en, this message translates to:
  /// **'Paste code'**
  String get loginPasteOtp;

  /// No description provided for @loginPaymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get loginPaymentConfirm;

  /// No description provided for @loginPaymentConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment not confirmed yet. Check the PayPal tab and try again.'**
  String get loginPaymentConfirmFailed;

  /// No description provided for @loginPaymentOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'PayPal could not be opened right now.'**
  String get loginPaymentOpenFailed;

  /// No description provided for @loginPaymentOpened.
  ///
  /// In en, this message translates to:
  /// **'Done in PayPal? Return here and confirm.'**
  String get loginPaymentOpened;

  /// No description provided for @loginPaypal.
  ///
  /// In en, this message translates to:
  /// **'Open PayPal'**
  String get loginPaypal;

  /// No description provided for @loginPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your lawyer account was created and sent to the admin for review. You will be notified once approved.'**
  String get loginPendingBody;

  /// No description provided for @loginPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval pending'**
  String get loginPendingTitle;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0501234567 or 5XXXXXXXX'**
  String get loginPhoneHint;

  /// No description provided for @loginPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get loginPhoneLabel;

  /// No description provided for @loginProfileH2Login.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginProfileH2Login;

  /// No description provided for @loginProfileH2Register.
  ///
  /// In en, this message translates to:
  /// **'Let’s create your account'**
  String get loginProfileH2Register;

  /// No description provided for @loginProfileLedeLogin.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone to receive a one-time verification code.'**
  String get loginProfileLedeLogin;

  /// No description provided for @loginProfileLedeRegister.
  ///
  /// In en, this message translates to:
  /// **'We only need name and phone. Google signup is available too.'**
  String get loginProfileLedeRegister;

  /// No description provided for @loginProfileStepKicker.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get loginProfileStepKicker;

  /// No description provided for @loginProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get loginProfileTitle;

  /// No description provided for @loginRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get loginRegister;

  /// No description provided for @loginRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create your account. Please try again.'**
  String get loginRegisterFailed;

  /// No description provided for @loginRoleStepKicker.
  ///
  /// In en, this message translates to:
  /// **'Choose role'**
  String get loginRoleStepKicker;

  /// No description provided for @loginSecureFootnote.
  ///
  /// In en, this message translates to:
  /// **'🔒 Secured with end-to-end encryption'**
  String get loginSecureFootnote;

  /// No description provided for @loginSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get loginSendOtp;

  /// No description provided for @loginStepOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get loginStepOtp;

  /// No description provided for @loginStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get loginStepProfile;

  /// No description provided for @loginStepRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get loginStepRole;

  /// No description provided for @loginSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'A monthly membership is required. Emergency lawyer dispatch is billed only when you trigger a live event.'**
  String get loginSubscriptionBody;

  /// No description provided for @loginSubscriptionLine1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited legal AI'**
  String get loginSubscriptionLine1;

  /// No description provided for @loginSubscriptionLine2.
  ///
  /// In en, this message translates to:
  /// **'Access to scenarios, rights and evidence tools'**
  String get loginSubscriptionLine2;

  /// No description provided for @loginSubscriptionLine3.
  ///
  /// In en, this message translates to:
  /// **'Emergency lawyer dispatch billed separately'**
  String get loginSubscriptionLine3;

  /// No description provided for @loginSubscriptionPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly membership'**
  String get loginSubscriptionPlan;

  /// No description provided for @loginSubscriptionPrice.
  ///
  /// In en, this message translates to:
  /// **'₪19.90 / month'**
  String get loginSubscriptionPrice;

  /// No description provided for @loginSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate full VETO access'**
  String get loginSubscriptionTitle;

  /// No description provided for @loginSystemError.
  ///
  /// In en, this message translates to:
  /// **'A temporary error occurred. Please try again.'**
  String get loginSystemError;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'One access layer for every role'**
  String get loginTagline;

  /// No description provided for @loginUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get loginUnderstood;

  /// No description provided for @loginVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get loginVerify;

  /// No description provided for @adashActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adashActive;

  /// No description provided for @adashAllLawyers.
  ///
  /// In en, this message translates to:
  /// **'All Lawyers'**
  String get adashAllLawyers;

  /// No description provided for @adashAllUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get adashAllUsers;

  /// No description provided for @adashBackend.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get adashBackend;

  /// No description provided for @adashDb.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get adashDb;

  /// No description provided for @adashDispatchedStatus.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get adashDispatchedStatus;

  /// No description provided for @adashEmergencyLogs.
  ///
  /// In en, this message translates to:
  /// **'Emergency Logs'**
  String get adashEmergencyLogs;

  /// No description provided for @adashEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get adashEvents;

  /// No description provided for @adashEventsMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get adashEventsMonth;

  /// No description provided for @adashEventsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get adashEventsToday;

  /// No description provided for @adashEventsWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get adashEventsWeek;

  /// No description provided for @adashLawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyers'**
  String get adashLawyers;

  /// No description provided for @adashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get adashLoading;

  /// No description provided for @adashNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get adashNoActivity;

  /// No description provided for @adashOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get adashOffline;

  /// No description provided for @adashOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get adashOnline;

  /// No description provided for @adashOpenStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adashOpenStatus;

  /// No description provided for @adashPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get adashPending;

  /// No description provided for @adashPendingLawyers.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get adashPendingLawyers;

  /// No description provided for @adashQuickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get adashQuickLinks;

  /// No description provided for @adashRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get adashRecentActivity;

  /// No description provided for @adashRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get adashRefresh;

  /// No description provided for @adashResolvedStatus.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get adashResolvedStatus;

  /// No description provided for @adashSocket.
  ///
  /// In en, this message translates to:
  /// **'Socket'**
  String get adashSocket;

  /// No description provided for @adashSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get adashSubscriptions;

  /// No description provided for @adashSystemHealth.
  ///
  /// In en, this message translates to:
  /// **'System Health'**
  String get adashSystemHealth;

  /// No description provided for @adashTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adashTitle;

  /// No description provided for @adashUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get adashUnknown;

  /// No description provided for @adashUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adashUsers;

  /// No description provided for @admActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get admActive;

  /// No description provided for @admAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get admAdd;

  /// No description provided for @admAddLawyer.
  ///
  /// In en, this message translates to:
  /// **'Add lawyer'**
  String get admAddLawyer;

  /// No description provided for @admAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get admAddUser;

  /// No description provided for @admAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admAdmin;

  /// No description provided for @admAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin panel'**
  String get admAdminPanel;

  /// No description provided for @admAllLawyers.
  ///
  /// In en, this message translates to:
  /// **'All lawyers'**
  String get admAllLawyers;

  /// No description provided for @admAllUsers.
  ///
  /// In en, this message translates to:
  /// **'All users'**
  String get admAllUsers;

  /// No description provided for @admAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get admAppVersion;

  /// No description provided for @admApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get admApprove;

  /// No description provided for @admApproveError.
  ///
  /// In en, this message translates to:
  /// **'Approval failed'**
  String get admApproveError;

  /// No description provided for @admApproveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get admApproveSuccess;

  /// No description provided for @admAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get admAvailable;

  /// No description provided for @admAvailableForCalls.
  ///
  /// In en, this message translates to:
  /// **'Available for calls'**
  String get admAvailableForCalls;

  /// No description provided for @admBadgeActive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get admBadgeActive;

  /// No description provided for @admCacheReset.
  ///
  /// In en, this message translates to:
  /// **'Reset cache'**
  String get admCacheReset;

  /// No description provided for @admCacheResetSnack.
  ///
  /// In en, this message translates to:
  /// **'Cache reset requested (demo)'**
  String get admCacheResetSnack;

  /// No description provided for @admCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get admCancel;

  /// No description provided for @admChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get admChangeStatus;

  /// No description provided for @admCitizen.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get admCitizen;

  /// No description provided for @admCitizenApp.
  ///
  /// In en, this message translates to:
  /// **'Citizen app (VETO)'**
  String get admCitizenApp;

  /// No description provided for @admCommAgora.
  ///
  /// In en, this message translates to:
  /// **'Agora RTC'**
  String get admCommAgora;

  /// No description provided for @admCommFcm.
  ///
  /// In en, this message translates to:
  /// **'Firebase Cloud Messaging'**
  String get admCommFcm;

  /// No description provided for @admCommGemini.
  ///
  /// In en, this message translates to:
  /// **'Google Gemini'**
  String get admCommGemini;

  /// No description provided for @admCommTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication & integrations'**
  String get admCommTitle;

  /// No description provided for @admCommTwilio.
  ///
  /// In en, this message translates to:
  /// **'Twilio SMS / Voice'**
  String get admCommTwilio;

  /// No description provided for @admConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get admConnected;

  /// No description provided for @admDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get admDatabase;

  /// No description provided for @admDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get admDelete;

  /// No description provided for @admDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get admDeleteEvent;

  /// No description provided for @admDeleteEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this emergency record permanently?'**
  String get admDeleteEventConfirm;

  /// No description provided for @admDeleteLawyer.
  ///
  /// In en, this message translates to:
  /// **'Delete lawyer'**
  String get admDeleteLawyer;

  /// No description provided for @admDeleteLawyerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this lawyer permanently?'**
  String get admDeleteLawyerConfirm;

  /// No description provided for @admDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get admDeleteUser;

  /// No description provided for @admDeleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this user permanently? This cannot be undone.'**
  String get admDeleteUserConfirm;

  /// No description provided for @admDispatchMaxLawyers.
  ///
  /// In en, this message translates to:
  /// **'Max lawyers per call'**
  String get admDispatchMaxLawyers;

  /// No description provided for @admDispatchRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'Radius (km)'**
  String get admDispatchRadiusKm;

  /// No description provided for @admDispatchTimeoutSec.
  ///
  /// In en, this message translates to:
  /// **'Response timeout (seconds)'**
  String get admDispatchTimeoutSec;

  /// No description provided for @admDispatchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency dispatch'**
  String get admDispatchingTitle;

  /// No description provided for @admEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get admEdit;

  /// No description provided for @admEditLawyer.
  ///
  /// In en, this message translates to:
  /// **'Edit lawyer'**
  String get admEditLawyer;

  /// No description provided for @admEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get admEditUser;

  /// No description provided for @admEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get admEmail;

  /// No description provided for @admEmergencyLogs.
  ///
  /// In en, this message translates to:
  /// **'Emergency logs'**
  String get admEmergencyLogs;

  /// No description provided for @admExempt.
  ///
  /// In en, this message translates to:
  /// **'Exempt'**
  String get admExempt;

  /// No description provided for @admExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get admExperience;

  /// No description provided for @admExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get admExperienceYears;

  /// No description provided for @admFixedOtp.
  ///
  /// In en, this message translates to:
  /// **'Fixed OTP for admins'**
  String get admFixedOtp;

  /// No description provided for @admFixedOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Code 123456 for development and testing'**
  String get admFixedOtpHint;

  /// No description provided for @admFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get admFullName;

  /// No description provided for @admLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get admLanguage;

  /// No description provided for @admLawyerPrefix.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get admLawyerPrefix;

  /// No description provided for @admLawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyers'**
  String get admLawyers;

  /// No description provided for @admLicense.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get admLicense;

  /// No description provided for @admLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get admLoading;

  /// No description provided for @admLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get admLogout;

  /// No description provided for @admMaintenanceHint.
  ///
  /// In en, this message translates to:
  /// **'Shows maintenance screen to end users'**
  String get admMaintenanceHint;

  /// No description provided for @admMaintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode'**
  String get admMaintenanceMode;

  /// No description provided for @admMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get admMaintenanceTitle;

  /// No description provided for @admManualExempt.
  ///
  /// In en, this message translates to:
  /// **'Payment exempt (manually added)'**
  String get admManualExempt;

  /// No description provided for @admManualExemptHint.
  ///
  /// In en, this message translates to:
  /// **'This user will not need a subscription'**
  String get admManualExemptHint;

  /// No description provided for @admNoEmergencyEvents.
  ///
  /// In en, this message translates to:
  /// **'No emergency events'**
  String get admNoEmergencyEvents;

  /// No description provided for @admNoLawyers.
  ///
  /// In en, this message translates to:
  /// **'No lawyers found'**
  String get admNoLawyers;

  /// No description provided for @admNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get admNoName;

  /// No description provided for @admNoPendingLawyers.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get admNoPendingLawyers;

  /// No description provided for @admNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get admNoUsers;

  /// No description provided for @admOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get admOnline;

  /// No description provided for @admOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get admOpenApp;

  /// No description provided for @admPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get admPending;

  /// No description provided for @admPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Lawyers waiting for approval'**
  String get admPendingApprovals;

  /// No description provided for @admPendingApprovalsAction.
  ///
  /// In en, this message translates to:
  /// **'Review lawyer approvals'**
  String get admPendingApprovalsAction;

  /// No description provided for @admPendingLawyersTitle.
  ///
  /// In en, this message translates to:
  /// **'Lawyers pending approval'**
  String get admPendingLawyersTitle;

  /// No description provided for @admPendingSingle.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get admPendingSingle;

  /// No description provided for @admPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get admPendingStatus;

  /// No description provided for @admPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (+972...)'**
  String get admPhone;

  /// No description provided for @admQuickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick stats'**
  String get admQuickStats;

  /// No description provided for @admRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get admRefresh;

  /// No description provided for @admReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get admReject;

  /// No description provided for @admRejectError.
  ///
  /// In en, this message translates to:
  /// **'Rejection failed'**
  String get admRejectError;

  /// No description provided for @admRejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get admRejectRequest;

  /// No description provided for @admRejectRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject this request?'**
  String get admRejectRequestConfirm;

  /// No description provided for @admRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get admRejectSuccess;

  /// No description provided for @admResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get admResolved;

  /// No description provided for @admRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get admRole;

  /// No description provided for @admSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get admSave;

  /// No description provided for @admSaveLawyerFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save lawyer. Check phone format (+972...).'**
  String get admSaveLawyerFailed;

  /// No description provided for @admSaveUserFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save user. Check phone format (+972...).'**
  String get admSaveUserFailed;

  /// No description provided for @admServerStatus.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get admServerStatus;

  /// No description provided for @admSettingUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the setting'**
  String get admSettingUpdateError;

  /// No description provided for @admSettingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Setting updated successfully'**
  String get admSettingUpdated;

  /// No description provided for @admShellAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admShellAdmin;

  /// No description provided for @admShellAdminGroup.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get admShellAdminGroup;

  /// No description provided for @admShellDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get admShellDashboard;

  /// No description provided for @admShellEnvProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get admShellEnvProduction;

  /// No description provided for @admShellEnvStaging.
  ///
  /// In en, this message translates to:
  /// **'Staging'**
  String get admShellEnvStaging;

  /// No description provided for @admShellLawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyers'**
  String get admShellLawyers;

  /// No description provided for @admShellLogs.
  ///
  /// In en, this message translates to:
  /// **'Emergency Logs'**
  String get admShellLogs;

  /// No description provided for @admShellNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get admShellNotifications;

  /// No description provided for @admShellPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get admShellPanel;

  /// No description provided for @admShellPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get admShellPending;

  /// No description provided for @admShellRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get admShellRefresh;

  /// No description provided for @admShellSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search everywhere...'**
  String get admShellSearchHint;

  /// No description provided for @admShellSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get admShellSettings;

  /// No description provided for @admShellSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get admShellSubscriptions;

  /// No description provided for @admShellSystemGroup.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get admShellSystemGroup;

  /// No description provided for @admShellUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get admShellUsers;

  /// No description provided for @admSpecializations.
  ///
  /// In en, this message translates to:
  /// **'Specializations (comma separated)'**
  String get admSpecializations;

  /// No description provided for @admSpecializationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get admSpecializationsLabel;

  /// No description provided for @admStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get admStatusAccepted;

  /// No description provided for @admStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get admStatusCancelled;

  /// No description provided for @admStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get admStatusCompleted;

  /// No description provided for @admStatusDispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatching'**
  String get admStatusDispatching;

  /// No description provided for @admStatusDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get admStatusDocumentation;

  /// No description provided for @admStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get admStatusFailed;

  /// No description provided for @admStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get admStatusInProgress;

  /// No description provided for @admSystemOverview.
  ///
  /// In en, this message translates to:
  /// **'System overview'**
  String get admSystemOverview;

  /// No description provided for @admSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'System settings'**
  String get admSystemSettings;

  /// No description provided for @admUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get admUnavailable;

  /// No description provided for @admUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get admUnknown;

  /// No description provided for @admUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get admUnverified;

  /// No description provided for @admUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get admUserManagement;

  /// No description provided for @admUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get admUsers;

  /// No description provided for @admVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get admVerified;

  /// No description provided for @subAdmAccountEnabled.
  ///
  /// In en, this message translates to:
  /// **'Account active'**
  String get subAdmAccountEnabled;

  /// No description provided for @subAdmActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get subAdmActions;

  /// No description provided for @subAdmActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get subAdmActivate;

  /// No description provided for @subAdmActive.
  ///
  /// In en, this message translates to:
  /// **'Active Subscribers'**
  String get subAdmActive;

  /// No description provided for @subAdmAllTime.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get subAdmAllTime;

  /// No description provided for @subAdmAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get subAdmAmount;

  /// No description provided for @subAdmArpu.
  ///
  /// In en, this message translates to:
  /// **'ARPU'**
  String get subAdmArpu;

  /// No description provided for @subAdmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get subAdmCancel;

  /// No description provided for @subAdmCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subAdmCancelled;

  /// No description provided for @subAdmClearExpiry.
  ///
  /// In en, this message translates to:
  /// **'Clear expiry'**
  String get subAdmClearExpiry;

  /// No description provided for @subAdmConfirmActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate this subscription?'**
  String get subAdmConfirmActivate;

  /// No description provided for @subAdmConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel this subscription?'**
  String get subAdmConfirmCancel;

  /// No description provided for @subAdmConfirmDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete this user permanently? This cannot be undone.'**
  String get subAdmConfirmDeleteUser;

  /// No description provided for @subAdmConfirmExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend by 30 days?'**
  String get subAdmConfirmExtend;

  /// No description provided for @subAdmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get subAdmDelete;

  /// No description provided for @subAdmDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get subAdmDeleted;

  /// No description provided for @subAdmEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get subAdmEdit;

  /// No description provided for @subAdmEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get subAdmEmailLabel;

  /// No description provided for @subAdmEndDate.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get subAdmEndDate;

  /// No description provided for @subAdmErrorSave.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get subAdmErrorSave;

  /// No description provided for @subAdmExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subAdmExpired;

  /// No description provided for @subAdmExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend 30d'**
  String get subAdmExtend;

  /// No description provided for @subAdmFreeTier.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subAdmFreeTier;

  /// No description provided for @subAdmFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get subAdmFullName;

  /// No description provided for @subAdmLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get subAdmLoading;

  /// No description provided for @subAdmLogFail.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get subAdmLogFail;

  /// No description provided for @subAdmLogGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Login'**
  String get subAdmLogGoogle;

  /// No description provided for @subAdmLogGoogleFail.
  ///
  /// In en, this message translates to:
  /// **'Google Failed'**
  String get subAdmLogGoogleFail;

  /// No description provided for @subAdmLogOtpFail.
  ///
  /// In en, this message translates to:
  /// **'OTP Failed'**
  String get subAdmLogOtpFail;

  /// No description provided for @subAdmLogOtpOk.
  ///
  /// In en, this message translates to:
  /// **'OTP Verified'**
  String get subAdmLogOtpOk;

  /// No description provided for @subAdmLogOtpReq.
  ///
  /// In en, this message translates to:
  /// **'OTP Request'**
  String get subAdmLogOtpReq;

  /// No description provided for @subAdmLogRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get subAdmLogRegister;

  /// No description provided for @subAdmLogSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get subAdmLogSuccess;

  /// No description provided for @subAdmManualExempt.
  ///
  /// In en, this message translates to:
  /// **'Manual exempt (admin)'**
  String get subAdmManualExempt;

  /// No description provided for @subAdmMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get subAdmMonthly;

  /// No description provided for @subAdmMrrBadge.
  ///
  /// In en, this message translates to:
  /// **'MRR'**
  String get subAdmMrrBadge;

  /// No description provided for @subAdmNewPlan.
  ///
  /// In en, this message translates to:
  /// **'+ New plan'**
  String get subAdmNewPlan;

  /// No description provided for @subAdmNewPlanHint.
  ///
  /// In en, this message translates to:
  /// **'New plan creation — coming soon'**
  String get subAdmNewPlanHint;

  /// No description provided for @subAdmNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get subAdmNo;

  /// No description provided for @subAdmNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs'**
  String get subAdmNoLogs;

  /// No description provided for @subAdmNoSubs.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get subAdmNoSubs;

  /// No description provided for @subAdmPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get subAdmPhoneLabel;

  /// No description provided for @subAdmPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get subAdmPlan;

  /// No description provided for @subAdmPlanBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get subAdmPlanBasic;

  /// No description provided for @subAdmPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subAdmPlanFree;

  /// No description provided for @subAdmPlanNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get subAdmPlanNone;

  /// No description provided for @subAdmPlanPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get subAdmPlanPro;

  /// No description provided for @subAdmPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get subAdmPlansTitle;

  /// No description provided for @subAdmPremiumMonthly.
  ///
  /// In en, this message translates to:
  /// **'Premium monthly'**
  String get subAdmPremiumMonthly;

  /// No description provided for @subAdmPremiumYearly.
  ///
  /// In en, this message translates to:
  /// **'Premium yearly'**
  String get subAdmPremiumYearly;

  /// No description provided for @subAdmRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get subAdmRefresh;

  /// No description provided for @subAdmRenewalsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Renewals this month'**
  String get subAdmRenewalsThisMonth;

  /// No description provided for @subAdmRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get subAdmRetry;

  /// No description provided for @subAdmRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get subAdmRevenue;

  /// No description provided for @subAdmSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get subAdmSave;

  /// No description provided for @subAdmSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name/email/phone'**
  String get subAdmSearch;

  /// No description provided for @subAdmStartDate.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get subAdmStartDate;

  /// No description provided for @subAdmStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get subAdmStatus;

  /// No description provided for @subAdmStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subAdmStatusActive;

  /// No description provided for @subAdmStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subAdmStatusCancelled;

  /// No description provided for @subAdmStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subAdmStatusExpired;

  /// No description provided for @subAdmStatusFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subAdmStatusFree;

  /// No description provided for @subAdmStatusNoSub.
  ///
  /// In en, this message translates to:
  /// **'No Subscription'**
  String get subAdmStatusNoSub;

  /// No description provided for @subAdmStatusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get subAdmStatusTrial;

  /// No description provided for @subAdmStatusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get subAdmStatusUnverified;

  /// No description provided for @subAdmSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get subAdmSubscribed;

  /// No description provided for @subAdmSubscriptionExpiry.
  ///
  /// In en, this message translates to:
  /// **'Subscription expiry'**
  String get subAdmSubscriptionExpiry;

  /// No description provided for @subAdmTabLogs.
  ///
  /// In en, this message translates to:
  /// **'Login Logs'**
  String get subAdmTabLogs;

  /// No description provided for @subAdmTabUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get subAdmTabUsers;

  /// No description provided for @subAdmTitle.
  ///
  /// In en, this message translates to:
  /// **'Users & Subscriptions'**
  String get subAdmTitle;

  /// No description provided for @subAdmTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get subAdmTotal;

  /// No description provided for @subAdmUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get subAdmUpdated;

  /// No description provided for @subAdmUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get subAdmUser;

  /// No description provided for @subAdmYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get subAdmYes;

  /// No description provided for @chatScrTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get chatScrTitle;

  /// No description provided for @chatScrNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get chatScrNewChat;

  /// No description provided for @chatScrNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatScrNoConversations;

  /// No description provided for @chatScrTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatScrTypeMessage;

  /// No description provided for @chatScrSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatScrSend;

  /// No description provided for @chatScrToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatScrToday;

  /// No description provided for @chatScrYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatScrYesterday;

  /// No description provided for @chatScrLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chatScrLoadingMore;

  /// No description provided for @chatScrDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get chatScrDeleteMsg;

  /// No description provided for @chatScrYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatScrYou;

  /// No description provided for @chatScrSelectPartner.
  ///
  /// In en, this message translates to:
  /// **'Select a partner to chat with'**
  String get chatScrSelectPartner;

  /// No description provided for @chatScrNoPartners.
  ///
  /// In en, this message translates to:
  /// **'No available partners'**
  String get chatScrNoPartners;

  /// No description provided for @chatScrBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get chatScrBack;

  /// No description provided for @chatScrUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get chatScrUnread;

  /// No description provided for @chatScrDesktopStatus.
  ///
  /// In en, this message translates to:
  /// **'Active conversations · E2E encrypted'**
  String get chatScrDesktopStatus;

  /// No description provided for @callUiBadgeConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to a lawyer…'**
  String get callUiBadgeConnecting;

  /// No description provided for @callUiFindingLawyer.
  ///
  /// In en, this message translates to:
  /// **'Finding a criminal lawyer'**
  String get callUiFindingLawyer;

  /// No description provided for @callUiConnectingNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get callUiConnectingNearby;

  /// No description provided for @callUiConnectingDetails.
  ///
  /// In en, this message translates to:
  /// **'3 lawyers nearby received the request. Connecting to the first to respond.'**
  String get callUiConnectingDetails;

  /// No description provided for @callUiCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get callUiCancelRequest;

  /// No description provided for @callUiIncomingBadge.
  ///
  /// In en, this message translates to:
  /// **'Incoming emergency · LIVE'**
  String get callUiIncomingBadge;

  /// No description provided for @callUiIncomingUnknown.
  ///
  /// In en, this message translates to:
  /// **'Anonymous user'**
  String get callUiIncomingUnknown;

  /// No description provided for @callUiIncomingCaseDetails.
  ///
  /// In en, this message translates to:
  /// **'Case details'**
  String get callUiIncomingCaseDetails;

  /// No description provided for @callUiIncomingDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callUiIncomingDecline;

  /// No description provided for @callUiIncomingChatFirst.
  ///
  /// In en, this message translates to:
  /// **'Chat first'**
  String get callUiIncomingChatFirst;

  /// No description provided for @callUiIncomingAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get callUiIncomingAccept;

  /// No description provided for @callUiEncryptedBadge.
  ///
  /// In en, this message translates to:
  /// **'Encrypted call'**
  String get callUiEncryptedBadge;

  /// No description provided for @callUiConnectedEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Connected · encrypted call'**
  String get callUiConnectedEncrypted;

  /// No description provided for @callUiAes256Footer.
  ///
  /// In en, this message translates to:
  /// **'End-to-end · AES-256'**
  String get callUiAes256Footer;

  /// No description provided for @callUiRecordingShort.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get callUiRecordingShort;

  /// No description provided for @callUiRecordingPill.
  ///
  /// In en, this message translates to:
  /// **'Recording · saved to your encrypted vault'**
  String get callUiRecordingPill;

  /// No description provided for @callUiMuteMic.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get callUiMuteMic;

  /// No description provided for @callUiUnmuteMic.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get callUiUnmuteMic;

  /// No description provided for @callUiSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get callUiSpeaker;

  /// No description provided for @callUiCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get callUiCamera;

  /// No description provided for @callUiCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera off'**
  String get callUiCameraOff;

  /// No description provided for @callUiFlipCamera.
  ///
  /// In en, this message translates to:
  /// **'Flip camera'**
  String get callUiFlipCamera;

  /// No description provided for @callUiScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Share screen'**
  String get callUiScreenShare;

  /// No description provided for @callUiStopScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get callUiStopScreenShare;

  /// No description provided for @callUiNoiseSuppression.
  ///
  /// In en, this message translates to:
  /// **'Noise suppression'**
  String get callUiNoiseSuppression;

  /// No description provided for @callUiOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get callUiOpenChat;

  /// No description provided for @callUiEndCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get callUiEndCall;

  /// No description provided for @callUiWaitingForPeer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other side…'**
  String get callUiWaitingForPeer;

  /// No description provided for @callUiWaitingForPeerVideo.
  ///
  /// In en, this message translates to:
  /// **'Waiting for remote video…'**
  String get callUiWaitingForPeerVideo;

  /// No description provided for @callUiCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Your camera'**
  String get callUiCameraLabel;

  /// No description provided for @callUiCameraOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera is off'**
  String get callUiCameraOffLabel;

  /// No description provided for @callUiVoiceHeader.
  ///
  /// In en, this message translates to:
  /// **'Voice call · encrypted'**
  String get callUiVoiceHeader;

  /// No description provided for @callUiTabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get callUiTabChat;

  /// No description provided for @callUiTabCaption.
  ///
  /// In en, this message translates to:
  /// **'Live caption'**
  String get callUiTabCaption;

  /// No description provided for @callUiSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get callUiSendMessage;

  /// No description provided for @callUiMessagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get callUiMessagePlaceholder;

  /// No description provided for @callUiChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Type below.'**
  String get callUiChatEmpty;

  /// No description provided for @callUiCaptionWebNotice.
  ///
  /// In en, this message translates to:
  /// **'Live captions are mobile-only; the browser uses post-call server transcription.'**
  String get callUiCaptionWebNotice;

  /// No description provided for @callUiCaptionStart.
  ///
  /// In en, this message translates to:
  /// **'Start caption'**
  String get callUiCaptionStart;

  /// No description provided for @callUiCaptionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop caption'**
  String get callUiCaptionStop;

  /// No description provided for @callUiErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Call error'**
  String get callUiErrorTitle;

  /// No description provided for @callUiErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera / microphone permission denied. Allow access in browser or device settings and retry.'**
  String get callUiErrorPermission;

  /// No description provided for @callUiErrorTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid Agora token — refreshing and retrying.'**
  String get callUiErrorTokenInvalid;

  /// No description provided for @callUiErrorTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Token expired — renewing and reconnecting.'**
  String get callUiErrorTokenExpired;

  /// No description provided for @callUiErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Connection lost — attempting to recover.'**
  String get callUiErrorNetwork;

  /// No description provided for @callUiErrorMedia.
  ///
  /// In en, this message translates to:
  /// **'Media (camera/microphone) unavailable. You can continue in chat.'**
  String get callUiErrorMedia;

  /// No description provided for @callUiErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please rejoin the call.'**
  String get callUiErrorGeneric;

  /// No description provided for @callUiErrorUidConflict.
  ///
  /// In en, this message translates to:
  /// **'Duplicate user ID or join was rejected. Retry — if it persists, refresh the page.'**
  String get callUiErrorUidConflict;

  /// No description provided for @callUiWebStartCall.
  ///
  /// In en, this message translates to:
  /// **'Start video call'**
  String get callUiWebStartCall;

  /// No description provided for @callUiWebStartCallHint.
  ///
  /// In en, this message translates to:
  /// **'Browsers require a tap before camera and microphone can start.'**
  String get callUiWebStartCallHint;

  /// No description provided for @callUiWebInsecureContext.
  ///
  /// In en, this message translates to:
  /// **'Video calls need HTTPS (or localhost). Open the app on a secure URL.'**
  String get callUiWebInsecureContext;

  /// No description provided for @callUiErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get callUiErrorRetry;

  /// No description provided for @callUiErrorExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get callUiErrorExit;

  /// No description provided for @callUiVaultSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save to vault?'**
  String get callUiVaultSaveTitle;

  /// No description provided for @callUiVaultSaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what to save before closing.'**
  String get callUiVaultSaveSubtitle;

  /// No description provided for @callUiVaultSaveMediaOnly.
  ///
  /// In en, this message translates to:
  /// **'Save recording only (no transcription)'**
  String get callUiVaultSaveMediaOnly;

  /// No description provided for @callUiVaultSaveMediaAndTranscript.
  ///
  /// In en, this message translates to:
  /// **'Save recording + transcription (recommended)'**
  String get callUiVaultSaveMediaAndTranscript;

  /// No description provided for @callUiVaultSaveChatOnly.
  ///
  /// In en, this message translates to:
  /// **'Save chat only'**
  String get callUiVaultSaveChatOnly;

  /// No description provided for @callUiVaultSaveSkip.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get callUiVaultSaveSkip;

  /// No description provided for @callUiVaultWebNoLocalRecording.
  ///
  /// In en, this message translates to:
  /// **'Browser: with Agora Cloud Recording + S3 on the server, a full mixed recording is saved in the cloud (audio/video) with optional transcript. Otherwise only your local mic (WebM) is captured. Mobile: unchanged on-device Agora recording.'**
  String get callUiVaultWebNoLocalRecording;

  /// No description provided for @callUiVaultNothingToSave.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save (no recording or chat).'**
  String get callUiVaultNothingToSave;

  /// No description provided for @callUiQualityExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get callUiQualityExcellent;

  /// No description provided for @callUiQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get callUiQualityGood;

  /// No description provided for @callUiQualityFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get callUiQualityFair;

  /// No description provided for @callUiQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get callUiQualityPoor;

  /// No description provided for @callUiQualityVeryPoor.
  ///
  /// In en, this message translates to:
  /// **'Very poor'**
  String get callUiQualityVeryPoor;

  /// No description provided for @callUiLeaveCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave call?'**
  String get callUiLeaveCallTitle;

  /// No description provided for @callUiLeaveCallBody.
  ///
  /// In en, this message translates to:
  /// **'The session will end for both sides.'**
  String get callUiLeaveCallBody;

  /// No description provided for @vaultScrTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Vault'**
  String get vaultScrTitle;

  /// No description provided for @vaultScrUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get vaultScrUpload;

  /// No description provided for @vaultScrUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get vaultScrUploading;

  /// No description provided for @vaultScrAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'AI analyzing...'**
  String get vaultScrAnalyzing;

  /// No description provided for @vaultScrDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this file?'**
  String get vaultScrDeleteConfirm;

  /// No description provided for @vaultScrDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get vaultScrDelete;

  /// No description provided for @vaultScrShare.
  ///
  /// In en, this message translates to:
  /// **'Share with Lawyer'**
  String get vaultScrShare;

  /// No description provided for @vaultScrRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke Access'**
  String get vaultScrRevoke;

  /// No description provided for @vaultScrAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze with AI'**
  String get vaultScrAnalyze;

  /// No description provided for @vaultScrNoFiles.
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get vaultScrNoFiles;

  /// No description provided for @vaultScrUsageOf.
  ///
  /// In en, this message translates to:
  /// **'Used: '**
  String get vaultScrUsageOf;

  /// No description provided for @vaultScrUsedGb.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get vaultScrUsedGb;

  /// No description provided for @vaultScrQuotaSuffix.
  ///
  /// In en, this message translates to:
  /// **' / 10 GB'**
  String get vaultScrQuotaSuffix;

  /// No description provided for @vaultScrLegalCase.
  ///
  /// In en, this message translates to:
  /// **'Legal Case'**
  String get vaultScrLegalCase;

  /// No description provided for @vaultScrCaseName.
  ///
  /// In en, this message translates to:
  /// **'Case name'**
  String get vaultScrCaseName;

  /// No description provided for @vaultScrCreateCase.
  ///
  /// In en, this message translates to:
  /// **'Create Case'**
  String get vaultScrCreateCase;

  /// No description provided for @vaultScrAddToCase.
  ///
  /// In en, this message translates to:
  /// **'Add to Case'**
  String get vaultScrAddToCase;

  /// No description provided for @vaultScrFiles.
  ///
  /// In en, this message translates to:
  /// **'files'**
  String get vaultScrFiles;

  /// No description provided for @vaultScrAllFiles.
  ///
  /// In en, this message translates to:
  /// **'All Files'**
  String get vaultScrAllFiles;

  /// No description provided for @vaultScrCaseFiles.
  ///
  /// In en, this message translates to:
  /// **'Case Files'**
  String get vaultScrCaseFiles;

  /// No description provided for @vaultScrShareWithLawyer.
  ///
  /// In en, this message translates to:
  /// **'Share with Lawyer'**
  String get vaultScrShareWithLawyer;

  /// No description provided for @vaultScrLawyerAccess.
  ///
  /// In en, this message translates to:
  /// **'Lawyer Access'**
  String get vaultScrLawyerAccess;

  /// No description provided for @vaultScrFileType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get vaultScrFileType;

  /// No description provided for @vaultScrSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get vaultScrSize;

  /// No description provided for @vaultScrDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get vaultScrDate;

  /// No description provided for @vaultScrStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get vaultScrStatus;

  /// No description provided for @vaultScrAiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI Summary'**
  String get vaultScrAiSummary;

  /// No description provided for @vaultScrAiBtn.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get vaultScrAiBtn;

  /// No description provided for @vaultScrCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vaultScrCancel;

  /// No description provided for @vaultScrSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get vaultScrSave;

  /// No description provided for @vaultScrErrorUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get vaultScrErrorUpload;

  /// No description provided for @vaultScrSuccessUpload.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully'**
  String get vaultScrSuccessUpload;

  /// No description provided for @vaultScrSuccessDelete.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get vaultScrSuccessDelete;

  /// No description provided for @vaultScrSuccessShare.
  ///
  /// In en, this message translates to:
  /// **'Access updated'**
  String get vaultScrSuccessShare;

  /// No description provided for @vaultScrCompressing.
  ///
  /// In en, this message translates to:
  /// **'Compressing...'**
  String get vaultScrCompressing;

  /// No description provided for @vaultScrCaseCreated.
  ///
  /// In en, this message translates to:
  /// **'Case created'**
  String get vaultScrCaseCreated;

  /// No description provided for @vaultScrLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get vaultScrLoading;

  /// No description provided for @vaultScrRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get vaultScrRename;

  /// No description provided for @vaultScrFileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get vaultScrFileName;

  /// No description provided for @vaultScrSuccessRename.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get vaultScrSuccessRename;

  /// No description provided for @vaultScrDeleteCase.
  ///
  /// In en, this message translates to:
  /// **'Delete Case'**
  String get vaultScrDeleteCase;

  /// No description provided for @vaultScrDeleteCaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this case? Files will remain in your vault.'**
  String get vaultScrDeleteCaseConfirm;

  /// No description provided for @vaultScrSuccessDeleteCase.
  ///
  /// In en, this message translates to:
  /// **'Case deleted'**
  String get vaultScrSuccessDeleteCase;

  /// No description provided for @vaultScrRemoveFromCase.
  ///
  /// In en, this message translates to:
  /// **'Remove from Case'**
  String get vaultScrRemoveFromCase;

  /// No description provided for @vaultScrFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get vaultScrFolders;

  /// No description provided for @vaultScrNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get vaultScrNewFolder;

  /// No description provided for @vaultScrFolderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get vaultScrFolderName;

  /// No description provided for @vaultScrMoveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get vaultScrMoveToFolder;

  /// No description provided for @vaultScrRootVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vaultScrRootVault;

  /// No description provided for @vaultScrDeleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get vaultScrDeleteFolder;

  /// No description provided for @vaultScrDeleteFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this folder? (only if empty)'**
  String get vaultScrDeleteFolderConfirm;

  /// No description provided for @vaultScrFolderNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder is not empty'**
  String get vaultScrFolderNotEmpty;

  /// No description provided for @vaultScrGoUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get vaultScrGoUp;

  /// No description provided for @vaultScrOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get vaultScrOpenFolder;

  /// No description provided for @vaultScrDropFilesHere.
  ///
  /// In en, this message translates to:
  /// **'Drop to upload'**
  String get vaultScrDropFilesHere;

  /// No description provided for @vaultScrUploadZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick upload'**
  String get vaultScrUploadZoneTitle;

  /// No description provided for @vaultScrUploadZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile: use Upload or camera. Web: drag files here or anywhere on the page.'**
  String get vaultScrUploadZoneHint;

  /// No description provided for @vaultScrSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get vaultScrSearchTooltip;

  /// No description provided for @vaultScrDesktopStatus.
  ///
  /// In en, this message translates to:
  /// **'Secured · E2E encrypted · stored on-device & in encrypted vault'**
  String get vaultScrDesktopStatus;

  /// No description provided for @vaultScrCaptureCamera.
  ///
  /// In en, this message translates to:
  /// **'Capture from camera'**
  String get vaultScrCaptureCamera;

  /// No description provided for @vaultScrRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get vaultScrRefresh;

  /// No description provided for @vaultScrQuotaExceededSnack.
  ///
  /// In en, this message translates to:
  /// **'Vault storage quota exceeded.'**
  String get vaultScrQuotaExceededSnack;

  /// No description provided for @vaultScrQuotaFileTooLargeSnack.
  ///
  /// In en, this message translates to:
  /// **'Not enough free vault space for this file (max 100MB per upload).'**
  String get vaultScrQuotaFileTooLargeSnack;

  /// No description provided for @vaultScrUpgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade plan'**
  String get vaultScrUpgradePlan;

  /// No description provided for @vaultScrStorageUsedLine.
  ///
  /// In en, this message translates to:
  /// **'{used} GB of {quota} GB used'**
  String vaultScrStorageUsedLine(String used, String quota);

  /// No description provided for @vaultScrStorageSubLine.
  ///
  /// In en, this message translates to:
  /// **'{count} files · AES-256 per-file encryption'**
  String vaultScrStorageSubLine(int count);

  /// No description provided for @vaultScrHeroKicker.
  ///
  /// In en, this message translates to:
  /// **'Secured · E2E Encrypted'**
  String get vaultScrHeroKicker;

  /// No description provided for @vaultScrHeroSubline.
  ///
  /// In en, this message translates to:
  /// **'{count} files · {used} GB of {quota} GB · stored only on your device and in your encrypted vault'**
  String vaultScrHeroSubline(int count, String used, String quota);

  /// No description provided for @vaultScrTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vaultScrTabAll;

  /// No description provided for @vaultScrTabDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get vaultScrTabDocuments;

  /// No description provided for @vaultScrTabAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get vaultScrTabAudio;

  /// No description provided for @vaultScrTabVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get vaultScrTabVideo;

  /// No description provided for @vaultScrTabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get vaultScrTabPhotos;

  /// No description provided for @vaultScrCasesSectionKicker.
  ///
  /// In en, this message translates to:
  /// **'Case files'**
  String get vaultScrCasesSectionKicker;

  /// No description provided for @vaultScrLegalCasesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal cases'**
  String get vaultScrLegalCasesSectionTitle;

  /// No description provided for @vaultScrPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get vaultScrPreview;

  /// No description provided for @vaultScrMoreFilesCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String vaultScrMoreFilesCount(int count);

  /// No description provided for @vaultScrReloginNoAccess.
  ///
  /// In en, this message translates to:
  /// **'Sign in again (or no access to this file)'**
  String get vaultScrReloginNoAccess;

  /// No description provided for @vaultScrBadgeCallRecording.
  ///
  /// In en, this message translates to:
  /// **'Call recording'**
  String get vaultScrBadgeCallRecording;

  /// No description provided for @vaultScrBadgeGpsSigned.
  ///
  /// In en, this message translates to:
  /// **'GPS tagged'**
  String get vaultScrBadgeGpsSigned;

  /// No description provided for @vaultScrBadgeSignedPdf.
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get vaultScrBadgeSignedPdf;

  /// No description provided for @vaultScrTimeAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{n} months ago'**
  String vaultScrTimeAgoMonths(int n);

  /// No description provided for @vaultScrTimeAgoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{n} weeks ago'**
  String vaultScrTimeAgoWeeks(int n);

  /// No description provided for @vaultScrTimeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days ago'**
  String vaultScrTimeAgoDays(int n);

  /// No description provided for @vaultScrTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get vaultScrTimeYesterday;

  /// No description provided for @vaultScrTimeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{n} hours ago'**
  String vaultScrTimeAgoHours(int n);

  /// No description provided for @vaultScrTimeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String vaultScrTimeAgoMinutes(int n);

  /// No description provided for @vaultScrTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get vaultScrTimeJustNow;

  /// No description provided for @calScrTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal calendar'**
  String get calScrTitle;

  /// No description provided for @calScrMonthTab.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calScrMonthTab;

  /// No description provided for @calScrWeekTab.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calScrWeekTab;

  /// No description provided for @calScrAgendaTab.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get calScrAgendaTab;

  /// No description provided for @calScrToolbarRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get calScrToolbarRefresh;

  /// No description provided for @calScrPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get calScrPrev;

  /// No description provided for @calScrNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get calScrNext;

  /// No description provided for @calScrAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get calScrAddEvent;

  /// No description provided for @calScrNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get calScrNoEvents;

  /// No description provided for @calScrIcalTitle.
  ///
  /// In en, this message translates to:
  /// **'iCal (sync)'**
  String get calScrIcalTitle;

  /// No description provided for @calScrCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get calScrCopyUrl;

  /// No description provided for @calScrCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get calScrCopied;

  /// No description provided for @calScrGoogleOutlookHint.
  ///
  /// In en, this message translates to:
  /// **'Paste into Google Calendar → Settings → Add calendar → From URL, or Outlook Subscribe.'**
  String get calScrGoogleOutlookHint;

  /// No description provided for @calScrGcalTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar sync'**
  String get calScrGcalTitle;

  /// No description provided for @calScrGcalConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get calScrGcalConnect;

  /// No description provided for @calScrGcalDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get calScrGcalDisconnect;

  /// No description provided for @calScrGcalConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get calScrGcalConnected;

  /// No description provided for @calScrGcalNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google sync not configured on server.'**
  String get calScrGcalNotConfigured;

  /// No description provided for @calScrTypeHearing.
  ///
  /// In en, this message translates to:
  /// **'Hearing'**
  String get calScrTypeHearing;

  /// No description provided for @calScrTypeMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get calScrTypeMeeting;

  /// No description provided for @calScrTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get calScrTypeOther;

  /// No description provided for @calScrNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get calScrNewEvent;

  /// No description provided for @calScrEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get calScrEditEvent;

  /// No description provided for @calScrTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get calScrTitleField;

  /// No description provided for @calScrTypeField.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get calScrTypeField;

  /// No description provided for @calScrAddressField.
  ///
  /// In en, this message translates to:
  /// **'Address (maps)'**
  String get calScrAddressField;

  /// No description provided for @calScrNotesField.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get calScrNotesField;

  /// No description provided for @calScrReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get calScrReminders;

  /// No description provided for @calScrLinkCase.
  ///
  /// In en, this message translates to:
  /// **'Vault case'**
  String get calScrLinkCase;

  /// No description provided for @calScrNoCase.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get calScrNoCase;

  /// No description provided for @calScrStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get calScrStart;

  /// No description provided for @calScrEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get calScrEnd;

  /// No description provided for @calScrConfirmDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete this event?'**
  String get calScrConfirmDeleteEvent;

  /// No description provided for @calScrGenericError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get calScrGenericError;

  /// No description provided for @mapsScrTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get mapsScrTitle;

  /// No description provided for @sharedVaultFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get sharedVaultFallbackTitle;

  /// No description provided for @sharedVaultNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents shared.'**
  String get sharedVaultNoDocuments;

  /// No description provided for @sharedVaultUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get sharedVaultUntitled;

  /// No description provided for @legalDocPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalDocPrivacyTitle;

  /// No description provided for @legalDocTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalDocTermsTitle;

  /// No description provided for @nbScrTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal notebook'**
  String get nbScrTitle;

  /// No description provided for @nbScrDesktopStatus.
  ///
  /// In en, this message translates to:
  /// **'Legal notebook · VETO'**
  String get nbScrDesktopStatus;

  /// No description provided for @nbScrNewNotebook.
  ///
  /// In en, this message translates to:
  /// **'New notebook'**
  String get nbScrNewNotebook;

  /// No description provided for @nbScrNotebookShort.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get nbScrNotebookShort;

  /// No description provided for @nbScrRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get nbScrRefreshTooltip;

  /// No description provided for @nbScrSyncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get nbScrSyncTooltip;

  /// No description provided for @nbScrOpenBrowserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get nbScrOpenBrowserTooltip;

  /// No description provided for @nbScrExportPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get nbScrExportPdfTooltip;

  /// No description provided for @nbScrExportDocxTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export DOCX'**
  String get nbScrExportDocxTooltip;

  /// No description provided for @nbScrEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get nbScrEdit;

  /// No description provided for @nbScrSyncOkTesting.
  ///
  /// In en, this message translates to:
  /// **'Sync completed (API check)'**
  String get nbScrSyncOkTesting;

  /// No description provided for @nbScrSyncFallback.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get nbScrSyncFallback;

  /// No description provided for @nbScrExportPdfOk.
  ///
  /// In en, this message translates to:
  /// **'PDF exported successfully'**
  String get nbScrExportPdfOk;

  /// No description provided for @nbScrExportDocxOk.
  ///
  /// In en, this message translates to:
  /// **'DOCX exported successfully'**
  String get nbScrExportDocxOk;

  /// No description provided for @nbScrExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get nbScrExportFailed;

  /// No description provided for @nbScrDefaultNotebookName.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get nbScrDefaultNotebookName;

  /// No description provided for @nbScrIntentContractReview.
  ///
  /// In en, this message translates to:
  /// **'AI contract review'**
  String get nbScrIntentContractReview;

  /// No description provided for @nbScrIntentDemandLetter.
  ///
  /// In en, this message translates to:
  /// **'Demand letter draft'**
  String get nbScrIntentDemandLetter;

  /// No description provided for @nbScrIntentCivilClaim.
  ///
  /// In en, this message translates to:
  /// **'Civil claim draft'**
  String get nbScrIntentCivilClaim;

  /// No description provided for @nbScrIntentLaborDoc.
  ///
  /// In en, this message translates to:
  /// **'Labor law document'**
  String get nbScrIntentLaborDoc;

  /// No description provided for @nbScrIntentFamilyDoc.
  ///
  /// In en, this message translates to:
  /// **'Family law document'**
  String get nbScrIntentFamilyDoc;

  /// No description provided for @nbScrIntentBanner.
  ///
  /// In en, this message translates to:
  /// **'Selected flow: {intent} ({domain}) — create a new notebook to begin.'**
  String nbScrIntentBanner(String intent, String domain);

  /// No description provided for @nbEdScrChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Chat failed'**
  String get nbEdScrChatFailed;

  /// No description provided for @nbEdScrAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get nbEdScrAddSource;

  /// No description provided for @nbEdScrSegText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get nbEdScrSegText;

  /// No description provided for @nbEdScrSegUrl.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get nbEdScrSegUrl;

  /// No description provided for @nbEdScrSegVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get nbEdScrSegVault;

  /// No description provided for @nbEdScrOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get nbEdScrOptionalTitle;

  /// No description provided for @nbEdScrContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get nbEdScrContent;

  /// No description provided for @nbEdScrNoVaultFiles.
  ///
  /// In en, this message translates to:
  /// **'No files in vault'**
  String get nbEdScrNoVaultFiles;

  /// No description provided for @nbEdScrPickFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get nbEdScrPickFile;

  /// No description provided for @nbEdScrAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get nbEdScrAdd;

  /// No description provided for @nbEdScrLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get nbEdScrLoadingTitle;

  /// No description provided for @nbEdScrNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get nbEdScrNotFound;

  /// No description provided for @nbEdScrNameHint.
  ///
  /// In en, this message translates to:
  /// **'Notebook name'**
  String get nbEdScrNameHint;

  /// No description provided for @nbEdScrTabEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get nbEdScrTabEditor;

  /// No description provided for @nbEdScrTabSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get nbEdScrTabSources;

  /// No description provided for @nbEdScrTabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get nbEdScrTabChat;

  /// No description provided for @nbEdScrNewSource.
  ///
  /// In en, this message translates to:
  /// **'New source'**
  String get nbEdScrNewSource;

  /// No description provided for @nbEdScrNoSources.
  ///
  /// In en, this message translates to:
  /// **'No sources'**
  String get nbEdScrNoSources;

  /// No description provided for @nbEdScrStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String nbEdScrStatusLine(String status);

  /// No description provided for @nbEdScrChatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask using your sources…'**
  String get nbEdScrChatPlaceholder;

  /// No description provided for @nbScrIntentDomainFallback.
  ///
  /// In en, this message translates to:
  /// **'general'**
  String get nbScrIntentDomainFallback;

  /// No description provided for @nbEdScrMarkdownHint.
  ///
  /// In en, this message translates to:
  /// **'# Markdown\n\nWrite notes…'**
  String get nbEdScrMarkdownHint;

  /// No description provided for @nbEdScrUrlField.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get nbEdScrUrlField;

  /// No description provided for @vetoChatAssistantGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m the VETO legal assistant.\nDescribe your legal issue and I\'ll find you an available lawyer.'**
  String get vetoChatAssistantGreeting;

  /// No description provided for @vetoChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue...'**
  String get vetoChatInputHint;

  /// No description provided for @vetoChatProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get vetoChatProcessing;

  /// No description provided for @vetoChatDispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatching...'**
  String get vetoChatDispatching;

  /// No description provided for @vetoWizardTooltipHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get vetoWizardTooltipHome;

  /// No description provided for @vetoWizardTooltipLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get vetoWizardTooltipLanguage;

  /// No description provided for @vetoWizardAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'VETO — Legal Shield'**
  String get vetoWizardAppBarTitle;

  /// No description provided for @vetoSnackLocationCopied.
  ///
  /// In en, this message translates to:
  /// **'Location link copied to clipboard'**
  String get vetoSnackLocationCopied;

  /// No description provided for @vetoGeminiLiveBannerActive.
  ///
  /// In en, this message translates to:
  /// **'Gemini Live · session active'**
  String get vetoGeminiLiveBannerActive;

  /// No description provided for @vetoGeminiLiveTooltipAudioSettings.
  ///
  /// In en, this message translates to:
  /// **'Live voice & volume'**
  String get vetoGeminiLiveTooltipAudioSettings;

  /// No description provided for @vetoGeminiLiveInputHint.
  ///
  /// In en, this message translates to:
  /// **'Gemini Live voice — tap the mic again to stop'**
  String get vetoGeminiLiveInputHint;

  /// No description provided for @vetoLangSelfName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get vetoLangSelfName;

  /// No description provided for @vetoSnackAdminEmergencyUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get vetoSnackAdminEmergencyUpdateFailed;

  /// No description provided for @vetoUiAdminEmergencyCleaningTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get vetoUiAdminEmergencyCleaningTitle;

  /// No description provided for @vetoUiAdminEmergencyClearEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove attached evidence only'**
  String get vetoUiAdminEmergencyClearEvidenceLabel;

  /// No description provided for @vetoSnackAdminEmergencyEvidenceCleared.
  ///
  /// In en, this message translates to:
  /// **'Evidence cleared'**
  String get vetoSnackAdminEmergencyEvidenceCleared;

  /// No description provided for @vetoSnackAdminEmergencyClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Clear failed'**
  String get vetoSnackAdminEmergencyClearFailed;

  /// No description provided for @vetoSnackAdminEmergencyDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get vetoSnackAdminEmergencyDeleteFailed;

  /// No description provided for @vetoSnackDispatchNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection.'**
  String get vetoSnackDispatchNoConnection;

  /// No description provided for @vetoDispatchSearchingLawyer.
  ///
  /// In en, this message translates to:
  /// **'Searching {specLabel} lawyer...\n{lawyerName} will contact you.'**
  String vetoDispatchSearchingLawyer(String specLabel, String lawyerName);

  /// No description provided for @vetoDispatchSearchingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Searching for an available lawyer...'**
  String get vetoDispatchSearchingGeneric;

  /// No description provided for @vetoSnackGeminiLiveDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Voice session disconnected. Tap the mic to try again.'**
  String get vetoSnackGeminiLiveDisconnected;

  /// No description provided for @vetoSnackVoiceInputUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available in this browser.'**
  String get vetoSnackVoiceInputUnavailable;

  /// No description provided for @vetoVoiceHistoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'(voice)'**
  String get vetoVoiceHistoryPlaceholder;

  /// No description provided for @vetoPeerNameLawyer.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get vetoPeerNameLawyer;

  /// No description provided for @vetoDispatchBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Request broadcast. Lawyers notified: {count}.'**
  String vetoDispatchBroadcast(int count);

  /// No description provided for @vetoDispatchNoLawyers.
  ///
  /// In en, this message translates to:
  /// **'No lawyers are currently available.'**
  String get vetoDispatchNoLawyers;

  /// No description provided for @vetoDispatchFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Dispatch failed. Please try again.'**
  String get vetoDispatchFailedRetry;

  /// No description provided for @vetoDispatchCaseTaken.
  ///
  /// In en, this message translates to:
  /// **'Another lawyer has already taken this case.'**
  String get vetoDispatchCaseTaken;

  /// No description provided for @vetoEvidenceSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to capture evidence'**
  String get vetoEvidenceSignInRequired;

  /// No description provided for @vetoEvidenceSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start evidence session ({code})'**
  String vetoEvidenceSessionFailed(int code);

  /// No description provided for @vetoEvidenceNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error starting evidence'**
  String get vetoEvidenceNetworkError;

  /// No description provided for @vetoUiBackToHomeWizard.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get vetoUiBackToHomeWizard;

  /// No description provided for @vetoUiDesktopStatusLine.
  ///
  /// In en, this message translates to:
  /// **'Connected · ready · average response 3:21'**
  String get vetoUiDesktopStatusLine;

  /// No description provided for @vetoUiFileVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'File Vault'**
  String get vetoUiFileVaultTitle;

  /// No description provided for @vetoUiFileVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Store and manage all your evidence files'**
  String get vetoUiFileVaultSubtitle;

  /// No description provided for @vetoUiOpenFileVault.
  ///
  /// In en, this message translates to:
  /// **'Open File Vault'**
  String get vetoUiOpenFileVault;

  /// No description provided for @vetoUiManageProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage Profile'**
  String get vetoUiManageProfile;

  /// No description provided for @vetoUiProfileCta.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get vetoUiProfileCta;

  /// No description provided for @vetoUiProfileTabTitleGuest.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get vetoUiProfileTabTitleGuest;

  /// No description provided for @vetoUiNotebookEnterprise.
  ///
  /// In en, this message translates to:
  /// **'Notebook (Enterprise)'**
  String get vetoUiNotebookEnterprise;

  /// No description provided for @vetoUiScenarioHeading.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get vetoUiScenarioHeading;

  /// No description provided for @vetoUiScenarioPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the situation you are in right now'**
  String get vetoUiScenarioPickTitle;

  /// No description provided for @vetoUiScenarioPickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will tailor rights, guidance, and counsel type to your choice.'**
  String get vetoUiScenarioPickSubtitle;

  /// No description provided for @vetoUiStatusDispatching.
  ///
  /// In en, this message translates to:
  /// **'Connected · Dispatching'**
  String get vetoUiStatusDispatching;

  /// No description provided for @vetoUiStatusStandby.
  ///
  /// In en, this message translates to:
  /// **'Connected · Standby'**
  String get vetoUiStatusStandby;

  /// No description provided for @vetoSnackSttBrowserUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Your browser does not support speech recognition'**
  String get vetoSnackSttBrowserUnsupported;

  /// No description provided for @vetoUiAdminTooltip.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get vetoUiAdminTooltip;

  /// No description provided for @vetoUiHamburgerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get vetoUiHamburgerHome;

  /// No description provided for @vetoUiHeroLawyerOnWay.
  ///
  /// In en, this message translates to:
  /// **'A lawyer is on the way...'**
  String get vetoUiHeroLawyerOnWay;

  /// No description provided for @vetoUiHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'VETO · Immediate legal help'**
  String get vetoUiHeroEyebrow;

  /// No description provided for @vetoUiHeroBodyDesktop.
  ///
  /// In en, this message translates to:
  /// **'Tap SOS — a specialist criminal lawyer reaches you in minutes: voice or video, full call logging, encrypted vault backup, and evidence stays in your hands only.'**
  String get vetoUiHeroBodyDesktop;

  /// No description provided for @vetoUiHeroBodyMobile.
  ///
  /// In en, this message translates to:
  /// **'Tap SOS — a lawyer connects within minutes. Encrypted call log and vault backup.'**
  String get vetoUiHeroBodyMobile;

  /// No description provided for @vetoUiHeroHeadlineDesktop.
  ///
  /// In en, this message translates to:
  /// **'When the first minute decides\neverything else.'**
  String get vetoUiHeroHeadlineDesktop;

  /// No description provided for @vetoUiHeroHeadlineMobile.
  ///
  /// In en, this message translates to:
  /// **'A lawyer on your side — in minutes.'**
  String get vetoUiHeroHeadlineMobile;

  /// No description provided for @vetoUiHeroTrustPill1.
  ///
  /// In en, this message translates to:
  /// **'Full call logging'**
  String get vetoUiHeroTrustPill1;

  /// No description provided for @vetoUiHeroTrustPill2.
  ///
  /// In en, this message translates to:
  /// **'E2E encrypted vault'**
  String get vetoUiHeroTrustPill2;

  /// No description provided for @vetoUiHeroTrustPill3.
  ///
  /// In en, this message translates to:
  /// **'Available 24/7'**
  String get vetoUiHeroTrustPill3;

  /// No description provided for @vetoUiSosSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to dispatch a lawyer'**
  String get vetoUiSosSemanticLabel;

  /// No description provided for @vetoUiSosOrbEmergencyCaption.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY'**
  String get vetoUiSosOrbEmergencyCaption;

  /// No description provided for @vetoUiSosSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get vetoUiSosSearching;

  /// No description provided for @vetoUiScenarioCriticalLabel.
  ///
  /// In en, this message translates to:
  /// **'Critical time:'**
  String get vetoUiScenarioCriticalLabel;

  /// No description provided for @vetoUiScenarioLabelKnow.
  ///
  /// In en, this message translates to:
  /// **'What to know first'**
  String get vetoUiScenarioLabelKnow;

  /// No description provided for @vetoUiScenarioLabelAction.
  ///
  /// In en, this message translates to:
  /// **'First action'**
  String get vetoUiScenarioLabelAction;

  /// No description provided for @vetoUiDispatchBanner.
  ///
  /// In en, this message translates to:
  /// **'🚨 Dispatching — searching for a lawyer...'**
  String get vetoUiDispatchBanner;

  /// No description provided for @vetoUiCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vetoUiCancel;

  /// No description provided for @vetoUiAdminNoEvidenceAttached.
  ///
  /// In en, this message translates to:
  /// **'No evidence attached'**
  String get vetoUiAdminNoEvidenceAttached;

  /// No description provided for @vetoChatLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get vetoChatLocationTooltip;

  /// No description provided for @vetoUiRightsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Rights — {scenario}'**
  String vetoUiRightsCardTitle(String scenario);

  /// No description provided for @vetoUiReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get vetoUiReadMore;

  /// No description provided for @vetoChatQuickTools.
  ///
  /// In en, this message translates to:
  /// **'Quick tools'**
  String get vetoChatQuickTools;

  /// No description provided for @vetoChatToolCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get vetoChatToolCamera;

  /// No description provided for @vetoChatToolMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get vetoChatToolMute;

  /// No description provided for @vetoContactShareBody.
  ///
  /// In en, this message translates to:
  /// **'Hello, I need urgent legal assistance regarding: {scenario}. Please contact me immediately.'**
  String vetoContactShareBody(String scenario);

  /// No description provided for @vetoContactVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get vetoContactVideoTitle;

  /// No description provided for @vetoContactFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get vetoContactFieldPhone;

  /// No description provided for @vetoContactFieldCallLink.
  ///
  /// In en, this message translates to:
  /// **'Call link'**
  String get vetoContactFieldCallLink;

  /// No description provided for @vetoContactOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get vetoContactOpen;

  /// No description provided for @vetoContactIsraelShortcut.
  ///
  /// In en, this message translates to:
  /// **'▼ Israel +972...'**
  String get vetoContactIsraelShortcut;

  /// No description provided for @vetoContactLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get vetoContactLinkOpenFailed;

  /// No description provided for @vetoPayPalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with PayPal'**
  String get vetoPayPalDialogTitle;

  /// No description provided for @vetoPayPalProductLine.
  ///
  /// In en, this message translates to:
  /// **'15-minute lawyer consultation'**
  String get vetoPayPalProductLine;

  /// No description provided for @vetoPayPalPriceLine.
  ///
  /// In en, this message translates to:
  /// **'₪50 (≈ \$13.90 USD) — one-time charge'**
  String get vetoPayPalPriceLine;

  /// No description provided for @vetoPayPalNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Cannot be cancelled after payment.'**
  String get vetoPayPalNonRefundable;

  /// No description provided for @vetoPayPalPayButton.
  ///
  /// In en, this message translates to:
  /// **'Pay with PayPal'**
  String get vetoPayPalPayButton;

  /// No description provided for @vetoPayPalPayButtonLoading.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get vetoPayPalPayButtonLoading;

  /// No description provided for @vetoPayPalOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create PayPal order. Try again.'**
  String get vetoPayPalOrderFailed;

  /// No description provided for @vetoPayCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get vetoPayCaptureTitle;

  /// No description provided for @vetoPayCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'PayPal opened in a new tab.\nAfter you approve payment there — return here and tap \"I paid\".'**
  String get vetoPayCaptureBody;

  /// No description provided for @vetoPayCapturePaidButton.
  ///
  /// In en, this message translates to:
  /// **'I paid ✓'**
  String get vetoPayCapturePaidButton;

  /// No description provided for @vetoPayCaptureError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String vetoPayCaptureError(String message);

  /// No description provided for @vetoPayCaptureIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Payment was not completed. Try again after approving in PayPal.'**
  String get vetoPayCaptureIncomplete;

  /// No description provided for @vetoPaySubGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription required'**
  String get vetoPaySubGateTitle;

  /// No description provided for @vetoPaySubGateBody.
  ///
  /// In en, this message translates to:
  /// **'Using VETO requires an active monthly subscription.'**
  String get vetoPaySubGateBody;

  /// No description provided for @vetoPaySubGateBlockNote.
  ///
  /// In en, this message translates to:
  /// **'Without an active subscription you cannot use the platform.'**
  String get vetoPaySubGateBlockNote;

  /// No description provided for @vetoPaySubPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly subscription'**
  String get vetoPaySubPlanTitle;

  /// No description provided for @vetoPaySubPriceLine.
  ///
  /// In en, this message translates to:
  /// **'₪19.90 / month (USD \$5.50)'**
  String get vetoPaySubPriceLine;

  /// No description provided for @vetoPaySubFeatureAi.
  ///
  /// In en, this message translates to:
  /// **'Unlimited legal AI guidance'**
  String get vetoPaySubFeatureAi;

  /// No description provided for @vetoPaySubFeatureLawyer.
  ///
  /// In en, this message translates to:
  /// **'Emergency lawyer dispatch (+ ₪50)'**
  String get vetoPaySubFeatureLawyer;

  /// No description provided for @vetoPaySubPaymentDeclined.
  ///
  /// In en, this message translates to:
  /// **'Payment was not approved.'**
  String get vetoPaySubPaymentDeclined;

  /// No description provided for @citizenHubWelcomeName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String citizenHubWelcomeName(String name);

  /// No description provided for @citizenHubWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart legal protection in one place.'**
  String get citizenHubWelcomeSubtitle;

  /// No description provided for @citizenHubSendVetoCta.
  ///
  /// In en, this message translates to:
  /// **'Send VETO'**
  String get citizenHubSendVetoCta;

  /// No description provided for @citizenHubLegalShieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal shield'**
  String get citizenHubLegalShieldTitle;

  /// No description provided for @citizenHubShieldRiskCheck.
  ///
  /// In en, this message translates to:
  /// **'Instant risk check'**
  String get citizenHubShieldRiskCheck;

  /// No description provided for @citizenHubShieldDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines & reminders'**
  String get citizenHubShieldDeadlines;

  /// No description provided for @citizenHubShieldCourtMap.
  ///
  /// In en, this message translates to:
  /// **'Court & station map'**
  String get citizenHubShieldCourtMap;

  /// No description provided for @citizenHubShieldManageContracts.
  ///
  /// In en, this message translates to:
  /// **'Manage contracts'**
  String get citizenHubShieldManageContracts;

  /// No description provided for @citizenHubShieldLegalTasks.
  ///
  /// In en, this message translates to:
  /// **'Legal task list'**
  String get citizenHubShieldLegalTasks;

  /// No description provided for @citizenHubShieldCaseReport.
  ///
  /// In en, this message translates to:
  /// **'Case status report'**
  String get citizenHubShieldCaseReport;

  /// No description provided for @citizenHubShieldVaultExport.
  ///
  /// In en, this message translates to:
  /// **'Export to vault'**
  String get citizenHubShieldVaultExport;

  /// No description provided for @citizenHubToolCaseTracking.
  ///
  /// In en, this message translates to:
  /// **'Case tracking'**
  String get citizenHubToolCaseTracking;

  /// No description provided for @citizenHubToolContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get citizenHubToolContracts;

  /// No description provided for @citizenHubToolOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get citizenHubToolOpenTasks;

  /// No description provided for @citizenHubToolContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get citizenHubToolContacts;

  /// No description provided for @citizenHubToolReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get citizenHubToolReports;

  /// No description provided for @citizenHubToolAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get citizenHubToolAdvanced;

  /// No description provided for @citizenHubMetricOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get citizenHubMetricOpenTasks;

  /// No description provided for @citizenHubMetricTrackedCases.
  ///
  /// In en, this message translates to:
  /// **'Tracked cases'**
  String get citizenHubMetricTrackedCases;

  /// No description provided for @citizenHubMetricActiveContracts.
  ///
  /// In en, this message translates to:
  /// **'Active contracts'**
  String get citizenHubMetricActiveContracts;

  /// No description provided for @citizenHubQuickSummary.
  ///
  /// In en, this message translates to:
  /// **'Quick summary'**
  String get citizenHubQuickSummary;

  /// No description provided for @wizOnbRoleCitizenTitle.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get wizOnbRoleCitizenTitle;

  /// No description provided for @wizOnbRoleCitizenDesc.
  ///
  /// In en, this message translates to:
  /// **'Instant legal defense and SOS button'**
  String get wizOnbRoleCitizenDesc;

  /// No description provided for @wizOnbRoleLawyerTitle.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get wizOnbRoleLawyerTitle;

  /// No description provided for @wizOnbRoleLawyerDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive cases from VETO in real time'**
  String get wizOnbRoleLawyerDesc;

  /// No description provided for @wizOnbScnPoliceTitle.
  ///
  /// In en, this message translates to:
  /// **'Police investigation'**
  String get wizOnbScnPoliceTitle;

  /// No description provided for @wizOnbScnPoliceDesc.
  ///
  /// In en, this message translates to:
  /// **'Summons, caution, initial arrest'**
  String get wizOnbScnPoliceDesc;

  /// No description provided for @wizOnbScnTrafficTitle.
  ///
  /// In en, this message translates to:
  /// **'Traffic stop'**
  String get wizOnbScnTrafficTitle;

  /// No description provided for @wizOnbScnTrafficDesc.
  ///
  /// In en, this message translates to:
  /// **'Speed, alcohol, license check'**
  String get wizOnbScnTrafficDesc;

  /// No description provided for @wizOnbScnCivilTitle.
  ///
  /// In en, this message translates to:
  /// **'Civil dispute'**
  String get wizOnbScnCivilTitle;

  /// No description provided for @wizOnbScnCivilDesc.
  ///
  /// In en, this message translates to:
  /// **'Contract, real estate, tort'**
  String get wizOnbScnCivilDesc;

  /// No description provided for @wizOnbScnLaborTitle.
  ///
  /// In en, this message translates to:
  /// **'Labor law'**
  String get wizOnbScnLaborTitle;

  /// No description provided for @wizOnbScnLaborDesc.
  ///
  /// In en, this message translates to:
  /// **'Dismissal, rights, harassment'**
  String get wizOnbScnLaborDesc;

  /// No description provided for @wizOnbScnFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family law'**
  String get wizOnbScnFamilyTitle;

  /// No description provided for @wizOnbScnFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'Divorce, custody, alimony'**
  String get wizOnbScnFamilyDesc;

  /// No description provided for @wizOnbScnConsumerTitle.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get wizOnbScnConsumerTitle;

  /// No description provided for @wizOnbScnConsumerDesc.
  ///
  /// In en, this message translates to:
  /// **'Refund, warranty, fraud'**
  String get wizOnbScnConsumerDesc;

  /// No description provided for @wizOnbAlertPushSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push + SMS'**
  String get wizOnbAlertPushSmsTitle;

  /// No description provided for @wizOnbAlertPushSmsDesc.
  ///
  /// In en, this message translates to:
  /// **'Won\'t miss a call — both channels combined'**
  String get wizOnbAlertPushSmsDesc;

  /// No description provided for @wizOnbAlertPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Push only'**
  String get wizOnbAlertPushTitle;

  /// No description provided for @wizOnbAlertPushDesc.
  ///
  /// In en, this message translates to:
  /// **'Single device notification'**
  String get wizOnbAlertPushDesc;

  /// No description provided for @wizOnbAlertSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS only'**
  String get wizOnbAlertSmsTitle;

  /// No description provided for @wizOnbAlertSmsDesc.
  ///
  /// In en, this message translates to:
  /// **'App-independent'**
  String get wizOnbAlertSmsDesc;

  /// No description provided for @wizOnbAlertCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto call'**
  String get wizOnbAlertCallTitle;

  /// No description provided for @wizOnbAlertCallDesc.
  ///
  /// In en, this message translates to:
  /// **'Emergency only — instant call'**
  String get wizOnbAlertCallDesc;

  /// No description provided for @wizOnbPrivAnonTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous to lawyer'**
  String get wizOnbPrivAnonTitle;

  /// No description provided for @wizOnbPrivAnonDesc.
  ///
  /// In en, this message translates to:
  /// **'Name revealed only on your approval'**
  String get wizOnbPrivAnonDesc;

  /// No description provided for @wizOnbPrivVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get wizOnbPrivVerifiedTitle;

  /// No description provided for @wizOnbPrivVerifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Name shown to lawyer from the start'**
  String get wizOnbPrivVerifiedDesc;

  /// No description provided for @wizOnbStepTitle1.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get wizOnbStepTitle1;

  /// No description provided for @wizOnbStepTitle2.
  ///
  /// In en, this message translates to:
  /// **'Main scenario'**
  String get wizOnbStepTitle2;

  /// No description provided for @wizOnbStepTitle3.
  ///
  /// In en, this message translates to:
  /// **'Alert preferences'**
  String get wizOnbStepTitle3;

  /// No description provided for @wizOnbStepTitle4.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get wizOnbStepTitle4;

  /// No description provided for @wizOnbStepSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Citizen or lawyer?'**
  String get wizOnbStepSubtitle1;

  /// No description provided for @wizOnbStepSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Which emergency type is most relevant?'**
  String get wizOnbStepSubtitle2;

  /// No description provided for @wizOnbStepSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'How should we reach you fast?'**
  String get wizOnbStepSubtitle3;

  /// No description provided for @wizOnbStepSubtitle4.
  ///
  /// In en, this message translates to:
  /// **'Who sees your data'**
  String get wizOnbStepSubtitle4;

  /// No description provided for @wizOnbSaveJustNow.
  ///
  /// In en, this message translates to:
  /// **'Auto-saved · just now'**
  String get wizOnbSaveJustNow;

  /// No description provided for @wizOnbSaveSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'Auto-saved · {seconds}s ago'**
  String wizOnbSaveSecondsAgo(int seconds);

  /// No description provided for @wizOnbRailBrandEm.
  ///
  /// In en, this message translates to:
  /// **'Wizard'**
  String get wizOnbRailBrandEm;

  /// No description provided for @wizOnbRailHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Let\'s prepare'**
  String get wizOnbRailHeadline1;

  /// No description provided for @wizOnbRailHeadlineBeforeEm.
  ///
  /// In en, this message translates to:
  /// **''**
  String get wizOnbRailHeadlineBeforeEm;

  /// No description provided for @wizOnbRailHeadline3.
  ///
  /// In en, this message translates to:
  /// **'just for you'**
  String get wizOnbRailHeadline3;

  /// No description provided for @wizOnbRailDescription.
  ///
  /// In en, this message translates to:
  /// **'4 short questions help us tailor the screen, alerts and response time — to what you need.'**
  String get wizOnbRailDescription;

  /// No description provided for @wizOnbSaveExit.
  ///
  /// In en, this message translates to:
  /// **'Save & exit'**
  String get wizOnbSaveExit;

  /// No description provided for @wizOnbBack.
  ///
  /// In en, this message translates to:
  /// **'← Back'**
  String get wizOnbBack;

  /// No description provided for @wizOnbContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get wizOnbContinue;

  /// No description provided for @wizOnbFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish →'**
  String get wizOnbFinish;

  /// No description provided for @wizOnbSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get wizOnbSelectedLabel;

  /// No description provided for @wizOnbQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {step} of {total}'**
  String wizOnbQuestionProgress(int step, int total);

  /// No description provided for @wizOnbNextHintPrefix.
  ///
  /// In en, this message translates to:
  /// **'Next: '**
  String get wizOnbNextHintPrefix;

  /// No description provided for @wizOnbQ1Head.
  ///
  /// In en, this message translates to:
  /// **'How will you use VETO?'**
  String get wizOnbQ1Head;

  /// No description provided for @wizOnbQ1Lede.
  ///
  /// In en, this message translates to:
  /// **'We tailor the UI to your role. You can change this later in settings.'**
  String get wizOnbQ1Lede;

  /// No description provided for @wizOnbQ2Head.
  ///
  /// In en, this message translates to:
  /// **'Which scenario is most relevant?'**
  String get wizOnbQ2Head;

  /// No description provided for @wizOnbQ2Lede.
  ///
  /// In en, this message translates to:
  /// **'Pick the scenario you expect most — we preload rights and route to the right lawyer. Change any time.'**
  String get wizOnbQ2Lede;

  /// No description provided for @wizOnbQ3Head.
  ///
  /// In en, this message translates to:
  /// **'How should we reach you fast?'**
  String get wizOnbQ3Head;

  /// No description provided for @wizOnbQ3Lede.
  ///
  /// In en, this message translates to:
  /// **'Pick how we should notify you of urgent events.'**
  String get wizOnbQ3Lede;

  /// No description provided for @wizOnbQ4Head.
  ///
  /// In en, this message translates to:
  /// **'Who sees your data?'**
  String get wizOnbQ4Head;

  /// No description provided for @wizOnbQ4Lede.
  ///
  /// In en, this message translates to:
  /// **'Choose the privacy level you want toward the on-duty lawyer.'**
  String get wizOnbQ4Lede;

  /// No description provided for @wizOnbCalloutScenario.
  ///
  /// In en, this message translates to:
  /// **'This affects only the main screen. All scenarios remain available — the SOS button doesn\'t distinguish between types.'**
  String get wizOnbCalloutScenario;

  /// No description provided for @wizOnbSumAllSet.
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get wizOnbSumAllSet;

  /// No description provided for @wizOnbSumSummaryLede.
  ///
  /// In en, this message translates to:
  /// **'Summary of your settings — change any time.'**
  String get wizOnbSumSummaryLede;

  /// No description provided for @wizOnbSumRolePrefix.
  ///
  /// In en, this message translates to:
  /// **'Role ·'**
  String get wizOnbSumRolePrefix;

  /// No description provided for @wizOnbSumRoleSub.
  ///
  /// In en, this message translates to:
  /// **'Your screen is tailored'**
  String get wizOnbSumRoleSub;

  /// No description provided for @wizOnbSumScenarioPrefix.
  ///
  /// In en, this message translates to:
  /// **'Scenario ·'**
  String get wizOnbSumScenarioPrefix;

  /// No description provided for @wizOnbSumScenarioSub.
  ///
  /// In en, this message translates to:
  /// **'Rights pre-loaded'**
  String get wizOnbSumScenarioSub;

  /// No description provided for @wizOnbSumAlertsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Alerts ·'**
  String get wizOnbSumAlertsPrefix;

  /// No description provided for @wizOnbSumAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Won\'t miss a call'**
  String get wizOnbSumAlertsSub;

  /// No description provided for @wizOnbSumPrivacyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Privacy ·'**
  String get wizOnbSumPrivacyPrefix;

  /// No description provided for @wizOnbSumPrivacySub.
  ///
  /// In en, this message translates to:
  /// **'Name shown only if you approve'**
  String get wizOnbSumPrivacySub;

  /// No description provided for @wizOnbSuccessHead.
  ///
  /// In en, this message translates to:
  /// **'VETO is ready.'**
  String get wizOnbSuccessHead;

  /// No description provided for @wizOnbSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your SOS button is active at all times.'**
  String get wizOnbSuccessBody;

  /// No description provided for @wizShellLawTitle1.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get wizShellLawTitle1;

  /// No description provided for @wizShellLawTitle2.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get wizShellLawTitle2;

  /// No description provided for @wizShellLawTitle3.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get wizShellLawTitle3;

  /// No description provided for @wizShellLawTitle4.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get wizShellLawTitle4;

  /// No description provided for @wizShellLawSub1.
  ///
  /// In en, this message translates to:
  /// **'Control incoming flow'**
  String get wizShellLawSub1;

  /// No description provided for @wizShellLawSub2.
  ///
  /// In en, this message translates to:
  /// **'Accept or decline'**
  String get wizShellLawSub2;

  /// No description provided for @wizShellLawSub3.
  ///
  /// In en, this message translates to:
  /// **'Active matter status'**
  String get wizShellLawSub3;

  /// No description provided for @wizShellLawSub4.
  ///
  /// In en, this message translates to:
  /// **'Profile & sign out'**
  String get wizShellLawSub4;

  /// No description provided for @wizShellUserTitle1.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get wizShellUserTitle1;

  /// No description provided for @wizShellUserTitle2.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get wizShellUserTitle2;

  /// No description provided for @wizShellUserTitle3.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get wizShellUserTitle3;

  /// No description provided for @wizShellUserTitle4.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get wizShellUserTitle4;

  /// No description provided for @wizShellUserSub1.
  ///
  /// In en, this message translates to:
  /// **'System readiness'**
  String get wizShellUserSub1;

  /// No description provided for @wizShellUserSub2.
  ///
  /// In en, this message translates to:
  /// **'One-tap emergency'**
  String get wizShellUserSub2;

  /// No description provided for @wizShellUserSub3.
  ///
  /// In en, this message translates to:
  /// **'Evidence workspace'**
  String get wizShellUserSub3;

  /// No description provided for @wizShellUserSub4.
  ///
  /// In en, this message translates to:
  /// **'Profile & sign out'**
  String get wizShellUserSub4;

  /// No description provided for @wizShellRailLawyerBrandEm.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get wizShellRailLawyerBrandEm;

  /// No description provided for @wizShellRailLawyerHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Your on-call'**
  String get wizShellRailLawyerHeadline1;

  /// No description provided for @wizShellRailLawyerBeforeEm.
  ///
  /// In en, this message translates to:
  /// **' '**
  String get wizShellRailLawyerBeforeEm;

  /// No description provided for @wizShellRailLawyerLine3.
  ///
  /// In en, this message translates to:
  /// **'desk'**
  String get wizShellRailLawyerLine3;

  /// No description provided for @wizShellRailLawyerDesc.
  ///
  /// In en, this message translates to:
  /// **'Four steps: availability, alerts, active case, and account.'**
  String get wizShellRailLawyerDesc;

  /// No description provided for @wizShellRailLawyerSaveStatus.
  ///
  /// In en, this message translates to:
  /// **'Connected · dispatch ready'**
  String get wizShellRailLawyerSaveStatus;

  /// No description provided for @wizShellRailLawyerSaveExit.
  ///
  /// In en, this message translates to:
  /// **'Save & exit'**
  String get wizShellRailLawyerSaveExit;

  /// No description provided for @wizShellRailUserBrandEm.
  ///
  /// In en, this message translates to:
  /// **'Wizard'**
  String get wizShellRailUserBrandEm;

  /// No description provided for @wizShellRailUserHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up'**
  String get wizShellRailUserHeadline1;

  /// No description provided for @wizShellRailUserBeforeEm.
  ///
  /// In en, this message translates to:
  /// **' '**
  String get wizShellRailUserBeforeEm;

  /// No description provided for @wizShellRailUserLine3.
  ///
  /// In en, this message translates to:
  /// **'just for you'**
  String get wizShellRailUserLine3;

  /// No description provided for @wizShellRailUserDesc.
  ///
  /// In en, this message translates to:
  /// **'Four guided steps: protection, emergency dispatch, tools, and account.'**
  String get wizShellRailUserDesc;

  /// No description provided for @wizShellRailUserSaveStatus.
  ///
  /// In en, this message translates to:
  /// **'Connected · system active'**
  String get wizShellRailUserSaveStatus;

  /// No description provided for @wizShellRailUserSaveExit.
  ///
  /// In en, this message translates to:
  /// **'Save & exit'**
  String get wizShellRailUserSaveExit;

  /// No description provided for @wizShellStepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of 4'**
  String wizShellStepOfTotal(int n);

  /// No description provided for @wizShellBadgeLawyer.
  ///
  /// In en, this message translates to:
  /// **'LAWYER'**
  String get wizShellBadgeLawyer;

  /// No description provided for @wizShellBadgeAdmin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get wizShellBadgeAdmin;

  /// No description provided for @wizShellBadgeUser.
  ///
  /// In en, this message translates to:
  /// **'USER'**
  String get wizShellBadgeUser;

  /// No description provided for @wizShellTooltipProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get wizShellTooltipProfile;

  /// No description provided for @wizShellTooltipAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get wizShellTooltipAdmin;

  /// No description provided for @wizShellTooltipLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get wizShellTooltipLogout;

  /// No description provided for @wizShellUserPanel1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1 | Protection status'**
  String get wizShellUserPanel1Title;

  /// No description provided for @wizShellUserPanel1Sub.
  ///
  /// In en, this message translates to:
  /// **'Quick view of your system status'**
  String get wizShellUserPanel1Sub;

  /// No description provided for @wizShellUserBadgeDispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatch active'**
  String get wizShellUserBadgeDispatching;

  /// No description provided for @wizShellUserBadgeProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get wizShellUserBadgeProtected;

  /// No description provided for @wizShellUserPanel1BusyBody.
  ///
  /// In en, this message translates to:
  /// **'A call is already in progress; the system is tracking lawyer responses.'**
  String get wizShellUserPanel1BusyBody;

  /// No description provided for @wizShellUserPanel1IdleBody.
  ///
  /// In en, this message translates to:
  /// **'Ready to activate. One tap starts a full emergency call.'**
  String get wizShellUserPanel1IdleBody;

  /// No description provided for @wizShellUserPanel2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2 | Emergency dispatch'**
  String get wizShellUserPanel2Title;

  /// No description provided for @wizShellUserPanel2Sub.
  ///
  /// In en, this message translates to:
  /// **'One button, one action, zero confusion'**
  String get wizShellUserPanel2Sub;

  /// No description provided for @wizShellUserDispatchCtaBusy.
  ///
  /// In en, this message translates to:
  /// **'Dispatching...'**
  String get wizShellUserDispatchCtaBusy;

  /// No description provided for @wizShellUserDispatchCta.
  ///
  /// In en, this message translates to:
  /// **'Activate VETO now'**
  String get wizShellUserDispatchCta;

  /// No description provided for @wizShellUserPanel3Title.
  ///
  /// In en, this message translates to:
  /// **'Step 3 | Evidence'**
  String get wizShellUserPanel3Title;

  /// No description provided for @wizShellUserPanel3Sub.
  ///
  /// In en, this message translates to:
  /// **'Quick access to the existing evidence screen'**
  String get wizShellUserPanel3Sub;

  /// No description provided for @wizShellUserOpenEmergency.
  ///
  /// In en, this message translates to:
  /// **'Open emergency workspace'**
  String get wizShellUserOpenEmergency;

  /// No description provided for @wizShellUserPanel4Title.
  ///
  /// In en, this message translates to:
  /// **'Step 4 | Account actions'**
  String get wizShellUserPanel4Title;

  /// No description provided for @wizShellUserPanel4Sub.
  ///
  /// In en, this message translates to:
  /// **'Profile, admin, and safe sign-out'**
  String get wizShellUserPanel4Sub;

  /// No description provided for @wizShellUserCtaProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get wizShellUserCtaProfile;

  /// No description provided for @wizShellUserCtaAdmin.
  ///
  /// In en, this message translates to:
  /// **'System admin'**
  String get wizShellUserCtaAdmin;

  /// No description provided for @wizShellUserCtaLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get wizShellUserCtaLogout;

  /// No description provided for @wizShellLawPanel1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1 | Availability'**
  String get wizShellLawPanel1Title;

  /// No description provided for @wizShellLawPanel1Sub.
  ///
  /// In en, this message translates to:
  /// **'Full control of incoming case flow'**
  String get wizShellLawPanel1Sub;

  /// No description provided for @wizShellLawAvailOn.
  ///
  /// In en, this message translates to:
  /// **'Available for calls'**
  String get wizShellLawAvailOn;

  /// No description provided for @wizShellLawAvailOff.
  ///
  /// In en, this message translates to:
  /// **'Unavailable right now'**
  String get wizShellLawAvailOff;

  /// No description provided for @wizShellLawAvailOnSub.
  ///
  /// In en, this message translates to:
  /// **'On-call active'**
  String get wizShellLawAvailOnSub;

  /// No description provided for @wizShellLawAvailOffSub.
  ///
  /// In en, this message translates to:
  /// **'Standby mode'**
  String get wizShellLawAvailOffSub;

  /// No description provided for @wizShellLawPanel2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2 | Active alerts'**
  String get wizShellLawPanel2Title;

  /// No description provided for @wizShellLawPanel2Sub.
  ///
  /// In en, this message translates to:
  /// **'Accept or decline cases with one tap'**
  String get wizShellLawPanel2Sub;

  /// No description provided for @wizShellLawNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts right now'**
  String get wizShellLawNoAlerts;

  /// No description provided for @wizShellLawCallNumber.
  ///
  /// In en, this message translates to:
  /// **'Call #{id}'**
  String wizShellLawCallNumber(String id);

  /// No description provided for @wizShellLawRejectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get wizShellLawRejectTooltip;

  /// No description provided for @wizShellLawAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get wizShellLawAccept;

  /// No description provided for @wizShellLawPanel3Title.
  ///
  /// In en, this message translates to:
  /// **'Step 3 | Case handling'**
  String get wizShellLawPanel3Title;

  /// No description provided for @wizShellLawPanel3Sub.
  ///
  /// In en, this message translates to:
  /// **'Automatically switches to busy after acceptance'**
  String get wizShellLawPanel3Sub;

  /// No description provided for @wizShellLawNoCase.
  ///
  /// In en, this message translates to:
  /// **'No active case right now'**
  String get wizShellLawNoCase;

  /// No description provided for @wizShellLawBusyCase.
  ///
  /// In en, this message translates to:
  /// **'Busy — case in progress'**
  String get wizShellLawBusyCase;

  /// No description provided for @wizShellLawPanel4Title.
  ///
  /// In en, this message translates to:
  /// **'Step 4 | Account actions'**
  String get wizShellLawPanel4Title;

  /// No description provided for @wizShellLawPanel4Sub.
  ///
  /// In en, this message translates to:
  /// **'Quick access to profile and admin tools'**
  String get wizShellLawPanel4Sub;

  /// No description provided for @loginFlowsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Flows: OK ({detail})'**
  String loginFlowsSuccess(String detail);

  /// No description provided for @loginFlowsFailed.
  ///
  /// In en, this message translates to:
  /// **'Flows: failed ({error})'**
  String loginFlowsFailed(String error);

  /// No description provided for @legalAiWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello, I\'m the VETO assistant. How can I help?'**
  String get legalAiWelcome;

  /// No description provided for @legalAiVoiceSocketClosed.
  ///
  /// In en, this message translates to:
  /// **'Voice connection ended. Tap the microphone again.'**
  String get legalAiVoiceSocketClosed;

  /// No description provided for @legalAiVoiceNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This browser does not support voice input.'**
  String get legalAiVoiceNotSupported;

  /// No description provided for @legalAiAudioError.
  ///
  /// In en, this message translates to:
  /// **'Audio error: {error}'**
  String legalAiAudioError(String error);

  /// No description provided for @legalAiVoiceWebOnly.
  ///
  /// In en, this message translates to:
  /// **'Voice chat is only available on web.'**
  String get legalAiVoiceWebOnly;

  /// No description provided for @legalAiSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first.'**
  String get legalAiSignInRequired;

  /// No description provided for @legalAiGeminiNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This browser or device does not support Gemini voice chat.'**
  String get legalAiGeminiNotSupported;

  /// No description provided for @legalAiNoReply.
  ///
  /// In en, this message translates to:
  /// **'No reply received yet.'**
  String get legalAiNoReply;

  /// No description provided for @legalAiTitle.
  ///
  /// In en, this message translates to:
  /// **'VETO Agent'**
  String get legalAiTitle;

  /// No description provided for @legalAiCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get legalAiCloseTooltip;

  /// No description provided for @legalAiLiveBanner.
  ///
  /// In en, this message translates to:
  /// **'Gemini Live is on — speak freely; audio streams in real time.'**
  String get legalAiLiveBanner;

  /// No description provided for @legalAiMicStopHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get legalAiMicStopHint;

  /// No description provided for @legalAiMicStartHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to start voice chat'**
  String get legalAiMicStartHint;

  /// No description provided for @legalAiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a legal question…'**
  String get legalAiInputHint;

  /// No description provided for @legalAiModeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get legalAiModeText;

  /// No description provided for @legalAiModeLive.
  ///
  /// In en, this message translates to:
  /// **'Live Audio'**
  String get legalAiModeLive;

  /// No description provided for @legalAiRouteLegalCalendar.
  ///
  /// In en, this message translates to:
  /// **'Legal calendar'**
  String get legalAiRouteLegalCalendar;

  /// No description provided for @legalAiRouteLegalNotebook.
  ///
  /// In en, this message translates to:
  /// **'Legal notebook'**
  String get legalAiRouteLegalNotebook;

  /// No description provided for @legalAiRouteFilesVault.
  ///
  /// In en, this message translates to:
  /// **'File vault'**
  String get legalAiRouteFilesVault;

  /// No description provided for @legalAiRouteCitizenContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get legalAiRouteCitizenContracts;

  /// No description provided for @legalAiRouteCitizenTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get legalAiRouteCitizenTasks;

  /// No description provided for @legalAiRouteCitizenContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get legalAiRouteCitizenContacts;

  /// No description provided for @legalAiRouteCitizenNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get legalAiRouteCitizenNotifications;

  /// No description provided for @legalAiRouteCitizenReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get legalAiRouteCitizenReports;

  /// No description provided for @legalAiRouteCitizenTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get legalAiRouteCitizenTools;

  /// No description provided for @legalAiRouteSecurityCenter.
  ///
  /// In en, this message translates to:
  /// **'Safety center'**
  String get legalAiRouteSecurityCenter;

  /// No description provided for @legalAiRouteAdminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get legalAiRouteAdminDashboard;

  /// No description provided for @legalAiRouteAdminUsers.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get legalAiRouteAdminUsers;

  /// No description provided for @legalAiRouteAdminLawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyer management'**
  String get legalAiRouteAdminLawyers;

  /// No description provided for @legalAiRouteAdminPending.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals'**
  String get legalAiRouteAdminPending;

  /// No description provided for @legalAiRouteAdminLogs.
  ///
  /// In en, this message translates to:
  /// **'Event log'**
  String get legalAiRouteAdminLogs;

  /// No description provided for @legalAiRouteAdminSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get legalAiRouteAdminSubscriptions;

  /// No description provided for @legalAiRouteAdminSettings.
  ///
  /// In en, this message translates to:
  /// **'System settings'**
  String get legalAiRouteAdminSettings;

  /// No description provided for @legalAiRouteLawyerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Lawyer dashboard'**
  String get legalAiRouteLawyerDashboard;

  /// No description provided for @legalAiRouteLawyerSettings.
  ///
  /// In en, this message translates to:
  /// **'Lawyer settings'**
  String get legalAiRouteLawyerSettings;

  /// No description provided for @legalAiRouteMaps.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get legalAiRouteMaps;

  /// No description provided for @legalAiRouteProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get legalAiRouteProfile;

  /// No description provided for @legalAiRouteSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get legalAiRouteSettings;

  /// No description provided for @legalAiRouteChat.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get legalAiRouteChat;

  /// No description provided for @legalAiRouteSharedVault.
  ///
  /// In en, this message translates to:
  /// **'Shared vault'**
  String get legalAiRouteSharedVault;

  /// No description provided for @legalAiRouteDefault.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get legalAiRouteDefault;
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
      <String>['en', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
