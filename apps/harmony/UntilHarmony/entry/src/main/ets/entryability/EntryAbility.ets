import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { formInfo } from '@kit.FormKit';
import { AppCalendarService } from '../calendar/AppCalendarService';
import { CountdownCardUpdateService } from '../card/CountdownCardDataSource';
import { AppEventStore } from '../repository/AppEventStore';
import { AppUserJourneyStore } from '../repository/AppUserJourneyStore';
import { CardInstallService } from '../services/CardInstallService';
import { ReminderService } from '../services/ReminderService';
import { RetentionCoordinator } from '../services/RetentionCoordinator';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppEventStore.configure(this.context);
    AppCalendarService.configure(this.context);
    CountdownCardUpdateService.configure(this.context);
    AppUserJourneyStore.configure(this.context);
    CardInstallService.configure(this.context);
    ReminderService.configure(this.context);
    PersistentStorage.persistProp('lastNightLetterShownAt', 0);
    PersistentStorage.persistProp('arrivalCelebrationTokens', '');
    AppStorage.setOrCreate('countdownEventsRevision', 0);
    this.captureCardRoute(want);
    RetentionCoordinator.reconcile();
  }

  onDestroy(): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      windowStage.loadContent('pages/Index');
    } catch (error) {
      console.error(`Failed to load the main page: ${JSON.stringify(error)}`);
    }
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
    AppStorage.setOrCreate('appForegroundRevision', (AppStorage.get<number>('appForegroundRevision') ?? 0) + 1);
    RetentionCoordinator.reconcile();
  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    console.info(`Countdown card onNewWant target=${want.parameters?.target}, eventID=${want.parameters?.eventID}`);
    this.captureCardRoute(want);
  }

  onBackground(): void {
    CountdownCardUpdateService.refreshAllCards();
  }

  private captureCardRoute(want: Want): void {
    const target = `${want.parameters?.target ?? ''}`;
    const eventID = `${want.parameters?.eventID ?? ''}`;
    const formID = `${want.parameters?.[formInfo.FormParam.IDENTITY_KEY] ?? ''}`;
    console.info(`Countdown card route captured target=${target}, eventID=${eventID}, hasFormID=${formID.length > 0}`);

    if (target !== 'add' && target !== 'event' && formID.length > 0) {
      AppStorage.setOrCreate('pendingCardRoute', 'configuration');
      AppStorage.setOrCreate('pendingCardEventID', '');
      AppStorage.setOrCreate('pendingCardFormID', formID);
      return;
    }

    if (target !== 'add' && target !== 'event') {
      return;
    }

    const isEventDetailActive = AppStorage.get<boolean>('isEventDetailActive') ?? false;
    if (target === 'event' && eventID.length > 0 && isEventDetailActive) {
      // The existing detail page consumes this ID directly. Do not also queue
      // an Index push, otherwise the same click opens a second detail page.
      AppStorage.setOrCreate('pendingCardRoute', '');
      AppStorage.setOrCreate('pendingCardEventID', '');
      AppStorage.setOrCreate('activeCardEventID', eventID);
      return;
    }

    AppStorage.setOrCreate('pendingCardRoute', target);
    AppStorage.setOrCreate('pendingCardEventID', eventID);
    AppStorage.setOrCreate('pendingCardFormID', '');
    if (target === 'event' && eventID.length > 0) {
      AppStorage.setOrCreate('activeCardEventID', eventID);
    }
  }
}
