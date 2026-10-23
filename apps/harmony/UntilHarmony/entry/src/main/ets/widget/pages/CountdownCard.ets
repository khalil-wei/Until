import { CardPalette } from '../../card/CardPalette';
let storage = new LocalStorage();

@Entry(storage)
@Component
struct CountdownCard {
  @LocalStorageProp('updateToken')
  @Watch('onUpdateToken')
  updateToken: string = '';
  @State renderRevision: number = 0;
  @LocalStorageProp('cardSize') cardSize: string = 'medium';
  @LocalStorageProp('theme') theme: string = 'colorful';
  @LocalStorageProp('appTitle') appTitle: string = 'Until';
  @LocalStorageProp('appSubtitle') appSubtitle: string = 'Countdown';
  @LocalStorageProp('sectionTitle') sectionTitle: string = 'Upcoming';
  @LocalStorageProp('brandShort') brandShort: string = 'UNTIL';
  @LocalStorageProp('nextLabel') nextLabel: string = 'NEXT';
  @LocalStorageProp('largeTitle') largeTitle: string = 'Until';
  @LocalStorageProp('largeSubtitle') largeSubtitle: string = 'Keep meaningful days in sight';
  @LocalStorageProp('moreEventsTitle') moreEventsTitle: string = 'Coming up next';
  @LocalStorageProp('emptyTitle') emptyTitle: string = 'No events';
  @LocalStorageProp('emptySubtitle') emptySubtitle: string = 'Open app to add';
  @LocalStorageProp('eventCountText') eventCountText: string = '0';
  @LocalStorageProp('hasEvents') hasEvents: string = 'false';

  @LocalStorageProp('entry0Visible') entry0Visible: string = 'false';
  @LocalStorageProp('entry0ID') entry0ID: string = '';
  @LocalStorageProp('entry0Title') entry0Title: string = '';
  @LocalStorageProp('entry0DateText') entry0DateText: string = '';
  @LocalStorageProp('entry0CountdownBadgeText') entry0CountdownBadgeText: string = '';
  @LocalStorageProp('entry0CountdownUnitText') entry0CountdownUnitText: string = '';
  @LocalStorageProp('entry0ShouldShowUnit') entry0ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry0CategorySymbol') entry0CategorySymbol: string = '';
  @LocalStorageProp('entry0CategoryLabel') entry0CategoryLabel: string = '';
  @LocalStorageProp('entry0UrgencyColor') entry0UrgencyColor: string = '#087F75';

  @LocalStorageProp('entry1Visible') entry1Visible: string = 'false';
  @LocalStorageProp('entry1ID') entry1ID: string = '';
  @LocalStorageProp('entry1Title') entry1Title: string = '';
  @LocalStorageProp('entry1DateText') entry1DateText: string = '';
  @LocalStorageProp('entry1CountdownBadgeText') entry1CountdownBadgeText: string = '';
  @LocalStorageProp('entry1CountdownUnitText') entry1CountdownUnitText: string = '';
  @LocalStorageProp('entry1ShouldShowUnit') entry1ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry1UrgencyColor') entry1UrgencyColor: string = '#087F75';
  @LocalStorageProp('entry1CategorySymbol') entry1CategorySymbol: string = '';

  @LocalStorageProp('entry2Visible') entry2Visible: string = 'false';
  @LocalStorageProp('entry2ID') entry2ID: string = '';
  @LocalStorageProp('entry2Title') entry2Title: string = '';
  @LocalStorageProp('entry2DateText') entry2DateText: string = '';
  @LocalStorageProp('entry2CountdownBadgeText') entry2CountdownBadgeText: string = '';
  @LocalStorageProp('entry2CountdownUnitText') entry2CountdownUnitText: string = '';
  @LocalStorageProp('entry2ShouldShowUnit') entry2ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry2UrgencyColor') entry2UrgencyColor: string = '#087F75';
  @LocalStorageProp('entry2CategorySymbol') entry2CategorySymbol: string = '';

  @LocalStorageProp('entry3Visible') entry3Visible: string = 'false';
  @LocalStorageProp('entry3ID') entry3ID: string = '';
  @LocalStorageProp('entry3Title') entry3Title: string = '';
  @LocalStorageProp('entry3DateText') entry3DateText: string = '';
  @LocalStorageProp('entry3CountdownBadgeText') entry3CountdownBadgeText: string = '';
  @LocalStorageProp('entry3CountdownUnitText') entry3CountdownUnitText: string = '';
  @LocalStorageProp('entry3ShouldShowUnit') entry3ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry3UrgencyColor') entry3UrgencyColor: string = '#087F75';
  @LocalStorageProp('entry3CategorySymbol') entry3CategorySymbol: string = '';

  @LocalStorageProp('entry4Visible') entry4Visible: string = 'false';
  @LocalStorageProp('entry4ID') entry4ID: string = '';
  @LocalStorageProp('entry4Title') entry4Title: string = '';
  @LocalStorageProp('entry4DateText') entry4DateText: string = '';
  @LocalStorageProp('entry4CountdownBadgeText') entry4CountdownBadgeText: string = '';
  @LocalStorageProp('entry4CountdownUnitText') entry4CountdownUnitText: string = '';
  @LocalStorageProp('entry4ShouldShowUnit') entry4ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry4UrgencyColor') entry4UrgencyColor: string = '#087F75';
  @LocalStorageProp('entry4CategorySymbol') entry4CategorySymbol: string = '';

  @LocalStorageProp('entry5Visible') entry5Visible: string = 'false';
  @LocalStorageProp('entry5ID') entry5ID: string = '';
  @LocalStorageProp('entry5Title') entry5Title: string = '';
  @LocalStorageProp('entry5DateText') entry5DateText: string = '';
  @LocalStorageProp('entry5CountdownBadgeText') entry5CountdownBadgeText: string = '';
  @LocalStorageProp('entry5CountdownUnitText') entry5CountdownUnitText: string = '';
  @LocalStorageProp('entry5ShouldShowUnit') entry5ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry5UrgencyColor') entry5UrgencyColor: string = '#087F75';
  @LocalStorageProp('entry5CategorySymbol') entry5CategorySymbol: string = '';

  build() {
    Column() {
      Text(this.updateToken)
        .width(0)
        .height(0)
        .opacity(0)

      if (this.renderRevision % 2 === 0) {
        this.cardContent()
      } else {
        this.cardContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.cardBackgroundColor())
  }

  @Builder
  private cardContent() {
    if (this.isSmallCard()) {
      this.smallCard()
    } else if (this.isLargeCard()) {
      this.largeCard()
    } else {
      this.mediumCard()
    }
  }

  @Builder
  private smallCard() {
    if (this.hasEvents === 'true') {
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Image(CardPalette.categoryIcon(this.entry0CategorySymbol))
            .width(22).height(22).padding(5)
            .fillColor(this.heroColor())
            .borderRadius(7)
            .backgroundColor(this.categoryTintColor(this.entry0CategorySymbol))
          Text(this.entry0CategoryLabel)
            .fontSize(10).fontWeight(FontWeight.Medium)
            .fontColor(this.secondaryTextColor())
            .maxLines(1)
          Blank()
          Text(this.brandShort)
            .fontSize(9).fontWeight(FontWeight.Bold)
            .fontColor(this.secondaryTextColor())
        }
        .width('100%')
        Text(this.entry0Title)
          .fontSize(15).fontWeight(FontWeight.Bold)
          .fontColor(this.primaryTextColor())
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 4 }) {
          Text(this.entry0CountdownBadgeText)
            .fontSize(this.smallBadgeFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(this.heroColor())
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (this.entry0ShouldShowUnit === 'true') {
            Text(this.entry0CountdownUnitText)
              .fontSize(12).fontColor(this.secondaryTextColor())
          }
        }
        .width('100%').alignItems(VerticalAlign.Bottom)
        Text(this.entry0DateText)
          .fontSize(10).fontColor(this.secondaryTextColor())
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding(16)
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { target: 'event', eventID: this.entry0ID },
        });
      })
    } else {
      this.emptyCard()
    }
  }

  @Builder
  private mediumCard() {
    if (this.hasEvents === 'true') {
      Column({ space: 2 }) {
        Row({ space: 8 }) {
          Image(CardPalette.categoryIcon(this.entry0CategorySymbol))
            .width(24).height(24).padding(5)
            .fillColor(this.heroColor())
          Column({ space: 2 }) {
            Text(this.entry0Title)
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.primaryTextColor())
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.entry0DateText)
              .fontSize(10).fontColor(this.secondaryTextColor())
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Row({ space: 3 }) {
            Text(this.entry0CountdownBadgeText)
              .fontSize(this.mediumHeroFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(this.heroColor())
              .maxLines(1)
            if (this.entry0ShouldShowUnit === 'true') {
              Text(this.entry0CountdownUnitText)
                .fontSize(10).fontColor(this.secondaryTextColor())
            }
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%').height(46)
        .padding({ left: 8, right: 8 })
        .borderRadius(12)
        .backgroundColor(this.categoryTintColor(this.entry0CategorySymbol))
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { target: 'event', eventID: this.entry0ID },
          });
        })
        this.compactEventRow(this.entry1Visible, this.entry1ID, this.entry1CategorySymbol,
          this.entry1Title, this.entry1DateText, this.entry1CountdownBadgeText, this.entry1UrgencyColor)
        this.compactEventRow(this.entry2Visible, this.entry2ID, this.entry2CategorySymbol,
          this.entry2Title, this.entry2DateText, this.entry2CountdownBadgeText, this.entry2UrgencyColor)
        this.compactEventRow(this.entry3Visible, this.entry3ID, this.entry3CategorySymbol,
          this.entry3Title, this.entry3DateText, this.entry3CountdownBadgeText, this.entry3UrgencyColor)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    } else {
      this.emptyCard()
    }
  }

  @Builder
  private largeCard() {
    if (this.hasEvents === 'true') {
      Column({ space: this.largeLayoutSpacing() }) {
        Row({ space: 8 }) {
          Text(this.brandShort)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.secondaryTextColor())
            .letterSpacing(1.2)
          Text(this.sectionTitle)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.secondaryTextColor())
          Blank()
          Text(this.eventCountText)
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.secondaryTextColor())
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
            .backgroundColor(this.brandTintColor())
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(26)

        Row({ space: 12 }) {
          Column({ space: 3 }) {
            Row({ space: 5 }) {
              Image(CardPalette.categoryIcon(this.entry0CategorySymbol))
                .width(13).height(13).fillColor(this.heroColor())
              Text(this.entry0CategoryLabel)
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.secondaryTextColor())
            }
            Text(this.entry0Title)
              .fontSize(this.largeHeroTitleFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(this.primaryTextColor())
              .maxLines(this.largeHeroTitleMaxLines())
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.entry0DateText)
              .fontSize(10)
              .fontColor(this.secondaryTextColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start)

          Row({ space: 5 }) {
            Text(this.entry0CountdownBadgeText)
              .fontSize(this.largeHeroFontSize())
              .fontWeight(FontWeight.Bold)
                .fontColor(this.heroColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.entry0ShouldShowUnit === 'true') {
              Text(this.entry0CountdownUnitText)
                .fontSize(this.largeHeroUnitFontSize())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.secondaryTextColor())
            }
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .height(this.largeHeroHeight())
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(14)
        .backgroundColor(this.categoryTintColor(this.entry0CategorySymbol))
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { target: 'event', eventID: this.entry0ID },
          });
        })

        if (this.largeSecondaryEventCount() > 0) {
          Divider()
            .strokeWidth(0.5)
            .color(this.timelineDividerColor())
          Column() {
            this.largeEventRow(
              this.entry1Visible,
              this.entry1ID,
              this.entry1CategorySymbol,
              this.entry1Title,
              this.entry1DateText,
              this.entry1CountdownBadgeText,
              this.entry1UrgencyColor,
              this.hasVisibleLargeEventAfter(1),
            )
            this.largeEventRow(
              this.entry2Visible,
              this.entry2ID,
              this.entry2CategorySymbol,
              this.entry2Title,
              this.entry2DateText,
              this.entry2CountdownBadgeText,
              this.entry2UrgencyColor,
              this.hasVisibleLargeEventAfter(2),
            )
            this.largeEventRow(
              this.entry3Visible,
              this.entry3ID,
              this.entry3CategorySymbol,
              this.entry3Title,
              this.entry3DateText,
              this.entry3CountdownBadgeText,
              this.entry3UrgencyColor,
              this.hasVisibleLargeEventAfter(3),
            )
            this.largeEventRow(
              this.entry4Visible,
              this.entry4ID,
              this.entry4CategorySymbol,
              this.entry4Title,
              this.entry4DateText,
              this.entry4CountdownBadgeText,
              this.entry4UrgencyColor,
              this.hasVisibleLargeEventAfter(4),
            )
            this.largeEventRow(
              this.entry5Visible,
              this.entry5ID,
              this.entry5CategorySymbol,
              this.entry5Title,
              this.entry5DateText,
              this.entry5CountdownBadgeText,
              this.entry5UrgencyColor,
              false,
            )
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.SpaceEvenly)
           .padding({ left: 4, right: 4 })
        }
      }
      .width('100%')
      .height('100%')
      .padding(this.largeOuterPadding())
    } else {
      this.emptyCard()
    }
  }

  @Builder
  private largeEventRow(
    visible: string,
    eventID: string,
    categorySymbol: string,
    title: string,
    dateText: string,
    countdownBadgeText: string,
    urgencyColor: string,
    showDivider: boolean,
  ) {
    if (visible === 'true') {
      Column() {
        Row({ space: 9 }) {
          Image(CardPalette.categoryIcon(categorySymbol))
            .padding(4)
            .fillColor(this.cardCategoryColor(categorySymbol, urgencyColor))
            .width(this.largeEventIconSize())
            .height(this.largeEventIconSize())
            .borderRadius(this.largeEventIconSize() / 2)
            .backgroundColor(this.categoryTintColor(categorySymbol))
          Column({ space: 2 }) {
            Text(title)
              .fontSize(this.largeEventTitleFontSize())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.primaryTextColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(dateText)
              .fontSize(this.largeEventDateFontSize())
              .fontColor(this.secondaryTextColor())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Row({ space: 3 }) {
            Text(countdownBadgeText)
              .fontSize(this.largeEventCountdownFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(this.cardCategoryColor(categorySymbol, urgencyColor))
              .maxLines(1)
            if (this.futureSuffix(countdownBadgeText).length > 0) {
              Text(this.futureSuffix(countdownBadgeText))
                .fontSize(10)
                .fontColor(this.secondaryTextColor())
            }
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .height(this.largeEventRowHeight())

        if (showDivider) {
          Divider()
            .strokeWidth(0.5)
            .color(this.timelineDividerColor())
            .margin({ left: this.largeEventIconSize() + 9, right: 4 })
        }
      }
      .width('100%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { target: 'event', eventID },
        });
      })
    }
  }

  @Builder
  private compactEventRow(
    visible: string,
    eventID: string,
    categorySymbol: string,
    title: string,
    dateText: string,
    countdownBadgeText: string,
    urgencyColor: string,
  ) {
    if (visible === 'true') {
      Row({ space: 7 }) {
        Image(CardPalette.categoryIcon(categorySymbol))
          .width(18).height(18).padding(3).fillColor(this.cardCategoryColor(categorySymbol, urgencyColor))
          .borderRadius(9)
          .backgroundColor(this.categoryTintColor(categorySymbol))

        Column({ space: 2 }) {
          Text(title)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.primaryTextColor())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(dateText)
            .fontSize(9)
            .fontColor(this.secondaryTextColor())
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: 2 }) {
          Text(countdownBadgeText)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.cardCategoryColor(categorySymbol, urgencyColor))
            .maxLines(1)
          if (this.futureSuffix(countdownBadgeText).length > 0) {
            Text(this.futureSuffix(countdownBadgeText))
              .fontSize(9)
              .fontColor(this.secondaryTextColor())
          }
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .height(30)
      .padding({ left: 6, right: 6 })
      .borderRadius(8)
      .backgroundColor(this.categoryTintColor(categorySymbol))
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { target: 'event', eventID },
        });
      })
    }
  }

  @Builder
  private emptyCard() {
    Column({ space: 6 }) {
      Image($r('app.media.ui_add'))
        .width(28).height(28)
        .fillColor(CardPalette.accent(this.theme))
      Text(this.emptyTitle)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.primaryTextColor())
      Text(this.emptySubtitle)
        .fontSize(11)
        .fontColor(this.secondaryTextColor())
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { target: 'add', eventID: '' },
      });
    })
  }

  private isSmallCard(): boolean {
    return this.cardSize === 'small';
  }

  private isLargeCard(): boolean {
    return this.cardSize === 'large';
  }

  private smallBadgeFontSize(): number {
    const length = this.entry0CountdownBadgeText.length;

    if (length > 12) {
      return 15;
    }

    if (length > 7) {
      return 20;
    }

    return length > 3 ? 24 : length > 2 ? 30 : 38;
  }

  private mediumHeroFontSize(): number {
    const length = this.entry0CountdownBadgeText.length;

    if (length > 7) {
      return 16;
    }

    return length > 2 ? 25 : 31;
  }

  private largeHeroFontSize(): number {
    const length = this.entry0CountdownBadgeText.length;
    const compact = this.largeSecondaryEventCount() >= 4;
    return length > 7 ? 18 : length > 3 ? (compact ? 23 : 25) : length > 2 ? (compact ? 28 : 30) : compact ? 30 : 32;
  }

  private largeHeroTitleFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 17 : 18;
  }

  private largeHeroTitleMaxLines(): number {
    return 1;
  }

  private largeHeroUnitFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 11 : 12;
  }

  private largeSecondaryEventCount(): number {
    let count = 0;

    if (this.entry1Visible === 'true') {
      count += 1;
    }
    if (this.entry2Visible === 'true') {
      count += 1;
    }
    if (this.entry3Visible === 'true') {
      count += 1;
    }
    if (this.entry4Visible === 'true') {
      count += 1;
    }
    if (this.entry5Visible === 'true') {
      count += 1;
    }

    return count;
  }

  private largeOuterPadding(): number {
    const count = this.largeSecondaryEventCount();
    return count >= 5 ? 8 : count >= 4 ? 10 : count >= 3 ? 12 : 14;
  }

  private largeLayoutSpacing(): number {
    const count = this.largeSecondaryEventCount();
    return count >= 5 ? 4 : count >= 4 ? 5 : count >= 3 ? 6 : 8;
  }

  private largeHeroHeight(): number {
    const count = this.largeSecondaryEventCount();
    return count >= 5 ? 66 : count >= 4 ? 72 : count >= 3 ? 78 : 84;
  }

  private largeEventRowHeight(): number {
    const count = this.largeSecondaryEventCount();
    return count >= 5 ? 36 : count >= 4 ? 40 : count >= 3 ? 42 : 46;
  }

  private largeEventIconSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 22 : 24;
  }

  private largeEventTitleFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 12 : 13;
  }

  private largeEventDateFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 9 : 10;
  }

  private largeEventCountdownFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 14 : 15;
  }

  private hasVisibleLargeEventAfter(index: number): boolean {
    if (index < 2 && this.entry2Visible === 'true') {
      return true;
    }
    if (index < 3 && this.entry3Visible === 'true') {
      return true;
    }
    if (index < 4 && this.entry4Visible === 'true') {
      return true;
    }
    return index < 5 && this.entry5Visible === 'true';
  }

  private brandTintColor(): string {
    return this.theme === 'midnight' ? '#20FFFFFF' : '#14087F75';
  }

  private timelineDividerColor(): string {
    return this.theme === 'midnight' ? '#24FFFFFF' : '#12000000';
  }

  private futureSuffix(countdownBadgeText: string): string {
    return /^\d+\+?$/.test(countdownBadgeText) ? this.entry0CountdownUnitText : '';
  }

  private heroColor(): string {
    if (this.theme === 'minimal') {
      return CardPalette.accent(this.theme);
    }

    if (this.theme === 'midnight') {
      return CardPalette.accent(this.theme);
    }

    return this.cardCategoryColor(this.entry0CategorySymbol, this.entry0UrgencyColor);
  }

  private cardCategoryColor(symbol: string, fallback: string): string {
    if (this.theme === 'midnight') {
      return symbol === '🎂' ? '#F2B678' : symbol === '💝' ? '#F396B4' : '#B8AEF1';
    }
    return this.theme === 'minimal' ? CardPalette.accent(this.theme) : CardPalette.categoryColor(symbol, fallback);
  }

  private categoryTintColor(symbol: string): string {
    return this.theme === 'midnight' ? '#252A3B' :
      this.theme === 'minimal' ? '#E6E2F8' : CardPalette.categorySoft(symbol);
  }

  private cardBackgroundColor(): string {
    return CardPalette.background(this.theme);
  }

  private primaryTextColor(): string {
    return CardPalette.primary(this.theme);
  }

  private secondaryTextColor(): string {
    return CardPalette.secondary(this.theme);
  }

  private onUpdateToken(): void {
    this.renderRevision += 1;
    console.info(`Countdown card UI received token=${this.updateToken}`);
  }
}
