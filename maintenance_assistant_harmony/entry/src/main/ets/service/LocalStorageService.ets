import { preferences } from '@kit.ArkData';
import { Plan } from '../model/PlanModel';
import { Habit } from '../model/HabitModel';
import { Anchor } from '../model/AnchorModel';
import { common } from '@kit.AbilityKit';

const PLANS_KEY = 'plans';
const HABITS_KEY = 'habits';
const ANCHORS_KEY = 'anchors';
const RAINBOW_FART_KEY = 'lastRainbowFart';
const PREFERENCES_NAME = 'maintenance_assistant_prefs';

/**
 * 本地存储服务
 */
export class LocalStorageService {
  private static instance: LocalStorageService;
  private dataPreferences: preferences.Preferences | null = null;

  private constructor() {}

  static getInstance(): LocalStorageService {
    if (!LocalStorageService.instance) {
      LocalStorageService.instance = new LocalStorageService();
    }
    return LocalStorageService.instance;
  }

  /**
   * 初始化 Preferences
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
    } catch (err) {
      console.error('LocalStorageService init error:', JSON.stringify(err));
    }
  }

  /**
   * 保存计划列表
   */
  async savePlans(plans: Plan[]): Promise<void> {
    if (!this.dataPreferences) return;
    try {
      const jsonArray = plans.map(p => p.toJson());
      await this.dataPreferences.put(PLANS_KEY, JSON.stringify(jsonArray));
      await this.dataPreferences.flush();
    } catch (err) {
      console.error('savePlans error:', JSON.stringify(err));
    }
  }

  /**
   * 加载计划列表
   */
  async loadPlans(): Promise<Plan[]> {
    if (!this.dataPreferences) return [];
    try {
      const jsonString = await this.dataPreferences.get(PLANS_KEY, '[]') as string;
      const jsonArray = JSON.parse(jsonString) as object[];
      return jsonArray.map(json => Plan.fromJson(json));
    } catch (err) {
      console.error('loadPlans error:', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 保存习惯列表
   */
  async saveHabits(habits: Habit[]): Promise<void> {
    if (!this.dataPreferences) return;
    try {
      const jsonArray = habits.map(h => h.toJson());
      await this.dataPreferences.put(HABITS_KEY, JSON.stringify(jsonArray));
      await this.dataPreferences.flush();
    } catch (err) {
      console.error('saveHabits error:', JSON.stringify(err));
    }
  }

  /**
   * 加载习惯列表
   */
  async loadHabits(): Promise<Habit[]> {
    if (!this.dataPreferences) return [];
    try {
      const jsonString = await this.dataPreferences.get(HABITS_KEY, '[]') as string;
      const jsonArray = JSON.parse(jsonString) as object[];
      return jsonArray.map(json => Habit.fromJson(json));
    } catch (err) {
      console.error('loadHabits error:', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 保存锚点列表
   */
  async saveAnchors(anchors: Anchor[]): Promise<void> {
    if (!this.dataPreferences) return;
    try {
      const jsonArray = anchors.map(a => a.toJson());
      await this.dataPreferences.put(ANCHORS_KEY, JSON.stringify(jsonArray));
      await this.dataPreferences.flush();
    } catch (err) {
      console.error('saveAnchors error:', JSON.stringify(err));
    }
  }

  /**
   * 加载锚点列表
   */
  async loadAnchors(): Promise<Anchor[]> {
    if (!this.dataPreferences) return [];
    try {
      const jsonString = await this.dataPreferences.get(ANCHORS_KEY, '[]') as string;
      const jsonArray = JSON.parse(jsonString) as object[];
      return jsonArray.map(json => Anchor.fromJson(json));
    } catch (err) {
      console.error('loadAnchors error:', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 保存彩虹屁
   */
  async saveRainbowFart(text: string): Promise<void> {
    if (!this.dataPreferences) return;
    try {
      await this.dataPreferences.put(RAINBOW_FART_KEY, text);
      await this.dataPreferences.flush();
    } catch (err) {
      console.error('saveRainbowFart error:', JSON.stringify(err));
    }
  }

  /**
   * 加载彩虹屁
   */
  async loadRainbowFart(): Promise<string> {
    if (!this.dataPreferences) return '你今天闪闪发光！';
    try {
      return await this.dataPreferences.get(RAINBOW_FART_KEY, '你今天闪闪发光！') as string;
    } catch (err) {
      console.error('loadRainbowFart error:', JSON.stringify(err));
      return '你今天闪闪发光！';
    }
  }
}
