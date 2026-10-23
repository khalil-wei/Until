import { CardPalette } from '../card/CardPalette';
import { CardTimelineProvider } from '../card/CardTimelineProvider';
import { AppPrimaryButton } from '../components/AppPrimaryButton';
import { AppPageHeader } from '../components/AppPageHeader';
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
        Column({ space: 26 }) {
          if (this.cards.length === 0) {
            this.emptyCardState()
          } else {
            this.installedCardsSection()
            if (this.events.length > 0) {
              this.cardPreview()
            }
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
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)

      this.actionArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.pageBackground)
  }

  @Builder
  private navigationBar() {
    AppPageHeader({
      title: L.text('card.center.title'),
      onBack: () => { router.back(); },
    })
  }

  @Builder
  private emptyCardState() {
    Column({ space: 14 }) {
      Image($r('app.media.ui_cards'))
        .fillColor(AppTheme.brand)
        .padding(12)
      .width(48)
      .height(48)
      .borderRadius(14)
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
        Image($r('app.media.ui_check'))
          .width(18).height(18).fillColor(AppTheme.brand)
        Text(L.text('card.center.empty_step'))
          .fontSize(12)
          .fontColor(AppTheme.secondaryText)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .borderRadius(AppTheme.controlRadius)
      .backgroundColor(AppTheme.materialBackground)
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 48 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private installedCardsSection() {
    Column({ space: 12 }) {
      Row() {
        Text(L.text('card.center.installed'))
          .fontSize(AppTheme.sectionTitleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
        Blank()
        Text(`${this.cards.length}`)
          .fontSize(13).fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.secondaryText)
      }
      .width('100%')

      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.cards, (card: CountdownCardInstance) => {
            Button({ type: ButtonType.Normal }) {
              Column({ space: 5 }) {
                Stack() {
                  Row()
                    .width(this.cardShapeWidth(card.size))
                    .height(this.cardShapeHeight(card.size))
                    .backgroundColor(CardPalette.background(card.theme))
                    .border({ width: 1, color: this.themeActionColor(card.theme) })
                    .borderRadius(5)
                  Image($r('app.media.category_anniversary'))
                    .width(11).height(11)
                    .fillColor(this.themeActionColor(card.theme))
                }
                .width(46).height(28)
                .alignContent(Alignment.Center)
                Text(this.sizeLabel(card.size))
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppTheme.primaryText)
                Text(this.shortFormID(card.id))
                  .fontSize(10)
                  .fontColor(AppTheme.secondaryText)
              }
              .alignItems(HorizontalAlign.Center)
            }
            .width(98).height(100)
            .border({ width: { bottom: card.id === this.selectedFormID ? 3 : 0 },
              color: this.themeActionColor(card.theme) })
            .borderRadius(12)
            .backgroundColor(card.id === this.selectedFormID
              ? this.themeSelectionBackground(card.theme) : AppTheme.materialBackground)
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
  private cardPreview() {
    Column({ space: 12 }) {
      this.sectionTitle(L.text('card.center.preview'))
      Column({ space: 18 }) {
        Row({ space: 8 }) {
          Image(EventPresentation.categoryIcon(this.previewEvent().category))
            .width(17).height(17)
            .fillColor(EventPresentation.categoryColor(this.previewEvent().category))
          Text(EventPresentation.categoryLabel(this.previewEvent().category))
            .fontSize(12).fontWeight(FontWeight.Bold)
            .fontColor(EventPresentation.categoryColor(this.previewEvent().category))
          Blank()
          Text(this.sizeLabel(this.previewSize()))
            .fontSize(12).fontColor(AppTheme.secondaryText)
        }
        .width('100%')
        Row() {
          Text(this.previewEvent().title)
            .fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
            .maxLines(2).layoutWeight(1)
          Text(EventPresentation.countdownBadgeText(this.previewEvent()))
            .fontSize(42).fontWeight(FontWeight.Bold)
            .fontColor(EventPresentation.categoryColor(this.previewEvent().category))
        }
        .width('100%')
        Text(EventPresentation.compactDate(this.previewEvent().nextOccurrence, this.previewEvent().dateCalendar))
          .fontSize(12).fontColor(AppTheme.secondaryText)
          .width('100%')
      }
      .width('100%')
      .padding(18)
      .borderRadius(20)
      .backgroundColor(CardPalette.background(this.theme))
    }
    .width('100%')
  }

  @Builder
  private contentSection() {
    Column({ space: 12 }) {
      this.sectionTitle(L.text('card.center.content'))

      Column({ space: 8 }) {
        this.contentModeButton(
          L.text('card.center.automatic'), L.text('card.center.automatic_detail'),
          $r('app.media.ui_calendar'), CountdownCardContentMode.Automatic)
        this.contentModeButton(
          L.text('card.center.fixed'), L.text('card.center.fixed_detail'),
          $r('app.media.ui_cards'), CountdownCardContentMode.Featured)

        if (this.contentMode === CountdownCardContentMode.Featured) {
          Text(L.text('card.center.fixed_helper'))
            .width('100%')
            .fontSize(12)
            .fontColor(AppTheme.secondaryText)
            .padding({ left: 4, top: 6, bottom: 2 })

          Column({ space: 1 }) {
            ForEach(this.events, (event: CountdownEvent) => {
              Button({ type: ButtonType.Normal }) {
                Row({ space: 10 }) {
                  Image(EventPresentation.categoryIcon(event.category))
                    .width(32)
                    .height(32)
                    .padding(7)
                    .fillColor(EventPresentation.categoryColor(event.category))
                    .borderRadius(10)
                    .backgroundColor(EventPresentation.categoryBackground(event.category))
                  Column({ space: 2 }) {
                    Text(event.title)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppTheme.primaryText)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(EventPresentation.compactDate(event.nextOccurrence, event.dateCalendar))
                      .fontSize(12)
                      .fontColor(AppTheme.secondaryText)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Image($r('app.media.ui_check'))
                    .width(20).height(20)
                    .fillColor(EventPresentation.categoryColor(event.category))
                    .opacity(event.id === this.featuredEventID ? 1 : 0)
                }
                .width('100%')
              }
              .width('100%')
              .constraintSize({ minHeight: 64 })
              .padding({ left: 12, right: 12 })
              .borderRadius(12)
              .backgroundColor(event.id === this.featuredEventID
                ? EventPresentation.categoryBackground(event.category) : Color.Transparent)
              .onClick(() => {
                this.featuredEventID = event.id;
              })
            }, (event: CountdownEvent) => event.id)
          }
          .width('100%')
          .padding(4)
          .borderRadius(12)
          .backgroundColor(AppTheme.materialBackground)
        }
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private contentModeButton(title: string, detail: string, icon: Resource, mode: CountdownCardContentMode) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        Image(icon)
          .width(32).height(32).padding(7)
          .fillColor(this.contentMode === mode ? this.themeActionColor(this.theme) : AppTheme.secondaryText)
          .borderRadius(10)
          .backgroundColor(this.contentMode === mode
            ? this.themeSelectionBackground(this.theme) : AppTheme.materialBackground)
        Column({ space: 3 }) {
          Text(title)
            .fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
          Text(detail)
            .fontSize(12).fontColor(AppTheme.secondaryText)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        Image($r('app.media.ui_check'))
          .width(20).height(20).fillColor(this.themeActionColor(this.theme))
          .opacity(this.contentMode === mode ? 1 : 0)
      }
      .width('100%')
    }
      .width('100%').height(68)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.contentMode === mode
        ? this.themeSelectionBackground(this.theme) : AppTheme.materialBackground)
      .borderRadius(12)
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
    Column({ space: 12 }) {
      this.sectionTitle(L.text('card.center.palette'))
      Row({ space: 8 }) {
        this.paletteButton(
          L.text('card.center.palette_smart'),
          CountdownCardTheme.Colorful,
          CardPalette.background(CountdownCardTheme.Colorful),
          this.previewAccent(CountdownCardTheme.Colorful),
        )
        this.paletteButton(
          L.text('card.center.palette_indigo'),
          CountdownCardTheme.Minimal,
          CardPalette.background(CountdownCardTheme.Minimal),
          this.previewAccent(CountdownCardTheme.Minimal),
        )
        this.paletteButton(
          L.text('card.center.palette_dark'),
          CountdownCardTheme.Midnight,
          CardPalette.background(CountdownCardTheme.Midnight),
          this.previewAccent(CountdownCardTheme.Midnight),
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
    Button({ type: ButtonType.Normal }) {
      Column({ space: 7 }) {
        Row({ space: 4 }) {
          Image(CardPalette.categoryIcon(this.previewCategorySymbol()))
            .width(13).height(13).fillColor(heroColor)
          Text('18')
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(heroColor)
        }
        .width('100%').height(40)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(outerColor)
        .borderRadius(8)

        Text(title)
          .fontSize(12)
          .fontWeight(this.theme === theme ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.theme === theme ? AppTheme.primaryText : AppTheme.secondaryText)
      }
      .width('100%').alignItems(HorizontalAlign.Center)
    }
    .height(96)
    .layoutWeight(1)
    .padding({ left: 8, right: 8, top: 9, bottom: 8 })
    .backgroundColor(this.theme === theme ? this.themeSelectionBackground(theme) : AppTheme.materialBackground)
    .border({ width: { bottom: this.theme === theme ? 3 : 0 }, color: this.themeActionColor(theme) })
    .borderRadius(12)
    .onClick(() => {
      this.theme = theme;
    })
  }

  @Builder
  private actionArea() {
    Column({ space: 8 }) {
      if (this.cards.length === 0) {
        Text(L.text('card.center.size_hint'))
          .fontSize(12)
          .fontColor(AppTheme.secondaryText)
          .textAlign(TextAlign.Center)
          .maxLines(2)
      }

      AppPrimaryButton({
        label: this.cards.length === 0 ? L.text('card.center.add') : L.text('card.center.save_refresh'),
        available: this.canSave(),
        busy: this.isSaving,
        accent: this.themeActionColor(this.theme),
        onAction: () => { this.performPrimaryAction(); },
      })

      if (this.cards.length > 0) {
        Button({ type: ButtonType.Normal }) {
          Row({ space: 7 }) {
            Image($r('app.media.ui_add'))
              .width(18).height(18).fillColor(this.themeActionColor(this.theme))
            Text(L.text('card.center.add_another'))
              .fontSize(13).fontWeight(FontWeight.Medium)
              .fontColor(this.themeActionColor(this.theme))
          }
        }
          .width('100%').height(44)
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
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppTheme.secondaryText)
      .letterSpacing(1)
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

  private previewSize(): CountdownCardSize {
    const selected = this.cards.find((card: CountdownCardInstance) => card.id === this.selectedFormID);
    return selected?.size ?? CountdownCardSize.Small;
  }

  private previewEvent(): CountdownEvent {
    if (this.contentMode === CountdownCardContentMode.Featured) {
      const featured = this.events.find((event: CountdownEvent) => event.id === this.featuredEventID);
      if (featured !== undefined) {
        return featured;
      }
    }
    return this.events[0];
  }

  private themeSelectionBackground(theme: CountdownCardTheme): string {
    return theme === CountdownCardTheme.Minimal ? '#F0EDFC' :
      theme === CountdownCardTheme.Midnight ? '#EDF0F4' : '#E8F6F2';
  }

  private themeActionColor(theme: CountdownCardTheme): string {
    return theme === CountdownCardTheme.Minimal ? '#6660BD' :
      theme === CountdownCardTheme.Midnight ? '#383951' : '#087F75';
  }

  private cardShapeWidth(size: CountdownCardSize): number {
    return size === CountdownCardSize.Medium ? 42 : size === CountdownCardSize.Large ? 28 : 24;
  }

  private cardShapeHeight(size: CountdownCardSize): number {
    return size === CountdownCardSize.Large ? 28 : 23;
  }

  private previewCategorySymbol(): string {
    const featuredID = this.contentMode === CountdownCardContentMode.Featured ? this.featuredEventID : undefined;
    const entries = CardTimelineProvider.entries(this.events, 1, new Date(), featuredID);
    return entries.length > 0 ? entries[0].categorySymbol : '✨';
  }

  private previewAccent(theme: CountdownCardTheme): string {
    return theme === CountdownCardTheme.Colorful
      ? CardPalette.categoryColor(this.previewCategorySymbol()) : CardPalette.accent(theme);
  }
}
