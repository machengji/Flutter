import { describe, it, expect } from '@ohos/hypium';
import { Plan } from '../../../main/ets/model/PlanModel';
import { Habit } from '../../../main/ets/model/HabitModel';
import { Anchor } from '../../../main/ets/model/AnchorModel';
import { DateUtils, StringUtils } from '../../../main/ets/common/Utils';

export default function abilityTest() {
  describe('PlanModel', () => {
    it('should create a plan with default values', () => {
      const plan = new Plan('1', 'Test Plan');
      expect(plan.id).assertEqual('1');
      expect(plan.name).assertEqual('Test Plan');
      expect(plan.status).assertEqual('未开始');
      expect(plan.completeTime).assertNull();
    });

    it('should serialize and deserialize correctly', () => {
      const plan = new Plan('1', 'Test Plan', '已完成', Date.now(), Date.now());
      const json = plan.toJson();
      const restored = Plan.fromJson(json);
      expect(restored.id).assertEqual(plan.id);
      expect(restored.name).assertEqual(plan.name);
      expect(restored.status).assertEqual(plan.status);
    });
  });

  describe('HabitModel', () => {
    it('should create a habit with default values', () => {
      const habit = new Habit('1', 'Test Habit');
      expect(habit.id).assertEqual('1');
      expect(habit.name).assertEqual('Test Habit');
      expect(habit.status).assertEqual('进行中');
      expect(habit.totalDays).assertEqual(0);
    });

    it('should track completion history', () => {
      const habit = new Habit('1', 'Test Habit');
      habit.totalDays = 5;
      habit.completionHistory = [Date.now()];
      expect(habit.getLastCompleteTime()).assertLarger(0);
    });
  });

  describe('AnchorModel', () => {
    it('should create an anchor with default values', () => {
      const anchor = new Anchor('1', 'Morning', '08:00');
      expect(anchor.id).assertEqual('1');
      expect(anchor.name).assertEqual('Morning');
      expect(anchor.time).assertEqual('08:00');
      expect(anchor.getItemCount()).assertEqual(0);
    });

    it('should count linked items', () => {
      const anchor = new Anchor('1', 'Morning', '08:00', ['p1', 'p2'], ['h1']);
      expect(anchor.getItemCount()).assertEqual(3);
    });
  });

  describe('DateUtils', () => {
    it('should format time correctly', () => {
      expect(DateUtils.formatTime(8, 5)).assertEqual('08:05');
      expect(DateUtils.formatTime(14, 30)).assertEqual('14:30');
    });

    it('should parse time correctly', () => {
      const time = DateUtils.parseTime('08:30');
      expect(time.hour).assertEqual(8);
      expect(time.minute).assertEqual(30);
    });

    it('should format relative date for today', () => {
      const today = Date.now();
      expect(DateUtils.formatRelativeDate(today)).assertEqual('今天');
    });
  });

  describe('StringUtils', () => {
    it('should truncate long strings', () => {
      expect(StringUtils.truncate('Hello World', 5)).assertEqual('Hello...');
      expect(StringUtils.truncate('Hi', 5)).assertEqual('Hi');
    });

    it('should generate unique IDs', () => {
      const id1 = StringUtils.generateId();
      const id2 = StringUtils.generateId();
      expect(id1).assertNotEqual(id2);
    });
  });
}
