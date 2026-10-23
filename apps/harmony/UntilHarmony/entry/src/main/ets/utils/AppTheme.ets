export class AppTheme {
  // Color resources are resolved again when HarmonyOS changes appearance.
  static readonly pageBackground: ResourceColor = $r('app.color.page_background');
  static readonly materialBackground: ResourceColor = $r('app.color.material_background');
  static readonly cardBackground: ResourceColor = $r('app.color.card_background');
  static readonly elevatedBackground: ResourceColor = $r('app.color.elevated_background');
  static readonly primaryText: ResourceColor = $r('app.color.primary_text');
  static readonly secondaryText: ResourceColor = $r('app.color.secondary_text');
  static readonly tertiaryText: ResourceColor = $r('app.color.tertiary_text');
  static readonly separator: ResourceColor = $r('app.color.separator');
  static readonly brand: ResourceColor = $r('app.color.brand');
  static readonly brandDark: ResourceColor = $r('app.color.brand_dark');
  static readonly brandSoft: ResourceColor = $r('app.color.brand_soft');
  static readonly warning: ResourceColor = $r('app.color.warning');
  static readonly warningSoft: ResourceColor = $r('app.color.warning_soft');
  static readonly danger: ResourceColor = $r('app.color.danger');
  static readonly dangerSoft: ResourceColor = $r('app.color.danger_soft');
  static readonly upcoming: ResourceColor = $r('app.color.upcoming');
  static readonly upcomingSoft: ResourceColor = $r('app.color.upcoming_soft');
  static readonly distant: ResourceColor = $r('app.color.distant');
  static readonly distantSoft: ResourceColor = $r('app.color.distant_soft');
  static readonly disabledBackground: ResourceColor = $r('app.color.disabled_background');
  static readonly disabledText: ResourceColor = $r('app.color.disabled_text');

  static readonly heroBackground: ResourceColor = $r('app.color.hero_background');
  static readonly heroText: ResourceColor = $r('app.color.hero_text');
  static readonly heroSecondary: ResourceColor = $r('app.color.hero_secondary');
  static readonly heroAccent: ResourceColor = $r('app.color.hero_accent');

  static readonly minimumTouchSize: number = 44;
  static readonly pagePadding: number = 20;
  static readonly sectionSpacing: number = 14;
  static readonly cardRadius: number = 20;
  static readonly controlRadius: number = 14;
  static readonly navigationHeight: number = 80;
  static readonly navigationTitleSize: number = 20;
  static readonly sectionTitleSize: number = 16;
  static readonly bodyTextSize: number = 14;
  static readonly supportingTextSize: number = 12;
  static readonly captionTextSize: number = 12;
  static readonly primaryActionHeight: number = 56;
  static readonly primaryActionRadius: number = 16;
}
