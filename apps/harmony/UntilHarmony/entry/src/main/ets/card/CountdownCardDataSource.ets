import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CountdownEvent } from '../model/CountdownEvent';
import { CountdownEventCodec } from '../repository/CountdownEventCodec';
import { CardTimelineProvider, CountdownCardEntry } from './CardTimelineProvider';
import { L } from '../utils/LocalizedText';
import {
  CountdownCardConfiguration,
  CountdownCardConfigurationRules,
  CountdownCardContentMode,
  CountdownCardInstance,
  CountdownCardSize,
  CountdownCardTheme,
  PersistedCountdownCardInstance,
} from './CountdownCardConfiguration';

const EVENT_STORE_NAME = 'until_countdown_events';
const EVENTS_KEY = 'countdownEvents';
const CARD_STORE_NAME = 'until_countdown_cards';
const CARD_INSTANCES_KEY = 'cardInstances';
const SAMPLE_EVENT_ID_PREFIX = 'sample-';

export {
  CountdownCardConfiguration,
  CountdownCardContentMode,
  CountdownCardInstance,
  CountdownCardSize,
  CountdownCardTheme,
} from './CountdownCardConfiguration';

export class CountdownCardDataSource {
  private static bindingRevision: number = 0;

  static bindingRecord(
    context: common.Context,
    size: CountdownCardSize,
    featuredEventID?: string,
    theme: CountdownCardTheme = CountdownCardTheme.Colorful,
    referenceDate: Date = new Date(),
  ): Record<string, string> {
    return CountdownCardDataSource.bindingRecordFromEvents(
      CountdownCardDataSource.loadEvents(context),
      size,
      featuredEventID,
      theme,
      referenceDate,
    );
  }

  private static bindingRecordFromEvents(
    events: CountdownEvent[],
    size: CountdownCardSize,
    featuredEventID?: string,
    theme: CountdownCardTheme = CountdownCardTheme.Colorful,
    referenceDate: Date = new Date(),
  ): Record<string, string> {
    const limit = size === CountdownCardSize.Small
      ? 1
      : size === CountdownCardSize.Large
        ? 6
        : 4;
    const entries = CardTimelineProvider.entries(
      events,
      limit,
      referenceDate,
      featuredEventID,
    );

    return CountdownCardDataSource.recordFromEntries(entries, size, theme);
  }

  static rememberCard(
    context: common.Context,
    formId: string,
    size: CountdownCardSize,
    preferredConfiguration?: CountdownCardConfiguration,
  ): void {
    if (formId.length === 0) {
      return;
    }

    const instances = CountdownCardDataSource.cardInstances(context);
    const existing = instances.find((instance: CountdownCardInstance) => instance.id === formId);
    const configuration = preferredConfiguration ?? existing ?? CountdownCardConfigurationRules.defaultConfiguration();
    const normalized = CountdownCardConfigurationRules.normalizeConfiguration(
      configuration.contentMode,
      configuration.featuredEventID,
      configuration.theme,
    );
    const nextInstances = instances.filter((instance: CountdownCardInstance) => instance.id !== formId);
    nextInstances.push({
      id: formId,
      size,
      contentMode: normalized.contentMode,
      featuredEventID: normalized.featuredEventID,
      theme: normalized.theme,
      configurationVersion: normalized.configurationVersion,
    });
    CountdownCardDataSource.saveCardInstances(context, nextInstances);
  }

  static rememberCardIfMissing(context: common.Context, formId: string, size: CountdownCardSize): void {
    if (formId.length === 0) {
      return;
    }

    const instances = CountdownCardDataSource.cardInstances(context);

    if (instances.some((instance: CountdownCardInstance) => instance.id === formId)) {
      return;
    }

    const defaults = CountdownCardConfigurationRules.defaultConfiguration();
    instances.push({
      id: formId,
      size,
      contentMode: defaults.contentMode,
      featuredEventID: defaults.featuredEventID,
      theme: defaults.theme,
      configurationVersion: defaults.configurationVersion,
    });
    CountdownCardDataSource.saveCardInstances(context, instances);
  }

  static updateCardSize(context: common.Context, formId: string, size: CountdownCardSize): void {
    CountdownCardDataSource.rememberCard(context, formId, size);
  }

  static updateConfiguration(
    context: common.Context,
    formId: string,
    configuration: CountdownCardConfiguration,
  ): boolean {
    const instances = CountdownCardDataSource.cardInstances(context);
    const existing = instances.find((instance: CountdownCardInstance) => instance.id === formId);
    if (existing === undefined) {
      return false;
    }

    const normalized = CountdownCardConfigurationRules.normalizeConfiguration(
      configuration.contentMode,
      configuration.featuredEventID,
      configuration.theme,
    );
    const nextInstances = instances.filter((instance: CountdownCardInstance) => instance.id !== formId);
    nextInstances.push({
      id: formId,
      size: existing.size,
      contentMode: normalized.contentMode,
      featuredEventID: normalized.featuredEventID,
      theme: normalized.theme,
      configurationVersion: normalized.configurationVersion,
    });
    CountdownCardDataSource.saveCardInstances(context, nextInstances);
    return true;
  }

  static configurationForCard(context: common.Context, formId: string): CountdownCardInstance | undefined {
    return CountdownCardDataSource.cardInstances(context)
      .find((instance: CountdownCardInstance) => instance.id === formId);
  }

  static forgetCard(context: common.Context, formId: string): void {
    const instances = CountdownCardDataSource.cardInstances(context)
      .filter((instance: CountdownCardInstance) => instance.id !== formId);
    CountdownCardDataSource.saveCardInstances(context, instances);
  }

  static registeredCardCount(context: common.Context): number {
    return CountdownCardDataSource.cardInstances(context).length;
  }

  static async refreshCard(context: common.Context, formId: string): Promise<boolean> {
    const instance = CountdownCardDataSource.cardInstances(context)
      .find((current: CountdownCardInstance) => current.id === formId);
    const size = instance?.size ?? CountdownCardSize.Medium;
    const record = CountdownCardDataSource.bindingRecord(
      context,
      size,
      instance?.contentMode === CountdownCardContentMode.Featured ? instance.featuredEventID : undefined,
      instance?.theme ?? CountdownCardTheme.Colorful,
    );

    try {
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(record));
      return true;
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`Failed to update countdown card ${formId}: ${businessError.code}, ${businessError.message}`);
      return false;
    }
  }

  static async refreshAllCards(
    context: common.Context,
    currentEvents?: CountdownEvent[],
  ): Promise<boolean> {
    const instances = CountdownCardDataSource.cardInstances(context);
    const events = currentEvents ?? CountdownCardDataSource.loadEvents(context);
    let didRefreshAllCards = true;

    for (let index = 0; index < instances.length; index += 1) {
      const instance = instances[index];
      const record = CountdownCardDataSource.bindingRecordFromEvents(
        events,
        instance.size,
        instance.contentMode === CountdownCardContentMode.Featured ? instance.featuredEventID : undefined,
        instance.theme,
      );

      try {
        await formProvider.updateForm(instance.id, formBindingData.createFormBindingData(record));
        console.info(
          `Countdown card refreshed formId=${instance.id}, size=${instance.size}, ` +
            `entries=${record.eventCountText}, token=${record.updateToken}`,
        );
      } catch (error) {
        didRefreshAllCards = false;
        const businessError = error as BusinessError;
        console.error(`Failed to update countdown card ${instance.id}: ${businessError.code}, ${businessError.message}`);
      }
    }

    return didRefreshAllCards;
  }

  private static recordFromEntries(
    entries: CountdownCardEntry[],
    size: CountdownCardSize,
    theme: CountdownCardTheme,
  ): Record<string, string> {
    const record = new Object() as Record<string, string>;
    record.cardSize = size;
    record.theme = theme;
    CountdownCardDataSource.bindingRevision += 1;
    record.updateToken = `${Date.now()}-${CountdownCardDataSource.bindingRevision}|` +
      entries.map((entry: CountdownCardEntry) =>
        `${entry.id}:${entry.title}:${entry.dateText}:${entry.countdownBadgeText}`).join('|');
    record.appTitle = L.text('app.title');
    record.appSubtitle = L.text('app.subtitle');
    record.sectionTitle = L.text('card.upcoming');
    record.brandShort = L.text('card.brand.short');
    record.nextLabel = L.text('card.next');
    record.largeTitle = L.text('card.large.title');
    record.largeSubtitle = L.text('card.large.subtitle');
    record.moreEventsTitle = L.text('card.more_events');
    record.emptyTitle = L.text('card.empty');
    record.emptySubtitle = L.text('card.empty.subtitle');
    record.eventCountText = L.cardCount(entries.length);
    record.hasEvents = entries.length > 0 ? 'true' : 'false';

    for (let index = 0; index < 6; index += 1) {
      const entry = entries[index];
      const prefix = `entry${index}`;

      record[`${prefix}Visible`] = entry ? 'true' : 'false';
      record[`${prefix}ID`] = entry?.id ?? '';
      record[`${prefix}Title`] = entry?.title ?? '';
      record[`${prefix}DateText`] = entry?.dateText ?? '';
      record[`${prefix}CountdownText`] = entry?.countdownText ?? '';
      record[`${prefix}CountdownBadgeText`] = entry?.countdownBadgeText ?? '';
      record[`${prefix}CountdownUnitText`] = entry?.countdownUnitText ?? '';
      record[`${prefix}ShouldShowUnit`] = entry?.shouldShowCountdownUnit ? 'true' : 'false';
      record[`${prefix}CategorySymbol`] = entry?.categorySymbol ?? '';
      record[`${prefix}CategoryLabel`] = entry?.categoryLabel ?? '';
      record[`${prefix}UrgencyColor`] = entry?.urgencyColor ?? '#079D89';
    }

    return record;
  }

  private static loadEvents(context: common.Context): CountdownEvent[] {
    try {
      const store = preferences.getPreferencesSync(context, { name: EVENT_STORE_NAME });
      const rawValue = store.getSync(EVENTS_KEY, '') as string;

      if (rawValue.trim().length === 0) {
        return [];
      }

      return CountdownEventCodec.decode(rawValue)
        .filter((event: CountdownEvent) => !event.id.startsWith(SAMPLE_EVENT_ID_PREFIX));
    } catch (error) {
      console.error(`Failed to load countdown card events: ${JSON.stringify(error)}`);
      return [];
    }
  }

  static cardInstances(context: common.Context): CountdownCardInstance[] {
    try {
      const store = preferences.getPreferencesSync(context, { name: CARD_STORE_NAME });
      const rawValue = store.getSync(CARD_INSTANCES_KEY, '') as string;

      if (rawValue.trim().length === 0) {
        return [];
      }

      const persisted = JSON.parse(rawValue) as PersistedCountdownCardInstance[];
      const migrated: CountdownCardInstance[] = [];
      persisted.forEach((instance: PersistedCountdownCardInstance) => {
        const current = CountdownCardConfigurationRules.migrateInstance(instance);
        if (current !== undefined) {
          migrated.push(current);
        }
      });
      return migrated;
    } catch (error) {
      console.error(`Failed to load countdown card instances: ${JSON.stringify(error)}`);
      return [];
    }
  }

  static replaceCardInstances(context: common.Context, instances: CountdownCardInstance[]): void {
    CountdownCardDataSource.saveCardInstances(context, instances);
  }

  private static saveCardInstances(context: common.Context, instances: CountdownCardInstance[]): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: CARD_STORE_NAME });
      store.putSync(CARD_INSTANCES_KEY, JSON.stringify(instances));
      store.flushSync();
    } catch (error) {
      console.error(`Failed to save countdown card instances: ${JSON.stringify(error)}`);
    }
  }
}

export class CountdownCardUpdateService {
  private static readonly CONFIRMATION_DELAYS: number[] = [700, 2200];
  private static context?: common.Context;
  private static refreshTimer?: number;
  private static refreshGeneration: number = 0;

  static configure(context: common.Context): void {
    CountdownCardUpdateService.context = context;
  }

  static async refreshAllCards(): Promise<void> {
    const context = CountdownCardUpdateService.context;

    if (!context) {
      return;
    }

    await CountdownCardDataSource.refreshAllCards(context);
  }

  static async refreshAfterEventChange(events: CountdownEvent[]): Promise<void> {
    const context = CountdownCardUpdateService.context;

    if (!context) {
      return;
    }

    CountdownCardUpdateService.refreshGeneration += 1;
    const generation = CountdownCardUpdateService.refreshGeneration;
    if (CountdownCardUpdateService.refreshTimer !== undefined) {
      clearTimeout(CountdownCardUpdateService.refreshTimer);
      CountdownCardUpdateService.refreshTimer = undefined;
    }

    await CountdownCardDataSource.refreshAllCards(context, events);
    if (generation === CountdownCardUpdateService.refreshGeneration) {
      CountdownCardUpdateService.scheduleConfirmation(context, events, generation, 0);
    }
  }

  private static scheduleConfirmation(
    context: common.Context,
    events: CountdownEvent[],
    generation: number,
    retryIndex: number,
  ): void {
    if (retryIndex >= CountdownCardUpdateService.CONFIRMATION_DELAYS.length) {
      return;
    }

    CountdownCardUpdateService.refreshTimer = setTimeout(async () => {
      CountdownCardUpdateService.refreshTimer = undefined;
      await CountdownCardDataSource.refreshAllCards(context, events);

      if (generation !== CountdownCardUpdateService.refreshGeneration) {
        return;
      }

      CountdownCardUpdateService.scheduleConfirmation(context, events, generation, retryIndex + 1);
    }, CountdownCardUpdateService.CONFIRMATION_DELAYS[retryIndex]);
  }
}
