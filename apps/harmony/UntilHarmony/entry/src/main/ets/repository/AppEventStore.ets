import { common } from '@kit.AbilityKit';
import { CountdownEventStore } from './CountdownEventStore';
import { InMemoryCountdownEventStore } from './InMemoryCountdownEventStore';
import { PreferencesCountdownEventStore } from './PreferencesCountdownEventStore';

export class AppEventStore {
  private static store: CountdownEventStore = new InMemoryCountdownEventStore();

  static configure(context: common.Context): void {
    AppEventStore.store = new PreferencesCountdownEventStore(context);
  }

  static shared(): CountdownEventStore {
    return AppEventStore.store;
  }
}
