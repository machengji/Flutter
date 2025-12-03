import { Plan } from '../model/PlanModel';
import { Habit } from '../model/HabitModel';
import { Anchor } from '../model/AnchorModel';
import { LocalStorageService } from '../service/LocalStorageService';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';

/**
 * 首页 ViewModel
 */
@Observed
export class HomeViewModel {
  plans: Plan[] = [];
  habits: Habit[] = [];
  anchors: Anchor[] = [];
  rainbowFart: string = '你今天闪闪发光！';
  currentView: string = 'plans'; // 'plans' | 'habits' | 'anchors'
  isLoading: boolean = false;

  private storage: LocalStorageService = LocalStorageService.getInstance();

  /**
   * 初始化数据
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    await this.storage.init(context);
    await this.loadData();
  }

  /**
   * 加载所有数据
   */
  async loadData(): Promise<void> {
    this.isLoading = true;
    this.plans = await this.storage.loadPlans();
    this.habits = await this.storage.loadHabits();
    this.anchors = await this.storage.loadAnchors();
    this.rainbowFart = await this.storage.loadRainbowFart();
    this.isLoading = false;
  }

  // ========== 计划相关方法 ==========

  /**
   * 获取进行中的计划
   */
  get ongoingPlans(): Plan[] {
    return this.plans.filter(p => p.status !== '已完成');
  }

  /**
   * 获取已完成的计划
   */
  get completedPlans(): Plan[] {
    return this.plans.filter(p => p.status === '已完成');
  }

  /**
   * 添加计划
   */
  async addPlan(name: string): Promise<void> {
    const newPlan = new Plan(
      Date.now().toString(),
      name,
      '未开始',
      Date.now()
    );
    this.plans.unshift(newPlan);
    await this.storage.savePlans(this.plans);
  }

  /**
   * 更新计划
   */
  async updatePlan(id: string, newName: string): Promise<void> {
    const index = this.plans.findIndex(p => p.id === id);
    if (index !== -1) {
      this.plans[index].name = newName;
      await this.storage.savePlans(this.plans);
    }
  }

  /**
   * 切换计划状态
   */
  async togglePlanStatus(id: string): Promise<void> {
    const index = this.plans.findIndex(p => p.id === id);
    if (index !== -1) {
      const plan = this.plans[index];
      if (plan.status === '已完成') {
        plan.status = '未开始';
        plan.completeTime = null;
      } else {
        plan.status = '已完成';
        plan.completeTime = Date.now();
        this.refreshRainbowFart();
      }
      await this.storage.savePlans(this.plans);
    }
  }

  /**
   * 删除计划
   */
  async deletePlan(id: string): Promise<void> {
    this.plans = this.plans.filter(p => p.id !== id);
    await this.storage.savePlans(this.plans);
  }

  /**
   * 置顶计划
   */
  async pinPlan(id: string): Promise<void> {
    const index = this.plans.findIndex(p => p.id === id);
    if (index !== -1) {
      const plan = this.plans.splice(index, 1)[0];
      this.plans.unshift(plan);
      await this.storage.savePlans(this.plans);
    }
  }

  // ========== 习惯相关方法 ==========

  /**
   * 获取进行中的习惯
   */
  get activeHabits(): Habit[] {
    return this.habits.filter(h => h.status !== '已停用');
  }

  /**
   * 获取已停用的习惯
   */
  get stoppedHabits(): Habit[] {
    return this.habits.filter(h => h.status === '已停用');
  }

  /**
   * 添加习惯
   */
  async addHabit(name: string): Promise<void> {
    const newHabit = new Habit(
      Date.now().toString(),
      name,
      '进行中',
      Date.now()
    );
    this.habits.unshift(newHabit);
    await this.storage.saveHabits(this.habits);
  }

  /**
   * 更新习惯
   */
  async updateHabit(id: string, newName: string): Promise<void> {
    const index = this.habits.findIndex(h => h.id === id);
    if (index !== -1) {
      this.habits[index].name = newName;
      await this.storage.saveHabits(this.habits);
    }
  }

  /**
   * 习惯打卡
   */
  async checkHabit(id: string): Promise<void> {
    const index = this.habits.findIndex(h => h.id === id);
    if (index !== -1) {
      const habit = this.habits[index];
      habit.totalDays++;
      habit.completionHistory.push(Date.now());
      await this.storage.saveHabits(this.habits);
      this.refreshRainbowFart();
    }
  }

  /**
   * 切换习惯状态
   */
  async toggleHabitStatus(id: string): Promise<void> {
    const index = this.habits.findIndex(h => h.id === id);
    if (index !== -1) {
      const habit = this.habits[index];
      habit.status = habit.status === '已停用' ? '进行中' : '已停用';
      await this.storage.saveHabits(this.habits);
    }
  }

  /**
   * 删除习惯
   */
  async deleteHabit(id: string): Promise<void> {
    this.habits = this.habits.filter(h => h.id !== id);
    await this.storage.saveHabits(this.habits);
  }

  /**
   * 置顶习惯
   */
  async pinHabit(id: string): Promise<void> {
    const index = this.habits.findIndex(h => h.id === id);
    if (index !== -1) {
      const habit = this.habits.splice(index, 1)[0];
      this.habits.unshift(habit);
      await this.storage.saveHabits(this.habits);
    }
  }

  // ========== 锚点相关方法 ==========

  /**
   * 添加锚点
   */
  async addAnchor(name: string, time: string): Promise<void> {
    const newAnchor = new Anchor(
      Date.now().toString(),
      name,
      time
    );
    this.anchors.push(newAnchor);
    this.anchors.sort((a, b) => a.time.localeCompare(b.time));
    await this.storage.saveAnchors(this.anchors);
  }

  /**
   * 更新锚点
   */
  async updateAnchor(id: string, name: string, time: string): Promise<void> {
    const index = this.anchors.findIndex(a => a.id === id);
    if (index !== -1) {
      this.anchors[index].name = name;
      this.anchors[index].time = time;
      this.anchors.sort((a, b) => a.time.localeCompare(b.time));
      await this.storage.saveAnchors(this.anchors);
    }
  }

  /**
   * 删除锚点
   */
  async deleteAnchor(id: string): Promise<void> {
    this.anchors = this.anchors.filter(a => a.id !== id);
    await this.storage.saveAnchors(this.anchors);
  }

  /**
   * 绑定计划到锚点
   */
  async bindPlanToAnchor(anchorId: string, planId: string): Promise<void> {
    const index = this.anchors.findIndex(a => a.id === anchorId);
    if (index !== -1 && !this.anchors[index].planIds.includes(planId)) {
      this.anchors[index].planIds.push(planId);
      await this.storage.saveAnchors(this.anchors);
    }
  }

  /**
   * 解绑计划从锚点
   */
  async unbindPlanFromAnchor(anchorId: string, planId: string): Promise<void> {
    const index = this.anchors.findIndex(a => a.id === anchorId);
    if (index !== -1) {
      this.anchors[index].planIds = this.anchors[index].planIds.filter(id => id !== planId);
      await this.storage.saveAnchors(this.anchors);
    }
  }

  /**
   * 绑定习惯到锚点
   */
  async bindHabitToAnchor(anchorId: string, habitId: string): Promise<void> {
    const index = this.anchors.findIndex(a => a.id === anchorId);
    if (index !== -1 && !this.anchors[index].habitIds.includes(habitId)) {
      this.anchors[index].habitIds.push(habitId);
      await this.storage.saveAnchors(this.anchors);
    }
  }

  /**
   * 解绑习惯从锚点
   */
  async unbindHabitFromAnchor(anchorId: string, habitId: string): Promise<void> {
    const index = this.anchors.findIndex(a => a.id === anchorId);
    if (index !== -1) {
      this.anchors[index].habitIds = this.anchors[index].habitIds.filter(id => id !== habitId);
      await this.storage.saveAnchors(this.anchors);
    }
  }

  // ========== 彩虹屁相关方法 ==========

  /**
   * 刷新彩虹屁
   */
  async refreshRainbowFart(): Promise<void> {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request('https://api.shadiao.pro/chp', {
        method: http.RequestMethod.GET
      });

      if (response.responseCode === 200) {
        const data = JSON.parse(response.result as string) as Record<string, Record<string, string>>;
        const text = data['data']?.['text'];
        if (text) {
          this.rainbowFart = text;
          await this.storage.saveRainbowFart(text);
        }
      }
      httpRequest.destroy();
    } catch (err) {
      console.error('refreshRainbowFart error:', JSON.stringify(err));
    }
  }

  // ========== 数据导入导出 ==========

  /**
   * 导出数据
   */
  exportData(): string {
    const data = {
      plans: this.plans.map(p => p.toJson()),
      habits: this.habits.map(h => h.toJson())
    };
    return JSON.stringify(data);
  }

  /**
   * 导入数据
   */
  async importData(jsonString: string): Promise<boolean> {
    try {
      const data = JSON.parse(jsonString) as Record<string, object[]>;

      if (data['plans']) {
        this.plans = (data['plans'] as object[]).map(json => Plan.fromJson(json));
        await this.storage.savePlans(this.plans);
      }

      if (data['habits']) {
        this.habits = (data['habits'] as object[]).map(json => Habit.fromJson(json));
        await this.storage.saveHabits(this.habits);
      }

      return true;
    } catch (err) {
      console.error('importData error:', JSON.stringify(err));
      return false;
    }
  }
}
