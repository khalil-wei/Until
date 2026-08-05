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
  @LocalStorageProp('entry0UrgencyColor') entry0UrgencyColor: string = '#079D89';

  @LocalStorageProp('entry1Visible') entry1Visible: string = 'false';
  @LocalStorageProp('entry1ID') entry1ID: string = '';
  @LocalStorageProp('entry1Title') entry1Title: string = '';
  @LocalStorageProp('entry1DateText') entry1DateText: string = '';
  @LocalStorageProp('entry1CountdownBadgeText') entry1CountdownBadgeText: string = '';
  @LocalStorageProp('entry1CountdownUnitText') entry1CountdownUnitText: string = '';
  @LocalStorageProp('entry1ShouldShowUnit') entry1ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry1UrgencyColor') entry1UrgencyColor: string = '#079D89';
  @LocalStorageProp('entry1CategorySymbol') entry1CategorySymbol: string = '';

  @LocalStorageProp('entry2Visible') entry2Visible: string = 'false';
  @LocalStorageProp('entry2ID') entry2ID: string = '';
  @LocalStorageProp('entry2Title') entry2Title: string = '';
  @LocalStorageProp('entry2DateText') entry2DateText: string = '';
  @LocalStorageProp('entry2CountdownBadgeText') entry2CountdownBadgeText: string = '';
  @LocalStorageProp('entry2CountdownUnitText') entry2CountdownUnitText: string = '';
  @LocalStorageProp('entry2ShouldShowUnit') entry2ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry2UrgencyColor') entry2UrgencyColor: string = '#079D89';
  @LocalStorageProp('entry2CategorySymbol') entry2CategorySymbol: string = '';

  @LocalStorageProp('entry3Visible') entry3Visible: string = 'false';
  @LocalStorageProp('entry3ID') entry3ID: string = '';
  @LocalStorageProp('entry3Title') entry3Title: string = '';
  @LocalStorageProp('entry3DateText') entry3DateText: string = '';
  @LocalStorageProp('entry3CountdownBadgeText') entry3CountdownBadgeText: string = '';
  @LocalStorageProp('entry3CountdownUnitText') entry3CountdownUnitText: string = '';
  @LocalStorageProp('entry3ShouldShowUnit') entry3ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry3UrgencyColor') entry3UrgencyColor: string = '#079D89';
  @LocalStorageProp('entry3CategorySymbol') entry3CategorySymbol: string = '';

  @LocalStorageProp('entry4Visible') entry4Visible: string = 'false';
  @LocalStorageProp('entry4ID') entry4ID: string = '';
  @LocalStorageProp('entry4Title') entry4Title: string = '';
  @LocalStorageProp('entry4DateText') entry4DateText: string = '';
  @LocalStorageProp('entry4CountdownBadgeText') entry4CountdownBadgeText: string = '';
  @LocalStorageProp('entry4CountdownUnitText') entry4CountdownUnitText: string = '';
  @LocalStorageProp('entry4ShouldShowUnit') entry4ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry4UrgencyColor') entry4UrgencyColor: string = '#079D89';
  @LocalStorageProp('entry4CategorySymbol') entry4CategorySymbol: string = '';

  @LocalStorageProp('entry5Visible') entry5Visible: string = 'false';
  @LocalStorageProp('entry5ID') entry5ID: string = '';
  @LocalStorageProp('entry5Title') entry5Title: string = '';
  @LocalStorageProp('entry5DateText') entry5DateText: string = '';
  @LocalStorageProp('entry5CountdownBadgeText') entry5CountdownBadgeText: string = '';
  @LocalStorageProp('entry5CountdownUnitText') entry5CountdownUnitText: string = '';
  @LocalStorageProp('entry5ShouldShowUnit') entry5ShouldShowUnit: string = 'false';
  @LocalStorageProp('entry5UrgencyColor') entry5UrgencyColor: string = '#079D89';
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
      Column() {
      Column({ space: 7 }) {
        Row({ space: 6 }) {
          Text(this.entry0CategorySymbol)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .width(18)
            .height(18)
            .textAlign(TextAlign.Center)
            .borderRadius(9)
            .backgroundColor('#33FFFFFF')

          Text(this.entry0CategoryLabel)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text(this.brandShort)
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .fontColor('#DFFFFFFF')
        }
        .width('100%')

        Text(this.entry0Title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        .width('100%')

        Blank()

        Row({ space: 5 }) {
          Text(this.entry0CountdownBadgeText)
            .fontSize(this.smallBadgeFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.entry0ShouldShowUnit === 'true') {
            Text(this.entry0CountdownUnitText)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E8FFFFFF')
              .maxLines(1)
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)

        Text(this.entry0DateText)
          .fontSize(9)
          .fontWeight(FontWeight.Medium)
          .fontColor('#DFFFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 13, right: 13, top: 12, bottom: 12 })
      .borderRadius(22)
      .backgroundColor(this.heroColor())
      }
      .width('100%')
      .height('100%')
      .padding(9)
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
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Row() {
            Text(this.entry0CategorySymbol)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Blank()
            Text(this.nextLabel)
              .fontSize(8)
              .fontWeight(FontWeight.Bold)
              .fontColor('#DFFFFFFF')
          }
          .width('100%')

          Blank()

          Text(this.entry0CountdownBadgeText)
            .fontSize(this.mediumHeroFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.entry0ShouldShowUnit === 'true') {
            Text(this.entry0CountdownUnitText)
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E8FFFFFF')
          }

          Text(this.entry0Title)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width(106)
        .height('100%')
        .padding(11)
        .borderRadius(20)
        .backgroundColor(this.heroColor())
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { target: 'event', eventID: this.entry0ID },
          });
        })

        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(this.brandShort)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#079D89')
            Text(this.sectionTitle)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.secondaryTextColor())
            Blank()
            Text(this.eventCountText)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.secondaryTextColor())
          }
          .width('100%')

          this.compactEventRow(
            this.entry1Visible,
            this.entry1ID,
            this.entry1CategorySymbol,
            this.entry1Title,
            this.entry1DateText,
            this.entry1CountdownBadgeText,
            this.entry1UrgencyColor,
          )
          this.compactEventRow(
            this.entry2Visible,
            this.entry2ID,
            this.entry2CategorySymbol,
            this.entry2Title,
            this.entry2DateText,
            this.entry2CountdownBadgeText,
            this.entry2UrgencyColor,
          )
          this.compactEventRow(
            this.entry3Visible,
            this.entry3ID,
            this.entry3CategorySymbol,
            this.entry3Title,
            this.entry3DateText,
            this.entry3CountdownBadgeText,
            this.entry3UrgencyColor,
          )
        }
        .layoutWeight(1)
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    } else {
      this.emptyCard()
    }
  }

  @Builder
  private largeCard() {
    if (this.hasEvents === 'true') {
      Column({ space: this.largeLayoutSpacing() }) {
        Row({ space: 10 }) {
          Column({ space: 2 }) {
            Text(this.largeTitle)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#079D89')
            Text(this.largeSubtitle)
              .fontSize(9)
              .fontColor(this.secondaryTextColor())
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Text(this.eventCountText)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#079D89')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .backgroundColor(this.brandTintColor())
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(32)

        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(104)
            .height(104)
            .borderRadius(52)
            .border({ width: 18, color: '#12FFFFFF' })
            .translate({ x: 118, y: -34 })

          Text('✦')
            .fontSize(28)
            .fontColor('#2AFFFFFF')
            .translate({ x: -132, y: 42 })

          Column() {
            Row({ space: 8 }) {
              Row({ space: 5 }) {
                Text(this.entry0CategorySymbol)
                  .fontSize(16)
                Text(this.entry0CategoryLabel)
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
              }
              .padding({ left: 9, right: 10, top: 4, bottom: 4 })
              .borderRadius(14)
              .backgroundColor('#24FFFFFF')

              Blank()

              Text(this.entry0DateText)
                .fontSize(10)
                .fontWeight(FontWeight.Medium)
                .fontColor('#E8FFFFFF')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 154 })
            }
            .width('100%')

            Blank()

            Row({ space: 12 }) {
              Text(this.entry0Title)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)

              Row({ space: 4 }) {
                Text(this.entry0CountdownBadgeText)
                  .fontSize(this.largeHeroFontSize())
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .maxLines(1)
                if (this.entry0ShouldShowUnit === 'true') {
                  Text(this.entry0CountdownUnitText)
                    .fontSize(11)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#E8FFFFFF')
                }
              }
              .alignItems(VerticalAlign.Bottom)
            }
            .width('100%')
          }
          .width('100%')
          .height('100%')
          .padding({
            left: this.largeHeroHorizontalPadding(),
            right: this.largeHeroHorizontalPadding(),
            top: 12,
            bottom: 12,
          })
        }
        .width('100%')
        .layoutWeight(1)
        .constraintSize({ minHeight: this.largeHeroMinimumHeight() })
        .borderRadius(22)
        .backgroundColor(this.heroColor())
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { target: 'event', eventID: this.entry0ID },
          });
        })

        if (this.largeSecondaryEventCount() > 0) {
          Row() {
            Text(this.moreEventsTitle)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.secondaryTextColor())
          }
          .width('100%')
          .height(16)

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
          .padding({ left: 12, right: 12 })
          .borderRadius(18)
          .backgroundColor(this.surfaceColor())
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
          Text(categorySymbol)
            .fontSize(this.largeEventIconFontSize())
            .width(this.largeEventIconSize())
            .height(this.largeEventIconSize())
            .textAlign(TextAlign.Center)
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
          Text(`${countdownBadgeText}${this.futureSuffix(countdownBadgeText)}`)
            .fontSize(this.largeEventCountdownFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(urgencyColor)
            .maxLines(1)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
            .backgroundColor(this.countdownBadgeSurfaceColor())
        }
        .width('100%')
        .height(this.largeEventRowHeight())

        if (showDivider) {
          Divider()
            .strokeWidth(0.5)
            .color(this.timelineDividerColor())
            .margin({ left: this.largeEventIconSize() + 9 })
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
        Text(categorySymbol)
          .fontSize(11)
          .fontColor(urgencyColor)
          .width(18)
          .height(18)
          .textAlign(TextAlign.Center)
          .borderRadius(9)
          .backgroundColor(this.surfaceColor())

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

        Text(countdownBadgeText)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(urgencyColor)
          .maxLines(1)
      }
      .width('100%')
      .height(38)
      .padding({ left: 8, right: 8 })
      .borderRadius(12)
      .backgroundColor(this.surfaceColor())
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
      Text('＋')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.secondaryTextColor())
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
    return length > 7 ? 24 : length > 3 ? 32 : length > 2 ? 40 : 48;
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

  private largeHeroMinimumHeight(): number {
    const count = this.largeSecondaryEventCount();
    return count >= 5 ? 58 : count >= 4 ? 66 : count >= 3 ? 78 : 90;
  }

  private largeHeroHorizontalPadding(): number {
    return this.largeSecondaryEventCount() >= 4 ? 12 : 16;
  }

  private largeEventRowHeight(): number {
    const count = this.largeSecondaryEventCount();
    return count >= 5 ? 29 : count >= 4 ? 34 : count >= 3 ? 38 : 46;
  }

  private largeEventIconSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 20 : 24;
  }

  private largeEventIconFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 10 : 12;
  }

  private largeEventTitleFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 11 : 12;
  }

  private largeEventDateFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 8 : 9;
  }

  private largeEventCountdownFontSize(): number {
    return this.largeSecondaryEventCount() >= 4 ? 12 : 13;
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
    return this.theme === 'midnight' ? '#20FFFFFF' : '#14079D89';
  }

  private countdownBadgeSurfaceColor(): string {
    return this.theme === 'midnight' ? '#18FFFFFF' : '#F2F4F7';
  }

  private timelineDividerColor(): string {
    return this.theme === 'midnight' ? '#24FFFFFF' : '#12000000';
  }

  private futureSuffix(countdownBadgeText: string): string {
    return /^\d+\+?$/.test(countdownBadgeText) ? this.entry0CountdownUnitText : '';
  }

  private heroColor(): string {
    if (this.theme === 'minimal') {
      return '#5B61C7';
    }

    if (this.theme === 'midnight') {
      return '#3F4AA8';
    }

    return this.entry0UrgencyColor;
  }

  private cardBackgroundColor(): string {
    if (this.theme === 'midnight') {
      return '#0B1020';
    }

    return this.theme === 'minimal' ? '#F4F4F7' : '#F5F7FA';
  }

  private primaryTextColor(): string {
    return this.theme === 'midnight' ? '#F5F5F7' : '#1C1C1E';
  }

  private secondaryTextColor(): string {
    return this.theme === 'midnight' ? '#B7B7C2' : '#636366';
  }

  private surfaceColor(): string {
    return this.theme === 'midnight' ? '#18FFFFFF' : '#EFFFFFFF';
  }

  private onUpdateToken(): void {
    this.renderRevision += 1;
    console.info(`Countdown card UI received token=${this.updateToken}`);
  }
}
