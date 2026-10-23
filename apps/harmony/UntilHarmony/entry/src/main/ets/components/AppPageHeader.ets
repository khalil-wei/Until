import { AppTheme } from '../utils/AppTheme';
import { L } from '../utils/LocalizedText';

@Component
export struct AppPageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop actionText: string = '';
  @Prop actionEnabled: boolean = true;
  @Prop accent: ResourceColor = AppTheme.brand;
  @Prop accentSoft: ResourceColor = AppTheme.brandSoft;
  onBack: () => void = () => {};
  onAction: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Button({ type: ButtonType.Normal }) {
        Image($r('app.media.ui_back'))
          .width(22).height(22).fillColor(AppTheme.primaryText)
      }
      .width(AppTheme.minimumTouchSize).height(AppTheme.minimumTouchSize)
      .borderRadius(AppTheme.controlRadius)
      .backgroundColor(Color.Transparent)
      .accessibilityText(L.text('action.back'))
      .onClick(this.onBack)
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(AppTheme.navigationTitleSize).fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
        if (this.subtitle.length > 0) {
          Text(this.subtitle).fontSize(AppTheme.supportingTextSize)
            .fontColor(AppTheme.secondaryText)
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      if (this.actionText.length > 0) {
        Button(this.actionText, { type: ButtonType.Normal })
          .fontSize(AppTheme.bodyTextSize).fontWeight(FontWeight.Medium)
          .fontColor(this.actionEnabled ? this.accent : AppTheme.disabledText)
          .backgroundColor(this.actionEnabled ? this.accentSoft : AppTheme.disabledBackground)
          .constraintSize({ minWidth: AppTheme.minimumTouchSize, minHeight: AppTheme.minimumTouchSize })
          .padding({ left: 14, right: 14 }).borderRadius(AppTheme.controlRadius)
          .enabled(this.actionEnabled).onClick(this.onAction)
      }
    }
    .width('100%').constraintSize({ minHeight: AppTheme.navigationHeight })
    .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding, top: 8, bottom: 8 })
  }
}
