import { CountdownCardUpdateService } from '../card/CountdownCardDataSource';
import { AppEventStore } from '../repository/AppEventStore';
import { EventListViewModel } from '../viewmodel/EventListViewModel';
import { ReminderService } from './ReminderService';

export class RetentionCoordinator {
  private static operationQueue: Promise<void> = Promise.resolve();

  static reconcile(referenceDate: Date = new Date()): Promise<void> {
    const operation = async (): Promise<void> => {
      try {
        const viewModel = new EventListViewModel(AppEventStore.shared());
        await viewModel.load(referenceDate);
        await ReminderService.reschedule(viewModel.allEvents());
        await CountdownCardUpdateService.refreshAllCards();
      } catch (error) {
        console.error(`Failed to reconcile retention channels: ${JSON.stringify(error)}`);
      }
    };

    const queuedOperation = RetentionCoordinator.operationQueue.then(operation, operation);
    RetentionCoordinator.operationQueue = queuedOperation.then(
      (): void => {
      },
      (): void => {
      },
    );
    return queuedOperation;
  }
}

