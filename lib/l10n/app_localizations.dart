import 'package:flutter/widgets.dart';

class AppLocalizations {
  final String locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations('ja');
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get(String key) => _strings[locale]?[key] ?? _strings['en']?[key] ?? key;

  // Convenience accessors
  String get appName => get('app_name');
  String get selectSettings => get('select_settings');
  String get brand => get('brand');
  String get plateShape => get('plate_shape');
  String get plateSize => get('plate_size');
  String get quality => get('quality');
  String get direct => get('direct');
  String get dither => get('dither');
  String get maxColors => get('max_colors');
  String get converting => get('converting');
  String get save => get('save');
  String get preview => get('preview');
  String get adjustColors => get('adjust_colors');
  String get pdfExport => get('pdf_export');
  String get shoppingList => get('shopping_list');
  String get share => get('share');
  String get gallery => get('gallery');
  String get settings => get('settings');
  String get premium => get('premium');
  String get premiumTitle => get('premium_title');
  String get premiumPrice => get('premium_price');
  String get restore => get('restore');
  String get solidOnly => get('solid_only');
  String get includePearl => get('include_pearl');
  String get allColors => get('all_colors');
  String get colorMode => get('color_mode');
  String get symbolMode => get('symbol_mode');
  String get numberMode => get('number_mode');
  String get total => get('total');
  String get pieces => get('pieces');
  String get colors => get('colors');
  String get sortByCount => get('sort_by_count');
  String get sortByName => get('sort_by_name');
  String get copyText => get('copy_text');
  String get noPatterns => get('no_patterns');
  String get deleteConfirm => get('delete_confirm');
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get defaultBrand => get('default_brand');
  String get removeIsolated => get('remove_isolated');
  String get darkMode => get('dark_mode');
  String get language => get('language');
  String get privacyPolicy => get('privacy_policy');
  String get termsOfUse => get('terms_of_use');
  String get contact => get('contact');
  String get version => get('version');
  String get dailyLimitReached => get('daily_limit_reached');
  String get premiumRequired => get('premium_required');
  String get disclaimer => get('disclaimer');
  String get ditherStrength => get('dither_strength');
  String get hintSmallDirect => get('hint_small_direct');
  String get hintLargeDither => get('hint_large_dither');
  String get unlimitedGen => get('unlimited_gen');
  String get multiPlate => get('multi_plate');
  String get customSize => get('custom_size');
  String get noWatermark => get('no_watermark');
  String get realSizePdf => get('real_size_pdf');
  String get hiResPdf => get('hi_res_pdf');
  String get purchaseBtn => get('purchase_btn');
  String get perler => get('perler');
  String get nano => get('nano');
  String get hama => get('hama');

  static const _strings = {
    'ja': {
      'app_name': 'beadot',
      'select_settings': 'SELECT SETTINGS',
      'brand': 'BRAND',
      'plate_shape': 'PLATE SHAPE',
      'plate_size': 'PLATE SIZE',
      'quality': 'QUALITY',
      'direct': 'DIRECT',
      'dither': 'DITHER',
      'max_colors': 'MAX COLORS',
      'converting': 'CONVERTING...',
      'save': '保存',
      'preview': '完成を見る',
      'adjust_colors': '色数調整',
      'pdf_export': 'PDF出力',
      'shopping_list': '買い物リスト',
      'share': 'シェア',
      'gallery': 'GALLERY',
      'settings': '設定',
      'premium': 'PREMIUM',
      'premium_title': 'PREMIUM',
      'premium_price': '¥500 で購入',
      'restore': '購入を復元',
      'solid_only': 'ソリッドのみ',
      'include_pearl': 'パール含む',
      'all_colors': '全色',
      'color_mode': 'COLOR',
      'symbol_mode': 'SYMBOL',
      'number_mode': 'NUMBER',
      'total': '合計',
      'pieces': '個',
      'colors': '色',
      'sort_by_count': '個数順',
      'sort_by_name': '色名順',
      'copy_text': 'テキストをコピー',
      'no_patterns': '図案がありません',
      'delete_confirm': 'この図案を削除しますか？',
      'cancel': 'キャンセル',
      'delete': '削除',
      'default_brand': 'デフォルトブランド',
      'remove_isolated': '孤立ピクセル除去',
      'dark_mode': 'ダークモード',
      'language': '言語',
      'privacy_policy': 'プライバシーポリシー',
      'terms_of_use': '利用規約',
      'contact': 'お問い合わせ',
      'version': 'バージョン',
      'daily_limit_reached': '本日の無料生成は終了しました\n明日またお試しください',
      'premium_required': 'プレミアム機能です',
      'disclaimer': '※ 本アプリはビーズメーカー各社の公式アプリではありません。色の再現は近似値であり、実際のビーズの色と異なる場合があります。',
      'dither_strength': '拡散強度',
      'hint_small_direct': 'S（15×15）ではダイレクトモードがおすすめ',
      'hint_large_dither': '29×29以上ではディザリングでグラデーションが自然に',
      'unlimited_gen': '1日の生成無制限',
      'multi_plate': '連結プレート対応（2L / 4L）',
      'custom_size': 'カスタムサイズ（最大128×128）',
      'no_watermark': '透かしなし',
      'real_size_pdf': '実寸PDF出力',
      'hi_res_pdf': '高解像度PDF出力',
      'purchase_btn': '¥500 で購入',
      'perler': 'パーラー',
      'nano': 'ナノ',
      'hama': 'ハマ',
    },
    'en': {
      'app_name': 'beadot',
      'select_settings': 'SELECT SETTINGS',
      'brand': 'BRAND',
      'plate_shape': 'PLATE SHAPE',
      'plate_size': 'PLATE SIZE',
      'quality': 'QUALITY',
      'direct': 'DIRECT',
      'dither': 'DITHER',
      'max_colors': 'MAX COLORS',
      'converting': 'CONVERTING...',
      'save': 'Save',
      'preview': 'Preview',
      'adjust_colors': 'Adjust Colors',
      'pdf_export': 'PDF Export',
      'shopping_list': 'Shopping List',
      'share': 'Share',
      'gallery': 'GALLERY',
      'settings': 'Settings',
      'premium': 'PREMIUM',
      'premium_title': 'PREMIUM',
      'premium_price': 'Buy for \$4.99',
      'restore': 'Restore Purchase',
      'solid_only': 'Solid Only',
      'include_pearl': 'Include Pearl',
      'all_colors': 'All Colors',
      'color_mode': 'COLOR',
      'symbol_mode': 'SYMBOL',
      'number_mode': 'NUMBER',
      'total': 'Total',
      'pieces': 'pcs',
      'colors': 'colors',
      'sort_by_count': 'By Count',
      'sort_by_name': 'By Name',
      'copy_text': 'Copy Text',
      'no_patterns': 'No patterns yet',
      'delete_confirm': 'Delete this pattern?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'default_brand': 'Default Brand',
      'remove_isolated': 'Remove Isolated Pixels',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'privacy_policy': 'Privacy Policy',
      'terms_of_use': 'Terms of Use',
      'contact': 'Contact',
      'version': 'Version',
      'daily_limit_reached': 'Daily free limit reached\nTry again tomorrow',
      'premium_required': 'Premium feature',
      'disclaimer': '※ This app is not affiliated with any bead manufacturer. Colors are approximations and may differ from actual beads.',
      'dither_strength': 'Diffusion Strength',
      'hint_small_direct': 'Direct mode recommended for S (15×15)',
      'hint_large_dither': 'Dithering makes gradients smoother at 29×29+',
      'unlimited_gen': 'Unlimited conversions',
      'multi_plate': 'Multi-plate sizes (2L / 4L)',
      'custom_size': 'Custom sizes (up to 128×128)',
      'no_watermark': 'No watermark',
      'real_size_pdf': 'Actual-size PDF',
      'hi_res_pdf': 'High-resolution PDF',
      'purchase_btn': 'Buy for \$4.99',
      'perler': 'Perler',
      'nano': 'Nano',
      'hama': 'Hama',
    },
    'zh': {
      'app_name': 'beadot',
      'select_settings': '选择设置',
      'brand': '品牌',
      'plate_shape': '模板形状',
      'plate_size': '模板尺寸',
      'quality': '质量',
      'direct': '直接',
      'dither': '抖动',
      'max_colors': '最大颜色数',
      'converting': '转换中...',
      'save': '保存',
      'preview': '查看成品',
      'adjust_colors': '调整颜色数',
      'pdf_export': 'PDF导出',
      'shopping_list': '购物清单',
      'share': '分享',
      'gallery': '作品集',
      'settings': '设置',
      'premium': '高级版',
      'premium_title': '高级版',
      'premium_price': '¥30 购买',
      'restore': '恢复购买',
      'solid_only': '仅纯色',
      'include_pearl': '含珠光',
      'all_colors': '全部颜色',
      'color_mode': '颜色',
      'symbol_mode': '符号',
      'number_mode': '编号',
      'total': '合计',
      'pieces': '个',
      'colors': '色',
      'sort_by_count': '按数量',
      'sort_by_name': '按名称',
      'copy_text': '复制文本',
      'no_patterns': '暂无图案',
      'delete_confirm': '确定删除此图案？',
      'cancel': '取消',
      'delete': '删除',
      'default_brand': '默认品牌',
      'remove_isolated': '去除孤立像素',
      'dark_mode': '深色模式',
      'language': '语言',
      'privacy_policy': '隐私政策',
      'terms_of_use': '使用条款',
      'contact': '联系我们',
      'version': '版本',
      'daily_limit_reached': '今日免费次数已用完\n明天再试',
      'premium_required': '高级版功能',
      'disclaimer': '※ 本应用非拼豆厂商官方应用。颜色为近似值，可能与实际拼豆颜色有所差异。',
      'dither_strength': '扩散强度',
      'hint_small_direct': 'S（15×15）建议使用直接模式',
      'hint_large_dither': '29×29以上使用抖动可使渐变更自然',
      'unlimited_gen': '无限生成',
      'multi_plate': '多板拼接（2L / 4L）',
      'custom_size': '自定义尺寸（最大128×128）',
      'no_watermark': '无水印',
      'real_size_pdf': '实际尺寸PDF',
      'hi_res_pdf': '高分辨率PDF',
      'purchase_btn': '¥30 购买',
      'perler': '拼豆',
      'nano': '迷你拼豆',
      'hama': '哈马',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ja', 'en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
