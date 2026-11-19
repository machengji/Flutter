import WidgetKit
import SwiftUI

struct ShineJarEntry: TimelineEntry {
    let date: Date
    let snapshot: ShineWidgetSnapshot
}

struct ShineJarProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShineJarEntry {
        ShineJarEntry(
            date: Date(),
            snapshot: ShineWidgetSnapshot(
                todayShineCount: 6,
                totalShineCount: 42,
                themeId: CelebrationThemeSkin.emerald.rawValue,
                latestActionTitle: "完成了一件微小的事",
                seedColorSeeds: [0, 1, 2, 3, 4, 5],
                updatedAtMs: 0
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShineJarEntry) -> Void) {
        completion(ShineJarEntry(date: Date(), snapshot: SharedWidgetStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShineJarEntry>) -> Void) {
        let entry = ShineJarEntry(date: Date(), snapshot: SharedWidgetStore.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct ShineJarWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: ShineJarProvider.Entry

    private var theme: CelebrationThemeSkin {
        CelebrationThemeSkin(rawValue: entry.snapshot.themeId) ?? .emerald
    }

    private var stageName: String {
        switch entry.snapshot.totalShineCount {
        case 0: return "休眠种子"
        case 1...4: return "破土嫩芽"
        case 5...14: return "抽枝幼苗"
        case 15...34: return "茂密小树"
        case 35...69: return "繁花绿冠"
        default: return "森境大树"
        }
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("\(entry.snapshot.todayShineCount)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                    Text("今日微步 +\(entry.snapshot.todayShineCount)")
                        .font(.system(size: 13, weight: .bold))
                }
                Text("\(stageName) · 累计 \(entry.snapshot.totalShineCount) 步")
                    .font(.system(size: 11))
                    .opacity(0.8)
            }
        case .systemMedium:
            mediumWidgetView
        default:
            smallWidgetView
        }
    }

    private var smallWidgetView: some View {
        ZStack {
            theme.bgColor
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(theme.goldColor)
                    Text("微步成长树")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.creamColor)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.todayShineCount)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.goldColor)
                    Text("今日成长")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.creamColor.opacity(0.85))
                }
                Text("\(stageName) · 累计 \(entry.snapshot.totalShineCount) 步")
                    .font(.system(size: 10.5))
                    .foregroundColor(theme.peachColor)
            }
            .padding(14)
        }
        .widgetBackground(theme.bgColor)
    }

    private var mediumWidgetView: some View {
        ZStack {
            theme.bgColor
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(theme.goldColor)
                        Text("微步 · \(stageName)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.creamColor)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.snapshot.todayShineCount)")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(theme.goldColor)
                        Text("今日微步成长")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.creamColor.opacity(0.88))
                    }
                    Text(entry.snapshot.latestActionTitle)
                        .font(.system(size: 11))
                        .foregroundColor(theme.peachColor)
                        .lineLimit(1)
                }

                Spacer()

                // 迷你动态成长树可视化
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.creamColor.opacity(0.35), lineWidth: 1.4)
                        .background(RoundedRectangle(cornerRadius: 16).fill(theme.creamColor.opacity(0.08)))
                        .frame(width: 84, height: 86)

                    VStack(spacing: 0) {
                        let leafScale: CGFloat = entry.snapshot.totalShineCount >= 15 ? 1.0 : (entry.snapshot.totalShineCount >= 5 ? 0.85 : 0.72)
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.32, green: 0.72, blue: 0.53))
                                .frame(width: 44 * leafScale, height: 34 * leafScale)
                            Circle()
                                .fill(Color(red: 0.45, green: 0.78, blue: 0.62))
                                .frame(width: 28 * leafScale, height: 24 * leafScale)
                                .offset(x: 10, y: -6)
                            if entry.snapshot.totalShineCount >= 15 {
                                Circle()
                                    .fill(theme.goldColor)
                                    .frame(width: 6, height: 6)
                                    .offset(x: -6, y: -4)
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 5, height: 5)
                                    .offset(x: 8, y: 2)
                            }
                        }
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.83, green: 0.52, blue: 0.34))
                            .frame(width: 7, height: entry.snapshot.totalShineCount >= 5 ? 24 : 14)
                    }
                    .padding(.bottom, 10)
                }
            }
            .padding(16)
        }
        .widgetBackground(theme.bgColor)
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}

struct ShineJarWidget: Widget {
    let kind: String = "ShineJarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShineJarProvider()) { entry in
            ShineJarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("微步成长树")
        .description("在桌面与锁屏随时看见你今天浇灌成长的微步生命树。")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
