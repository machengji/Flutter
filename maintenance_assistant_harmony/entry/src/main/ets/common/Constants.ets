/**
 * 应用常量
 */
export class AppColors {
  static readonly PRIMARY: string = '#007AFF';
  static readonly SUCCESS: string = '#34C759';
  static readonly WARNING: string = '#FF9500';
  static readonly DANGER: string = '#FF3B30';
  static readonly TEXT_PRIMARY: string = '#1D1D1F';
  static readonly TEXT_SECONDARY: string = '#86868B';
  static readonly BACKGROUND_PRIMARY: string = '#F2F2F7';
  static readonly BACKGROUND_SECONDARY: string = '#E5E5EA';
  static readonly CARD_BACKGROUND: string = '#FFFFFF';
  static readonly BORDER_COLOR: string = '#D1D1D6';
  static readonly PURPLE: string = '#5856D6';
}

export class AppDimens {
  static readonly PADDING_SMALL: number = 8;
  static readonly PADDING_MEDIUM: number = 12;
  static readonly PADDING_LARGE: number = 16;
  static readonly PADDING_XLARGE: number = 24;

  static readonly RADIUS_SMALL: number = 8;
  static readonly RADIUS_MEDIUM: number = 12;
  static readonly RADIUS_LARGE: number = 16;
  static readonly RADIUS_XLARGE: number = 24;

  static readonly FONT_SMALL: number = 12;
  static readonly FONT_MEDIUM: number = 14;
  static readonly FONT_LARGE: number = 16;
  static readonly FONT_XLARGE: number = 18;
  static readonly FONT_TITLE: number = 20;
  static readonly FONT_HEADER: number = 24;
  static readonly FONT_HERO: number = 28;

  static readonly ICON_SMALL: number = 16;
  static readonly ICON_MEDIUM: number = 20;
  static readonly ICON_LARGE: number = 24;
  static readonly ICON_XLARGE: number = 28;

  static readonly CARD_HEIGHT: number = 68;
  static readonly FAB_SIZE: number = 56;
  static readonly SWITCH_BUTTON_HEIGHT: number = 40;
}

export class AppStrings {
  static readonly APP_NAME: string = '微行动';
  static readonly TAB_PLANS: string = '计划';
  static readonly TAB_HABITS: string = '习惯';
  static readonly TAB_ANCHORS: string = '锚点';

  static readonly STATUS_NOT_STARTED: string = '未开始';
  static readonly STATUS_COMPLETED: string = '已完成';
  static readonly STATUS_IN_PROGRESS: string = '进行中';
  static readonly STATUS_STOPPED: string = '已停用';

  static readonly EMPTY_PLANS_ICON: string = '✨';
  static readonly EMPTY_PLANS_TITLE: string = '开始你的第一个梦想';
  static readonly EMPTY_PLANS_SUBTITLE: string = '点击下方按钮添加新计划';

  static readonly EMPTY_HABITS_ICON: string = '🎯';
  static readonly EMPTY_HABITS_TITLE: string = '开始你的第一个习惯';
  static readonly EMPTY_HABITS_SUBTITLE: string = '点击下方按钮添加新习惯';

  static readonly EMPTY_ANCHORS_ICON: string = '⚓';
  static readonly EMPTY_ANCHORS_TITLE: string = '添加你的第一个锚点';
  static readonly EMPTY_ANCHORS_SUBTITLE: string = '锚点是生活中一定会发生的事情\n(例如: 起床后, 吃饭前)';

  static readonly ADD_PLAN_TITLE: string = '新计划';
  static readonly ADD_PLAN_PLACEHOLDER: string = '输入你的梦想...';
  static readonly ADD_HABIT_TITLE: string = '新习惯';
  static readonly ADD_HABIT_PLACEHOLDER: string = '输入你的习惯...';
  static readonly ADD_ANCHOR_TITLE: string = '添加新锚点';
  static readonly ADD_ANCHOR_PLACEHOLDER: string = '锚点名称 (例如: 起床后)';

  static readonly EDIT_PLAN_TITLE: string = '编辑计划';
  static readonly EDIT_HABIT_TITLE: string = '编辑习惯';
  static readonly EDIT_ANCHOR_TITLE: string = '编辑锚点';

  static readonly BUTTON_CANCEL: string = '取消';
  static readonly BUTTON_ADD: string = '添加';
  static readonly BUTTON_SAVE: string = '保存';
  static readonly BUTTON_DELETE: string = '删除';

  static readonly TODAY: string = '今天';
  static readonly YESTERDAY: string = '昨天';
  static readonly DAYS_AGO: string = '天前';
  static readonly NEVER: string = '从未';
  static readonly LAST_COMPLETE: string = '最近完成: ';
  static readonly COMPLETE_AT: string = '完成于 ';
  static readonly LINKED_ITEMS: string = '个关联项';
}
