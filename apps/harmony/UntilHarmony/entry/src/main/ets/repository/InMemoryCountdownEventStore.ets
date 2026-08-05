import { CountdownEvent } from '../model/CountdownEvent';
import { CountdownEventStore } from './CountdownEventStore';

export class InMemoryCountdownEventStore implements CountdownEventStore {
  private events: CountdownEvent[] = [];

  constructor(initialEvents: CountdownEvent[] = []) {
    this.events = [...initialEvents];
  }

  async load(): Promise<CountdownEvent[]> {
    return [...this.events];
  }

  async save(events: CountdownEvent[]): Promise<void> {
    this.events = [...events];
  }
}
