import { CountdownEvent } from '../model/CountdownEvent';

export interface CountdownEventStore {
  load(): Promise<CountdownEvent[]>;
  save(events: CountdownEvent[]): Promise<void>;
}
