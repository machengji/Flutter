/**
 * 锚点模型
 */
@Observed
export class Anchor {
  id: string;
  name: string;
  time: string; // 格式: HH:mm
  planIds: string[];
  habitIds: string[];

  constructor(
    id: string,
    name: string,
    time: string,
    planIds: string[] = [],
    habitIds: string[] = []
  ) {
    this.id = id;
    this.name = name;
    this.time = time;
    this.planIds = planIds;
    this.habitIds = habitIds;
  }

  static fromJson(json: object): Anchor {
    const data = json as Record<string, Object>;
    return new Anchor(
      String(data['id'] ?? ''),
      String(data['name'] ?? ''),
      String(data['time'] ?? '08:00'),
      (data['planIds'] as string[]) ?? [],
      (data['habitIds'] as string[]) ?? []
    );
  }

  toJson(): object {
    return {
      id: this.id,
      name: this.name,
      time: this.time,
      planIds: this.planIds,
      habitIds: this.habitIds
    };
  }

  /**
   * 获取关联项总数
   */
  getItemCount(): number {
    return this.planIds.length + this.habitIds.length;
  }
}
