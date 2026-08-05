import { common } from '@kit.AbilityKit';
import {
  InMemoryUserJourneyStore,
  PreferencesUserJourneyStore,
  UserJourneyStore,
} from './UserJourneyStore';

export class AppUserJourneyStore {
  private static store: UserJourneyStore = new InMemoryUserJourneyStore();

  static configure(context: common.Context): void {
    AppUserJourneyStore.store = new PreferencesUserJourneyStore(context);
  }

  static shared(): UserJourneyStore {
    return AppUserJourneyStore.store;
  }
}

