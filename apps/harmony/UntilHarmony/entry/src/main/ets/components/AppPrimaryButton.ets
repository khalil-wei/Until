import { AppTheme } from '../utils/AppTheme';
import { L } from '../utils/LocalizedText';

@Component
export struct AppPrimaryButton {
  @Prop label: string = '';
  @Prop busy: boolean = false;
  @Prop available: boolean = true;
  @Prop accent: ResourceColor = AppTheme.brand;
  onAction: () => void = () => {};

  build() {
    Button(this.busy ? L.text('action.saving') : this.label, { type: ButtonType.Normal })
      .width('100%').constraintSize({ minHeight: AppTheme.primaryActionHeight })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .fontSize(16).fontWeight(FontWeight.Medium)
      .fontColor(this.available && !this.busy ? Color.White : AppTheme.disabledText)
      .backgroundColor(this.available && !this.busy ? this.accent : AppTheme.disabledBackground)
      .borderRadius(AppTheme.primaryActionRadius)
      .enabled(this.available && !this.busy)
      .accessibilityText(this.busy ? L.text('action.saving') : this.label)
      .onClick(this.onAction)
  }
}
