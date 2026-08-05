import { common, Want } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { formInfo, formProvider } from '@kit.FormKit';
import {
  CountdownCardConfiguration,
  CountdownCardDataSource,
  CountdownCardInstance,
} from '../card/CountdownCardDataSource';
import {
  CountdownCardConfigurationRules,
  CountdownCardSize,
} from '../card/CountdownCardConfiguration';
import { AppUserJourneyStore } from '../repository/AppUserJourneyStore';
import { ActivationService } from './ActivationService';

const APP_BUNDLE_NAME = 'com.khalil.until';
const ENTRY_ABILITY_NAME = 'EntryAbility';
const SMALL_CARD_NAME = 'until_countdown_small';
const MEDIUM_CARD_NAME = 'until_countdown_medium';
const LARGE_CARD_NAME = 'until_countdown_large';

export enum CardConfigurationUpdateResult {
  Updated = 'updated',
  RefreshPending = 'refreshPending',
  Missing = 'missing',
}

export class CardInstallService {
  private static context?: common.UIAbilityContext;
  private static didCompleteRunningCardQuery: boolean = false;

  static configure(context: common.UIAbilityContext): void {
    CardInstallService.context = context;
  }

  static registeredCardCount(): number {
    const context = CardInstallService.context;
    if (context === undefined) {
      return 0;
    }

    return CountdownCardDataSource.registeredCardCount(context);
  }

  static cardInstances(): CountdownCardInstance[] {
    const context = CardInstallService.context;
    if (context === undefined) {
      return [];
    }

    return CountdownCardDataSource.cardInstances(context);
  }

  static isRunningCardQueryReliable(): boolean {
    return CardInstallService.didCompleteRunningCardQuery;
  }

  static async reconcileCardInstances(): Promise<CountdownCardInstance[]> {
    const context = CardInstallService.context;
    if (context === undefined) {
      return [];
    }

    const storedCards = CountdownCardDataSource.cardInstances(context);
    if (deviceInfo.sdkApiVersion < 20) {
      CardInstallService.didCompleteRunningCardQuery = false;
      return storedCards;
    }

    try {
      const runningForms = await formProvider.getPublishedRunningFormInfos();
      const desktopForms = runningForms.filter((info: formInfo.RunningFormInfo) =>
        CardInstallService.isCountdownDesktopCard(info));
      const reconciledCards: CountdownCardInstance[] = [];

      desktopForms.forEach((info: formInfo.RunningFormInfo) => {
        const existing = storedCards.find((card: CountdownCardInstance) => card.id === info.formId);
        const defaults = CountdownCardConfigurationRules.defaultConfiguration();
        reconciledCards.push({
          id: info.formId,
          size: CardInstallService.cardSize(info),
          contentMode: existing?.contentMode ?? defaults.contentMode,
          featuredEventID: existing?.featuredEventID,
          theme: existing?.theme ?? defaults.theme,
          configurationVersion: existing?.configurationVersion ?? defaults.configurationVersion,
        });
      });

      CountdownCardDataSource.replaceCardInstances(context, reconciledCards);
      new ActivationService(AppUserJourneyStore.shared()).updateKnownCardCount(reconciledCards.length);
      CardInstallService.didCompleteRunningCardQuery = true;
      return reconciledCards;
    } catch (error) {
      CardInstallService.didCompleteRunningCardQuery = false;
      console.warn(`Failed to query running countdown cards: ${JSON.stringify(error)}`);
      return storedCards;
    }
  }

  static async updateConfiguration(
    formId: string,
    configuration: CountdownCardConfiguration,
  ): Promise<CardConfigurationUpdateResult> {
    const context = CardInstallService.context;
    if (context === undefined || !CountdownCardDataSource.updateConfiguration(context, formId, configuration)) {
      return CardConfigurationUpdateResult.Missing;
    }

    const didRefresh = await CountdownCardDataSource.refreshCard(context, formId);
    return didRefresh ? CardConfigurationUpdateResult.Updated : CardConfigurationUpdateResult.RefreshPending;
  }

  static syncKnownCardCount(context: common.Context): void {
    const count = CountdownCardDataSource.registeredCardCount(context);
    new ActivationService(AppUserJourneyStore.shared()).updateKnownCardCount(count);
  }

  static openManager(): boolean {
    if (CardInstallService.context === undefined) {
      return false;
    }

    try {
      const want: Want = {
        bundleName: APP_BUNDLE_NAME,
        abilityName: ENTRY_ABILITY_NAME,
      };
      formProvider.openFormManager(want);
      return true;
    } catch (error) {
      console.warn(`Failed to open form manager: ${JSON.stringify(error)}`);
      return false;
    }
  }

  private static isCountdownDesktopCard(info: formInfo.RunningFormInfo): boolean {
    if (info.formLocation !== formInfo.FormLocation.DESKTOP) {
      return false;
    }

    return info.formName === SMALL_CARD_NAME ||
      info.formName === MEDIUM_CARD_NAME ||
      info.formName === LARGE_CARD_NAME;
  }

  private static cardSize(info: formInfo.RunningFormInfo): CountdownCardSize {
    if (info.formName === SMALL_CARD_NAME) {
      return CountdownCardSize.Small;
    }

    if (info.formName === LARGE_CARD_NAME) {
      return CountdownCardSize.Large;
    }

    return CountdownCardSize.Medium;
  }
}
