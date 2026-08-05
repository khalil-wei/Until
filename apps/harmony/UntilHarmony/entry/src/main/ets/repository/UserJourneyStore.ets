import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const JOURNEY_STORE_NAME = 'until_user_journey';
const JOURNEY_STATE_KEY = 'journeyState';

export interface UserJourneyState {
  hasSeenFirstSaveGuide: boolean;
  activationCardDismissedAt: number;
  lastKnownCardCount: number;
}

export interface UserJourneyStore {
  load(): UserJourneyState;
  save(state: UserJourneyState): void;
}

export class UserJourneyDefaults {
  static state(): UserJourneyState {
    return {
      hasSeenFirstSaveGuide: false,
      activationCardDismissedAt: 0,
      lastKnownCardCount: 0,
    };
  }
}

export class InMemoryUserJourneyStore implements UserJourneyStore {
  private state: UserJourneyState = UserJourneyDefaults.state();

  load(): UserJourneyState {
    return this.copy(this.state);
  }

  save(state: UserJourneyState): void {
    this.state = this.copy(state);
  }

  private copy(state: UserJourneyState): UserJourneyState {
    return {
      hasSeenFirstSaveGuide: state.hasSeenFirstSaveGuide,
      activationCardDismissedAt: state.activationCardDismissedAt,
      lastKnownCardCount: state.lastKnownCardCount,
    };
  }
}

export class PreferencesUserJourneyStore implements UserJourneyStore {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  load(): UserJourneyState {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: JOURNEY_STORE_NAME });
      const rawValue = store.getSync(JOURNEY_STATE_KEY, '') as string;
      if (rawValue.trim().length === 0) {
        return UserJourneyDefaults.state();
      }

      const decoded = JSON.parse(rawValue) as UserJourneyState;
      return {
        hasSeenFirstSaveGuide: decoded.hasSeenFirstSaveGuide === true,
        activationCardDismissedAt: Number.isFinite(decoded.activationCardDismissedAt)
          ? decoded.activationCardDismissedAt
          : 0,
        lastKnownCardCount: Number.isFinite(decoded.lastKnownCardCount)
          ? Math.max(0, decoded.lastKnownCardCount)
          : 0,
      };
    } catch (error) {
      console.error(`Failed to load user journey state: ${JSON.stringify(error)}`);
      return UserJourneyDefaults.state();
    }
  }

  save(state: UserJourneyState): void {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: JOURNEY_STORE_NAME });
      store.putSync(JOURNEY_STATE_KEY, JSON.stringify(state));
      store.flushSync();
    } catch (error) {
      console.error(`Failed to save user journey state: ${JSON.stringify(error)}`);
    }
  }
}

