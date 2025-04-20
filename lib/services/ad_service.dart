import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  factory AdService() => _instance;

  AdService._internal();

  // For testing ads in development - using Google's test ad unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1236925949723418/3227961817'; // Production banner ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1236925949723418/3227961817'; // Production banner ad unit for iOS
    } else {
      return 'ca-app-pub-1236925949723418/3227961817'; // Production banner ad unit for other platforms
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1236925949723418/8354582839'; // Production interstitial ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1236925949723418/8354582839'; // Production interstitial ad unit for iOS
    } else {
      return 'ca-app-pub-1236925949723418/8354582839'; // Production interstitial ad unit for other platforms
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1236925949723418/1759494133'; // Production rewarded ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1236925949723418/1759494133'; // Production rewarded ad unit for iOS
    } else {
      return 'ca-app-pub-1236925949723418/1759494133'; // Production rewarded ad unit for other platforms
    }
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1236925949723418/7936748035'; // Production native ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test native ad unit for iOS
    } else {
      return kDebugMode ? 'ca-app-pub-3940256099942544/2934735716' : '';
    }
  }

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1236925949723418/2207050841'; // Production app open ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1236925949723418/2207050841'; // Production app open ad unit for iOS
    } else {
      return 'ca-app-pub-1236925949723418/2207050841'; // Production app open ad unit for other platforms
    }
  }

  // Initialize mobile ads SDK with production configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing AdMob...');

      // Initialize MobileAds with production configuration
      await MobileAds.instance.initialize();

      // Update request configuration
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          testDeviceIds: [
            'F6ZT4DHABUBEUCQ8',
          ], // Always use test device ID for testing
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );

      _isInitialized = true;
      debugPrint('AdMob initialized successfully with device as test device');

      // Pre-load ads after initialization
      await _preloadAds();
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
      _retryInitialization();
    }
  }

  void _retryInitialization() async {
    try {
      debugPrint('Retrying AdMob initialization...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully on retry');
      await _preloadAds();
    } catch (e) {
      debugPrint('Retry initialization also failed: $e');
    }
  }

  // Pre-load ads for better user experience
  Future<void> _preloadAds() async {
    try {
      debugPrint('Pre-loading all ads...');
      await Future.wait([
        _loadBannerAd(),
        _loadInterstitialAd(),
        _loadRewardedAd(),
      ]);
    } catch (e) {
      debugPrint('Error pre-loading ads: $e');
    }
  }

  // Load and maintain banner ad
  Future<void> _loadBannerAd() async {
    if (!_isInitialized) await initialize();

    if (bannerAdUnitId.isEmpty) {
      debugPrint('Banner ad unit ID is empty, not showing ads');
      return;
    }

    try {
      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            _bannerAd = ad as BannerAd;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            ad.dispose();
            _bannerAd = null;
            // Retry loading banner ad after delay
            Future.delayed(const Duration(seconds: 30), _loadBannerAd);
          },
          onAdOpened: (ad) => debugPrint('Banner ad opened'),
          onAdClosed: (ad) {
            debugPrint('Banner ad closed');
            // Reload banner ad when closed
            _loadBannerAd();
          },
          onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
        ),
      );

      await _bannerAd?.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      _bannerAd = null;
    }
  }

  // Get current banner ad
  BannerAd? get bannerAd => _bannerAd;

  // Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) await initialize();

    if (interstitialAdUnitId.isEmpty) {
      debugPrint('Interstitial ad unit ID is empty, not showing ads');
      return;
    }

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded successfully');
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            _isInterstitialAdReady = false;
            _interstitialAd = null;
            // Retry loading interstitial ad after delay
            Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _isInterstitialAdReady = false;
      _interstitialAd = null;
    }
  }

  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    if (!_isInitialized) await initialize();

    if (!_isInterstitialAdReady || _interstitialAd == null) {
      debugPrint('Interstitial ad not ready, loading new ad...');
      await _loadInterstitialAd();
      return false;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent:
            (ad) => debugPrint('Interstitial ad showed'),
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed');
          ad.dispose();
          _isInterstitialAdReady = false;
          _loadInterstitialAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Failed to show interstitial ad: $error');
          ad.dispose();
          _isInterstitialAdReady = false;
          _loadInterstitialAd(); // Retry loading
        },
      );

      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      return false;
    }
  }

  // Load rewarded ad
  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) await initialize();

    if (rewardedAdUnitId.isEmpty) {
      debugPrint('Rewarded ad unit ID is empty, not showing ads');
      return;
    }

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isRewardedAdReady = true;

            // Set full-screen callbacks
            _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent:
                  (ad) => debugPrint('Rewarded ad showed fullscreen'),
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Rewarded ad dismissed fullscreen');
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdReady = false;
                // Auto reload next ad
                _loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Rewarded ad failed to show fullscreen: $error');
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdReady = false;
                // Retry loading
                _loadRewardedAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
            _rewardedAd = null;
            _isRewardedAdReady = false;
            // Retry loading after delay
            Future.delayed(const Duration(seconds: 5), _loadRewardedAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      _rewardedAd = null;
      _isRewardedAdReady = false;
    }
  }

  // Public method to preload rewarded ad
  Future<void> preloadRewardedAd() async {
    if (!_isRewardedAdReady) {
      await _loadRewardedAd();
    }
  }

  // Show rewarded ad
  Future<bool> showRewardedAd() async {
    if (!_isInitialized) await initialize();

    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('Rewarded ad not ready, trying to load...');
      await _loadRewardedAd();
      // Wait a bit for the ad to load
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRewardedAdReady || _rewardedAd == null) {
        debugPrint('Failed to load rewarded ad');
        return false;
      }
    }

    try {
      Completer<bool> adCompleter = Completer<bool>();

      await _rewardedAd?.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          adCompleter.complete(true);
        },
      );

      _rewardedAd = null;
      _isRewardedAdReady = false;

      // Preload next ad
      _loadRewardedAd();

      return await adCompleter.future;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      _rewardedAd = null;
      _isRewardedAdReady = false;
      return false;
    }
  }

  // Check if we're on a supported platform for ads
  bool get isAdSupported => Platform.isAndroid || Platform.isIOS || kDebugMode;

  // Load a banner ad
  BannerAd? createBannerAd() {
    if (!_isInitialized) {
      // Try to initialize if not already done
      initialize().then(
        (_) => debugPrint('Initialized AdMob during banner ad creation'),
      );
      return null;
    }

    if (bannerAdUnitId.isEmpty) {
      debugPrint('Banner ad unit ID is empty, not showing ads');
      return null;
    }

    try {
      final ad = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => debugPrint('Banner ad loaded successfully'),
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            debugPrint('Banner ad failed to load: $error');
            debugPrint(
              'Error code: ${error.code}, message: ${error.message}, domain: ${error.domain}',
            );
          },
          onAdOpened: (ad) => debugPrint('Banner ad opened'),
          onAdClosed: (ad) => debugPrint('Banner ad closed'),
          onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
        ),
      );

      // Attempt to load the ad immediately
      ad.load();
      return ad;
    } catch (e) {
      debugPrint('Error creating banner ad: $e');
      return null;
    }
  }

  // Load and show an app open ad
  Future<void> loadAppOpenAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!isAdSupported || appOpenAdUnitId.isEmpty) {
      debugPrint('App open ads not supported or ad unit ID is empty');
      return;
    }

    try {
      await AppOpenAd.load(
        adUnitId: appOpenAdUnitId,
        orientation: AppOpenAd.orientationPortrait,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('App open ad loaded successfully');
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('App open ad showed successfully');
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Failed to show app open ad: $error');
                ad.dispose();
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('App open ad dismissed');
                ad.dispose();
              },
              onAdImpression: (ad) {
                debugPrint('App open ad impression recorded');
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (error) {
            debugPrint('App open ad failed to load: $error');
            debugPrint(
              'Error code: ${error.code}, message: ${error.message}, domain: ${error.domain}',
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading app open ad: $e');
    }
  }

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialAdReady = false;
    _isRewardedAdReady = false;
  }
}
