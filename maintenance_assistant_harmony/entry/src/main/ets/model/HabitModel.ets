/**
 * 习惯模型
 */
@Observed
export class Habit {
  id: string;
  name: string;
  status: string; // '进行中' | '已停用'
  createTime: number;
  totalDays: number;
  completionHistory: number[]; // 完成时间戳列表

  constructor(
    id: string,
    name: string,
    status: string = '进行中',
    createTime: number = Date.now(),
    totalDays: number = 0,
    completionHistory: number[] = []
  ) {
    this.id = id;
    this.name = name;
    this.status = status;
    this.createTime = createTime;
    this.totalDays = totalDays;
    this.completionHistory = completionHistory;
  }

  static fromJson(json: object): Habit {
    const data = json as Record<string, Object>;
    return new Habit(
      String(data['id'] ?? ''),
      String(data['name'] ?? ''),
      String(data['status'] ?? '进行中'),
      Number(data['createTime'] ?? Date.now()),
      Number(data['totalDays'] ?? 0),
      (data['completionHistory'] as number[]) ?? []
    );
  }

  toJson(): object {
    return {
      id: this.id,
      name: this.name,
      status: this.status,
      createTime: this.createTime,
      totalDays: this.totalDays,
      completionHistory: this.completionHistory
    };
  }

  /**
   * 获取最后完成时间
   */
  getLastCompleteTime(): number {
    if (this.completionHistory.length > 0) {
      return this.completionHistory[this.completionHistory.length - 1];
    }
    return 0;
  }
}
