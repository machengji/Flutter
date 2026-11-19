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

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                    Text("\(entry.snapshot.todayShineCount)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("今日发光 \(entry.snapshot.todayShineCount) 次")
                        .font(.system(size: 13, weight: .bold))
                }
                Text("累计星籽 \(entry.snapshot.totalShineCount) 颗")
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
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(theme.goldColor)
                    Text("发光星籽罐")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.creamColor)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.todayShineCount)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.goldColor)
                    Text("颗今日星籽")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.creamColor.opacity(0.85))
                }
                Text("累计 \(entry.snapshot.totalShineCount) 颗 · \(theme.name)")
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
                        Image(systemName: "sparkles")
                            .foregroundColor(theme.goldColor)
                        Text("微行动 · 发光星籽罐")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.creamColor)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.snapshot.todayShineCount)")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(theme.goldColor)
                        Text("次今日发光")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.creamColor.opacity(0.88))
                    }
                    Text(entry.snapshot.latestActionTitle)
                        .font(.system(size: 11))
                        .foregroundColor(theme.peachColor)
                        .lineLimit(1)
                }

                Spacer()

                // 迷你星籽玻璃罐可视化
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.creamColor.opacity(0.4), lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 16).fill(theme.creamColor.opacity(0.08)))
                        .frame(width: 84, height: 86)

                    let count = min(max(entry.snapshot.totalShineCount, 1), 12)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(14), spacing: 3), count: 4), spacing: 3) {
                        ForEach(0..<count, id: \.self) { idx in
                            Image(systemName: "sparkle")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(idx % 2 == 0 ? theme.goldColor : theme.peachColor)
                        }
                    }
                    .frame(width: 68)
                    .padding(.bottom, 8)
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
        .configurationDisplayName("发光星籽罐")
        .description("在桌面与锁屏随时看见你今天点亮的星籽数量。")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
