// 服务卡片和应用内配色样本共用同一来源，避免预览与实际卡片不一致。
export class CardPalette {
  static background(theme: string): string {
    return theme === 'midnight' ? '#171B29' : theme === 'minimal' ? '#F5F3FC' : '#FFFFFF';
  }
  static accent(theme: string): string {
    return theme === 'midnight' ? '#B8AEF1' : theme === 'minimal' ? '#6660BD' : '#087F75';
  }
  static primary(theme: string): string {
    return theme === 'midnight' ? '#F3F4F6' : '#181A1F';
  }
  static secondary(theme: string): string {
    return theme === 'midnight' ? '#B3B8C7' : '#70747D';
  }
  static surface(theme: string): string {
    return theme === 'midnight' ? '#252A3B' : '#F5F6F8';
  }
  static categoryIcon(symbol: string): Resource {
    if (symbol === '🎂') { return $r('app.media.category_birthday'); }
    if (symbol === '💝') { return $r('app.media.category_anniversary'); }
    return $r('app.media.category_custom');
  }
  static categoryColor(symbol: string, fallback: string = '#6660BD'): string {
    if (symbol === '🎂') { return '#A86024'; }
    if (symbol === '💝') { return '#BE4C73'; }
    if (symbol.length > 0) { return '#6660BD'; }
    return fallback;
  }
  static categorySoft(symbol: string): string {
    if (symbol === '🎂') { return '#FFF1E4'; }
    if (symbol === '💝') { return '#FCECF2'; }
    return '#F0EDFC';
  }
}
