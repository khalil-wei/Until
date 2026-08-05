export const COUNTDOWN_CARD_CONFIGURATION_VERSION = 1;

export enum CountdownCardSize {
  Small = 'small',
  Medium = 'medium',
  Large = 'large',
}

export enum CountdownCardTheme {
  Colorful = 'colorful',
  Minimal = 'minimal',
  Midnight = 'midnight',
}

export enum CountdownCardContentMode {
  Automatic = 'automatic',
  Featured = 'featured',
}

export interface CountdownCardConfiguration {
  contentMode: CountdownCardContentMode;
  featuredEventID?: string;
  theme: CountdownCardTheme;
  configurationVersion: number;
}

export interface CountdownCardInstance {
  id: string;
  size: CountdownCardSize;
  contentMode: CountdownCardContentMode;
  featuredEventID?: string;
  theme: CountdownCardTheme;
  configurationVersion: number;
}

export interface PersistedCountdownCardInstance {
  id?: string;
  size?: CountdownCardSize;
  contentMode?: CountdownCardContentMode;
  featuredEventID?: string;
  theme?: CountdownCardTheme;
  configurationVersion?: number;
}

export class CountdownCardConfigurationRules {
  static defaultConfiguration(): CountdownCardConfiguration {
    return {
      contentMode: CountdownCardContentMode.Automatic,
      featuredEventID: undefined,
      theme: CountdownCardTheme.Colorful,
      configurationVersion: COUNTDOWN_CARD_CONFIGURATION_VERSION,
    };
  }

  static normalizeConfiguration(
    contentMode?: CountdownCardContentMode,
    featuredEventID?: string,
    theme?: CountdownCardTheme,
  ): CountdownCardConfiguration {
    const normalizedFeaturedEventID = CountdownCardConfigurationRules.normalizedFeaturedEventID(featuredEventID);
    const normalizedMode = CountdownCardConfigurationRules.normalizedContentMode(
      contentMode,
      normalizedFeaturedEventID,
    );

    return {
      contentMode: normalizedMode,
      featuredEventID: normalizedMode === CountdownCardContentMode.Featured
        ? normalizedFeaturedEventID
        : undefined,
      theme: CountdownCardConfigurationRules.normalizedTheme(theme),
      configurationVersion: COUNTDOWN_CARD_CONFIGURATION_VERSION,
    };
  }

  static migrateInstance(instance: PersistedCountdownCardInstance): CountdownCardInstance | undefined {
    const id = instance.id ?? '';
    if (id.length === 0) {
      return undefined;
    }

    const configuration = CountdownCardConfigurationRules.normalizeConfiguration(
      instance.contentMode,
      instance.featuredEventID,
      instance.theme,
    );

    return {
      id,
      size: CountdownCardConfigurationRules.normalizedSize(instance.size),
      contentMode: configuration.contentMode,
      featuredEventID: configuration.featuredEventID,
      theme: configuration.theme,
      configurationVersion: configuration.configurationVersion,
    };
  }

  static effectiveFeaturedEventID(
    configuration: CountdownCardConfiguration,
    availableEventIDs: string[],
  ): string | undefined {
    if (configuration.contentMode !== CountdownCardContentMode.Featured ||
      configuration.featuredEventID === undefined ||
      availableEventIDs.indexOf(configuration.featuredEventID) < 0) {
      return undefined;
    }

    return configuration.featuredEventID;
  }

  private static normalizedFeaturedEventID(featuredEventID?: string): string | undefined {
    const candidate = featuredEventID?.trim() ?? '';
    return candidate.length > 0 ? candidate : undefined;
  }

  private static normalizedContentMode(
    contentMode: CountdownCardContentMode | undefined,
    featuredEventID: string | undefined,
  ): CountdownCardContentMode {
    if (contentMode === CountdownCardContentMode.Featured && featuredEventID !== undefined) {
      return CountdownCardContentMode.Featured;
    }

    // 兼容旧实例：旧结构只有 featuredEventID，没有 contentMode。
    if (contentMode === undefined && featuredEventID !== undefined) {
      return CountdownCardContentMode.Featured;
    }

    return CountdownCardContentMode.Automatic;
  }

  private static normalizedTheme(theme?: CountdownCardTheme): CountdownCardTheme {
    if (theme === CountdownCardTheme.Minimal || theme === CountdownCardTheme.Midnight) {
      return theme;
    }

    return CountdownCardTheme.Colorful;
  }

  private static normalizedSize(size?: CountdownCardSize): CountdownCardSize {
    if (size === CountdownCardSize.Small || size === CountdownCardSize.Large) {
      return size;
    }

    return CountdownCardSize.Medium;
  }
}
