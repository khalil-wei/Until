import { promptAction, router } from '@kit.ArkUI';
import {
  COUNTDOWN_CARD_CONFIGURATION_VERSION,
  CountdownCardConfiguration,
  CountdownCardContentMode,
  CountdownCardInstance,
  CountdownCardSize,
  CountdownCardTheme,
} from '../card/CountdownCardConfiguration';
import { CountdownEvent } from '../model/CountdownEvent';
import { AppEventStore } from '../repository/AppEventStore';
import { CardConfigurationUpdateResult, CardInstallService } from '../services/CardInstallService';
import { AppTheme } from '../utils/AppTheme';
import { EventPresentation } from '../utils/EventPresentation';
import { L } from '../utils/LocalizedText';
import { EventListViewModel } from '../viewmodel/EventListViewModel';

interface CardCenterRouteParams {
  formId?: string;
  featuredEventID?: string;
}

@Entry
@Component
struct CardCenterPage {
  private viewModel: EventListViewModel = new EventListViewModel(AppEventStore.shared());

  @State private cards: CountdownCardInstance[] = [];
  @State private events: CountdownEvent[] = [];
  @State private selectedFormID: string = '';
  @State private contentMode: CountdownCardContentMode = CountdownCardContentMode.Automatic;
  @State private featuredEventID: string = '';
  @State private theme: CountdownCardTheme = CountdownCardTheme.Colorful;
  @State private isSaving: boolean = false;
  @State private isCardQueryReliable: boolean = false;
  private hasAppliedRouteParams: boolean = false;
  private isAwaitingCardAddition: boolean = false;
  private cardIDsBeforeAdding: string[] = [];

  onPageShow(): void {
    this.reload();
  }

  build() {
    Column() {
      this.navigationBar()

      Scroll() {
        Column({ space: 16 }) {
          if (this.cards.length === 0) {
            this.emptyCardState()
          } else {
            this.installedCardsSection()
            if (this.events.length > 1) {
              this.contentSection()
            }
            this.paletteSection()
          }
        }
        .width('100%')
        .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      this.actionArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.pageBackground)
  }

  @Builder
  private navigationBar() {
    Row({ space: 12 }) {
      Button('‹')
        .fontSize(30)
        .fontColor(AppTheme.primaryText)
        .width(42)
        .height(42)
        .borderRadius(21)
        .backgroundColor(AppTheme.cardBackground)
        .onClick(() => {
          router.back();
        })
        .accessibilityText(L.text('action.done'))

      Column({ space: 2 }) {
        Text(L.text('card.center.title'))
          .fontSize(AppTheme.navigationTitleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
        Text(L.text('card.center.subtitle'))
          .fontSize(12)
          .fontColor(AppTheme.secondaryText)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height(AppTheme.navigationHeight)
    .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding })
  }

  @Builder
  private emptyCardState() {
    Column({ space: 14 }) {
      Text('🗓️')
        .fontSize(32)
        .textAlign(TextAlign.Center)
      .width(64)
      .height(64)
      .borderRadius(20)
      .backgroundColor(AppTheme.brandSoft)

      Text(L.text('card.center.empty_title'))
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.primaryText)
        .textAlign(TextAlign.Center)

      Text(this.isCardQueryReliable
        ? L.text('card.center.empty_description')
        : L.text('card.center.query_unavailable'))
        .fontSize(14)
        .fontColor(AppTheme.secondaryText)
        .textAlign(TextAlign.Center)
        .maxLines(3)

      Row({ space: 8 }) {
        Text('1')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .borderRadius(12)
          .backgroundColor(AppTheme.brand)
        Text(L.text('card.center.empty_step'))
          .fontSize(12)
          .fontColor(AppTheme.secondaryText)
          .layoutWeight(1)
      }
      .width('100%')
      .padding(14)
      .borderRadius(AppTheme.controlRadius)
      .backgroundColor(AppTheme.cardBackground)
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 54 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private installedCardsSection() {
    Column({ space: 10 }) {
      this.sectionTitle(`${L.text('card.center.installed')} · ${this.cards.length}`)

      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.cards, (card: CountdownCardInstance) => {
            Button() {
              Column({ space: 2 }) {
                Text(this.sizeLabel(card.size))
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(card.id === this.selectedFormID ? Color.White : AppTheme.primaryText)
                Text(this.shortFormID(card.id))
                  .fontSize(10)
                  .fontColor(card.id === this.selectedFormID ? '#DDF8F2' : AppTheme.tertiaryText)
              }
            }
            .height(52)
            .padding({ left: 16, right: 16 })
            .borderRadius(15)
            .backgroundColor(card.id === this.selectedFormID ? AppTheme.brand : AppTheme.cardBackground)
            .onClick(() => {
              this.selectCard(card);
            })
            .accessibilityText(`${this.sizeLabel(card.size)}，${this.shortFormID(card.id)}`)
          }, (card: CountdownCardInstance) => card.id)
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder
  private contentSection() {
    Column({ space: 10 }) {
      this.sectionTitle(L.text('card.center.content'))

      Column({ space: 10 }) {
        Row({ space: 8 }) {
          this.contentModeButton(L.text('card.center.automatic'), CountdownCardContentMode.Automatic)
          this.contentModeButton(L.text('card.center.fixed'), CountdownCardContentMode.Featured)
        }
        .width('100%')

        if (this.contentMode === CountdownCardContentMode.Featured) {
          Text(L.text('card.center.fixed_helper'))
            .width('100%')
            .fontSize(11)
            .fontColor(AppTheme.secondaryText)

          Column({ space: 1 }) {
            ForEach(this.events, (event: CountdownEvent) => {
              Button() {
                Row({ space: 10 }) {
                  Text(EventPresentation.categorySymbol(event.category))
                    .fontSize(17)
                    .width(26)
                  Column({ space: 2 }) {
                    Text(event.title)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppTheme.primaryText)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(EventPresentation.displayDate(event.nextOccurrence, event.dateCalendar))
                      .fontSize(11)
                      .fontColor(AppTheme.secondaryText)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text(event.id === this.featuredEventID ? '✓' : '')
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.brand)
                    .width(24)
                }
                .width('100%')
              }
              .width('100%')
              .height(54)
              .padding({ left: 10, right: 10 })
              .borderRadius(12)
              .backgroundColor(event.id === this.featuredEventID ? AppTheme.brandSoft : Color.Transparent)
              .onClick(() => {
                this.featuredEventID = event.id;
              })
            }, (event: CountdownEvent) => event.id)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(14)
      .borderRadius(AppTheme.cardRadius)
      .backgroundColor(AppTheme.cardBackground)
    }
    .width('100%')
  }

  @Builder
  private contentModeButton(title: string, mode: CountdownCardContentMode) {
    Button(title)
      .height(42)
      .layoutWeight(1)
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.contentMode === mode ? Color.White : AppTheme.secondaryText)
      .backgroundColor(this.contentMode === mode ? AppTheme.brand : AppTheme.materialBackground)
      .borderRadius(13)
      .onClick(() => {
        this.contentMode = mode;
        if (mode === CountdownCardContentMode.Featured && this.featuredEventID.length === 0 &&
          this.events.length > 0) {
          this.featuredEventID = this.events[0].id;
        }
      })
  }

  @Builder
  private paletteSection() {
    Column({ space: 10 }) {
      this.sectionTitle(L.text('card.center.palette'))
      Row({ space: 8 }) {
        this.paletteButton(
          L.text('card.center.palette_smart'),
          CountdownCardTheme.Colorful,
          '#F5F7FA',
          '#2F8E75',
        )
        this.paletteButton(
          L.text('card.center.palette_indigo'),
          CountdownCardTheme.Minimal,
          '#F4F4F7',
          '#5B61C7',
        )
        this.paletteButton(
          L.text('card.center.palette_dark'),
          CountdownCardTheme.Midnight,
          '#0B1020',
          '#3F4AA8',
        )
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private paletteButton(
    title: string,
    theme: CountdownCardTheme,
    outerColor: string,
    heroColor: string,
  ) {
    Button() {
      Column({ space: 6 }) {
        Stack() {
          Row()
            .width(34)
            .height(22)
            .borderRadius(7)
            .backgroundColor(outerColor)
            .border({ width: 1, color: '#22000000' })
          Row()
            .width(24)
            .height(14)
            .borderRadius(5)
            .backgroundColor(heroColor)
        }
        .width(36)
        .height(24)
        .alignContent(Alignment.Center)

        Text(title)
          .fontSize(12)
          .fontWeight(this.theme === theme ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.theme === theme ? AppTheme.brand : AppTheme.secondaryText)
      }
    }
    .height(72)
    .layoutWeight(1)
    .borderRadius(16)
    .backgroundColor(this.theme === theme ? AppTheme.brandSoft : AppTheme.cardBackground)
    .onClick(() => {
      this.theme = theme;
    })
  }

  @Builder
  private actionArea() {
    Column({ space: 8 }) {
      if (this.cards.length === 0) {
        Text(L.text('card.center.size_hint'))
          .fontSize(11)
          .fontColor(AppTheme.secondaryText)
          .textAlign(TextAlign.Center)
          .maxLines(2)
      }

      Button(this.cards.length === 0
        ? L.text('card.center.add')
        : L.text('card.center.save_refresh'))
        .width('100%')
        .height(AppTheme.primaryActionHeight)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor(this.canSave() ? AppTheme.brand : AppTheme.disabledBackground)
        .borderRadius(AppTheme.primaryActionRadius)
        .enabled(this.canSave() && !this.isSaving)
        .onClick(() => {
          this.performPrimaryAction();
        })

      if (this.cards.length > 0) {
        Button(L.text('card.center.add_another'))
          .height(38)
          .fontSize(13)
          .fontColor(AppTheme.brand)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.openCardManager();
          })
      }
    }
    .width('100%')
    .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding, top: 10, bottom: 16 })
    .backgroundColor(AppTheme.pageBackground)
  }

  @Builder
  private sectionTitle(title: string) {
    Text(title)
      .width('100%')
      .fontSize(AppTheme.sectionTitleSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppTheme.primaryText)
      .padding({ left: 2 })
  }

  private async reload(): Promise<void> {
    this.viewModel = new EventListViewModel(AppEventStore.shared());
    const loadedEvents = await this.viewModel.load();
    const reconciledCards = await CardInstallService.reconcileCardInstances();
    this.events = loadedEvents;
    this.cards = reconciledCards;
    this.isCardQueryReliable = CardInstallService.isRunningCardQueryReliable();

    if (this.isAwaitingCardAddition) {
      const addedCard = this.cards.find((card: CountdownCardInstance) =>
        this.cardIDsBeforeAdding.indexOf(card.id) < 0);
      if (addedCard !== undefined) {
        this.isAwaitingCardAddition = false;
        this.cardIDsBeforeAdding = [];
        this.selectCard(addedCard);
        return;
      }
    }

    let requestedFormID = '';
    let requestedFeaturedEventID = '';
    if (!this.hasAppliedRouteParams) {
      const params = router.getParams() as CardCenterRouteParams;
      requestedFormID = params?.formId ?? '';
      requestedFeaturedEventID = params?.featuredEventID ?? '';
      this.hasAppliedRouteParams = true;
    }

    const pendingTarget = AppStorage.get<string>('pendingCardRoute') ?? '';
    const pendingFormID = AppStorage.get<string>('pendingCardFormID') ?? '';
    if (pendingTarget === 'configuration' && pendingFormID.length > 0) {
      requestedFormID = pendingFormID;
      AppStorage.setOrCreate('pendingCardRoute', '');
      AppStorage.setOrCreate('pendingCardEventID', '');
      AppStorage.setOrCreate('pendingCardFormID', '');
    }

    if (this.cards.length === 0) {
      this.resetConfiguration();
      return;
    }

    const preferredFormID = requestedFormID.length > 0 ? requestedFormID : this.selectedFormID;
    const selected = this.cards.find((card: CountdownCardInstance) => card.id === preferredFormID) ?? this.cards[0];
    this.selectCard(selected);

    if (requestedFeaturedEventID.length > 0 &&
      this.events.some((event: CountdownEvent) => event.id === requestedFeaturedEventID)) {
      this.contentMode = CountdownCardContentMode.Featured;
      this.featuredEventID = requestedFeaturedEventID;
    }
  }

  private selectCard(card: CountdownCardInstance): void {
    this.selectedFormID = card.id;
    this.theme = card.theme;
    const hasFeaturedEvent = card.featuredEventID !== undefined &&
      this.events.some((event: CountdownEvent) => event.id === card.featuredEventID);
    this.contentMode = card.contentMode === CountdownCardContentMode.Featured && hasFeaturedEvent
      ? CountdownCardContentMode.Featured
      : CountdownCardContentMode.Automatic;
    this.featuredEventID = hasFeaturedEvent ? card.featuredEventID ?? '' : '';
  }

  private resetConfiguration(): void {
    this.selectedFormID = '';
    this.contentMode = CountdownCardContentMode.Automatic;
    this.featuredEventID = '';
    this.theme = CountdownCardTheme.Colorful;
  }

  private performPrimaryAction(): void {
    if (this.cards.length === 0) {
      this.openCardManager();
      return;
    }

    this.saveSelectedCard();
  }

  private async saveSelectedCard(): Promise<void> {
    if (!this.canSave() || this.isSaving) {
      return;
    }

    this.isSaving = true;
    const result = await CardInstallService.updateConfiguration(
      this.selectedFormID,
      this.currentConfiguration(),
    );
    this.isSaving = false;
    const message = result === CardConfigurationUpdateResult.Updated
      ? L.text('card.center.saved')
      : result === CardConfigurationUpdateResult.RefreshPending
        ? L.text('card.center.refresh_pending')
        : L.text('card.center.save_failed');
    promptAction.showToast({ message });
    if (result !== CardConfigurationUpdateResult.Missing) {
      this.cards = CardInstallService.cardInstances();
    }
  }

  private openCardManager(): void {
    this.cardIDsBeforeAdding = this.cards.map((card: CountdownCardInstance) => card.id);
    this.isAwaitingCardAddition = true;
    if (!CardInstallService.openManager()) {
      this.isAwaitingCardAddition = false;
      this.cardIDsBeforeAdding = [];
      promptAction.showToast({ message: L.text('activation.card_fallback') });
    }
  }

  private currentConfiguration(): CountdownCardConfiguration {
    return {
      contentMode: this.contentMode,
      featuredEventID: this.contentMode === CountdownCardContentMode.Featured
        ? this.featuredEventID
        : undefined,
      theme: this.theme,
      configurationVersion: COUNTDOWN_CARD_CONFIGURATION_VERSION,
    };
  }

  private canSave(): boolean {
    if (this.cards.length === 0) {
      return true;
    }

    return this.selectedFormID.length > 0 &&
      (this.contentMode !== CountdownCardContentMode.Featured || this.featuredEventID.length > 0);
  }

  private sizeLabel(size: CountdownCardSize): string {
    if (size === CountdownCardSize.Small) {
      return L.text('card.center.size_small');
    }

    if (size === CountdownCardSize.Large) {
      return L.text('card.center.size_large');
    }

    return L.text('card.center.size_medium');
  }

  private shortFormID(formID: string): string {
    const suffix = formID.length > 4 ? formID.slice(formID.length - 4) : formID;
    return L.format('card.center.form_label', suffix);
  }
}
