import { Want } from '@kit.AbilityKit';
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import {
  CountdownCardDataSource,
} from '../card/CountdownCardDataSource';
import {
  CountdownCardContentMode,
  CountdownCardSize,
} from '../card/CountdownCardConfiguration';
import { AppUserJourneyStore } from '../repository/AppUserJourneyStore';
import { CardInstallService } from '../services/CardInstallService';

const SMALL_CARD_NAME = 'until_countdown_small';
const LARGE_CARD_NAME = 'until_countdown_large';

export default class CountdownFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    AppUserJourneyStore.configure(this.context);
    const formId = this.formIdFromWant(want);
    const size = this.sizeFromWant(want);
    CountdownCardDataSource.rememberCard(this.context, formId, size);
    CardInstallService.syncKnownCardCount(this.context);
    const instance = CountdownCardDataSource.configurationForCard(this.context, formId);
    return formBindingData.createFormBindingData(CountdownCardDataSource.bindingRecord(
      this.context,
      size,
      instance?.contentMode === CountdownCardContentMode.Featured ? instance.featuredEventID : undefined,
      instance?.theme,
    ));
  }

  onCastToNormalForm(formId: string): void {
    console.info(`CountdownFormAbility onCastToNormalForm: ${formId}`);
  }

  onUpdateForm(formId: string): void {
    CountdownCardDataSource.rememberCardIfMissing(this.context, formId, CountdownCardSize.Medium);
    CountdownCardDataSource.refreshCard(this.context, formId);
  }

  onSizeChanged(formId: string, newDimension: formInfo.FormDimension, _newRect: formInfo.Rect): void {
    const size = newDimension === formInfo.FormDimension.Dimension_2_2
      ? CountdownCardSize.Small
      : newDimension === formInfo.FormDimension.Dimension_4_4
        ? CountdownCardSize.Large
        : CountdownCardSize.Medium;
    CountdownCardDataSource.updateCardSize(this.context, formId, size);
    CountdownCardDataSource.refreshCard(this.context, formId);
  }

  onRemoveForm(formId: string): void {
    AppUserJourneyStore.configure(this.context);
    CountdownCardDataSource.forgetCard(this.context, formId);
    CardInstallService.syncKnownCardCount(this.context);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    AppUserJourneyStore.configure(this.context);
    CardInstallService.syncKnownCardCount(this.context);
    return formInfo.FormState.READY;
  }

  private formIdFromWant(want: Want): string {
    return `${want.parameters?.[formInfo.FormParam.IDENTITY_KEY] ?? ''}`;
  }

  private sizeFromWant(want: Want): CountdownCardSize {
    const formName = `${want.parameters?.[formInfo.FormParam.NAME_KEY] ?? ''}`;

    if (formName === SMALL_CARD_NAME) {
      return CountdownCardSize.Small;
    }

    if (formName === LARGE_CARD_NAME) {
      return CountdownCardSize.Large;
    }

    const dimension = `${want.parameters?.[formInfo.FormParam.DIMENSION_KEY] ?? ''}`;
    if (dimension === `${formInfo.FormDimension.Dimension_2_2}`) {
      return CountdownCardSize.Small;
    }

    return dimension === `${formInfo.FormDimension.Dimension_4_4}`
      ? CountdownCardSize.Large
      : CountdownCardSize.Medium;
  }
}
