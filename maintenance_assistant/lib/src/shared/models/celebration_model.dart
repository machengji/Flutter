class CelebrationStyleMode {
  CelebrationStyleMode._();

  static const String mixed = 'mixed';
  static const String sincere = 'sincere';
  static const String playful = 'playful';

  static const List<String> values = [mixed, sincere, playful];

  static String normalize(String? raw) {
    if (raw == sincere || raw == playful || raw == mixed) {
      return raw!;
    }
    return mixed;
  }
}

/// 单次发光庆祝记录（对应发光星籽罐中的一颗星籽）
class ShineRecord {
  final String id;
  final int timestamp;
  final String title;
  final bool isGrand;
  final int colorSeed;

  const ShineRecord({
    required this.id,
    required this.timestamp,
    required this.title,
    this.isGrand = false,
    this.colorSeed = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'title': title,
      'isGrand': isGrand,
      'colorSeed': colorSeed,
    };
  }

  factory ShineRecord.fromJson(Map<String, dynamic> json) {
    return ShineRecord(
      id: json['id']?.toString() ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      isGrand: json['isGrand'] == true,
      colorSeed: (json['colorSeed'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 触发 UI 层展示庆祝动画的事件载荷
class CelebrationPayload {
  final int eventId;
  final String actionTitle;
  final String quote;
  final String microActionPrompt;
  final bool isGrand;
  final String? milestoneTag;

  const CelebrationPayload({
    required this.eventId,
    required this.actionTitle,
    required this.quote,
    required this.microActionPrompt,
    required this.isGrand,
    this.milestoneTag,
  });
}

/// 内置精选庆祝词库与福格 1 秒身体微庆祝动作库
class CelebrationLibrary {
  CelebrationLibrary._();

  /// 真诚克制的自我肯定语（贴合福格微习惯“发光感 Shine”理念）
  static const List<String> sincereAffirmations = [
    '哪怕只是一小步，我也稳稳做到了。',
    '说开始就开始，这就是我的行动力。',
    '今天的我，又认真接住了自己一次。',
    '不靠完美，靠这一次真实的行动。',
    '改变正在发生，为现在的自己鼓掌。',
    '我兑现了对自己的一个小小承诺。',
    '微小的确定性，正在长成新的生活节奏。',
    '每一次动手完成，都在为自信投票。',
    '做得好，这一刻值得停下来肯定自己。',
    '不用等终点，现在这一步就很发光。',
    '我比昨天更懂得照顾自己的目标了。',
    '稳稳向前，我正在养成赢的感觉。',
    '把念头落成行动，本身就很了不起。',
    '今天也在按自己的节奏悄悄生长。',
    '这一刻的踏实感，是我亲手挣来的。',
    '轻轻迈出这一步，阻力就已经变小了。',
  ];

  /// 本地趣味彩虹屁备选库（与在线彩虹屁共同服务趣味风格）
  static const List<String> playfulQuotes = [
    '你今天的执行力简直自带追光灯！',
    '又是被自己靠谱到的一天！',
    '连微风路过都要夸一句：这人真行！',
    '这点小事遇到你，算是踢到铁板啦！',
    '今日份闪闪发光额度已超标达成！',
    '请收下今日最佳行动派小金人！',
    '宇宙刚刚收到一条你变强的信号！',
    '太丝滑了，自律界今天为你亮绿灯！',
  ];

  /// 本地精选冷笑话词库（与开源冷笑话接口共同丰富趣味庆祝池）
  static const List<String> coldJokes = [
    '为什么企鹅的肚子是白的？因为手太短，洗不到。',
    '有一只北极熊觉得很冷，于是它就拔了一根毛，结果更冷了，又拔了一根，结果……成了北极秃熊。',
    '小猪佩奇为什么总是侧着脸？因为正面猪不让画。',
    '什么动物最没有方向感？麋鹿（迷路）。',
    '为什么草莓会被抓进警察局？因为它是莓（没）良心的。',
    '哪一种蛇最容易受骗？竹叶青（猪也轻信）。',
    '胖子从12楼跳下来会变成什么？死胖子。',
    '小明为什么总是考零分？因为他每次答完题都在卷子上写：此处略去一万字。',
    '为什么超人总是把内裤穿在外面？因为他懒得换外裤，直接套上就飞了。',
    '一只蚂蚁突然变大了，请问它现在叫什么？叫蚂蚁呀嘿（迈克尔）。',
    '什么水果视力最差？芒果（盲果）。',
    '热胀冷缩，那为什么人一到冬天就变胖了？因为穿得多，不是膨胀。',
  ];

  /// 1 秒身体微庆祝动作提示（简短直接，引导身体参与调动真实情绪）
  static const List<String> microActionPrompts = [
    '嘴角上扬，深呼吸一次',
    '轻轻握拳，心里说声 Yes',
    '拍拍自己的肩膀',
    '闭眼一秒，感受此刻的轻松',
    '给自己竖个大拇指',
    '舒展一下双肩，吐一口气',
    '点点头，对自己说：我做到了',
    '在心里给自己鼓三次掌',
  ];
}
