/**
 * 计划模型
 */
@Observed
export class Plan {
  id: string;
  name: string;
  status: string; // '未开始' | '已完成'
  createTime: number;
  completeTime: number | null;
  aiTags: string[];
  isExplored: boolean;

  constructor(
    id: string,
    name: string,
    status: string = '未开始',
    createTime: number = Date.now(),
    completeTime: number | null = null,
    aiTags: string[] = [],
    isExplored: boolean = false
  ) {
    this.id = id;
    this.name = name;
    this.status = status;
    this.createTime = createTime;
    this.completeTime = completeTime;
    this.aiTags = aiTags;
    this.isExplored = isExplored;
  }

  static fromJson(json: object): Plan {
    const data = json as Record<string, Object>;
    return new Plan(
      String(data['id'] ?? ''),
      String(data['name'] ?? ''),
      String(data['status'] ?? '未开始'),
      Number(data['createTime'] ?? Date.now()),
      data['completeTime'] ? Number(data['completeTime']) : null,
      (data['aiTags'] as string[]) ?? [],
      Boolean(data['isExplored'] ?? false)
    );
  }

  toJson(): object {
    return {
      id: this.id,
      name: this.name,
      status: this.status,
      createTime: this.createTime,
      completeTime: this.completeTime,
      aiTags: this.aiTags,
      isExplored: this.isExplored
    };
  }
}
