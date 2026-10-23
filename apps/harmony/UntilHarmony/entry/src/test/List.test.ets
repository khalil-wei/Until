import countdownRulesTest from './CountdownRules.test';
import recurrenceTest from './Recurrence.test';

export default function testsuite(): void {
  countdownRulesTest();
  recurrenceTest();
}
